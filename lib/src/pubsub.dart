import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:daredis/src/connect.dart';
import 'package:daredis/src/exceptions.dart';
import 'package:daredis/src/pubsub_message.dart';
import 'package:daredis/src/resp.dart';

class RedisPubSub {
  final String host;
  final int port;
  final String? username;
  final String? password;
  final Duration connectTimeout;
  final Duration commandTimeout;
  final bool useSsl;
  final ReconnectPolicy reconnectPolicy;

  final _decoder = RespDecoder();
  final _encoder = RespEncoder();
  final _buffer = BytesBuilder();
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;

  late Socket? _socket;
  final _pubSubController = StreamController<PubSubMessage>.broadcast();
  final Queue<_PubSubAckWaiter> _ackQueue = Queue();
  final Set<String> _channels = {};
  final Set<String> _patterns = {};

  RedisPubSub({
    required this.host,
    required this.port,
    this.username,
    this.password,
    this.connectTimeout = const Duration(seconds: 5),
    this.commandTimeout = const Duration(seconds: 30),
    this.useSsl = false,
    this.reconnectPolicy = const ReconnectPolicy(),
  });

  factory RedisPubSub.fromOptions(ConnectionOptions options) {
    return RedisPubSub(
      host: options.host,
      port: options.port,
      username: options.username,
      password: options.password,
      connectTimeout: options.connectTimeout,
      commandTimeout: options.commandTimeout,
      useSsl: options.useSsl,
      reconnectPolicy: options.reconnectPolicy,
    );
  }

  Stream<PubSubMessage> get messages => _pubSubController.stream;

  Stream<PubSubMessage> get subscriptionEvents =>
      messages.where((message) => message.isSubscriptionEvent);

  Stream<PubSubMessage> get dataMessages =>
      messages.where((message) => message.isDataMessage);

  Stream<PubSubMessage> listen() => messages;

  Future<PubSubMessage?> getMessage({
    Duration? timeout,
    bool ignoreSubscriptionMessages = false,
  }) async {
    Stream<PubSubMessage> stream = messages;

    if (ignoreSubscriptionMessages) {
      stream = stream.where(
        (message) => message.type == 'message' || message.type == 'pmessage',
      );
    }

    if (timeout == null) {
      return await stream.first;
    }

    return stream.cast<PubSubMessage?>().first.timeout(
      timeout,
      onTimeout: () => null,
    );
  }

  Future<void> connect() async {
    if (_closed) {
      _closed = false;
    }
    try {
      if (useSsl) {
        _socket = await SecureSocket.connect(
          host,
          port,
          timeout: connectTimeout,
        );
      } else {
        _socket = await Socket.connect(host, port, timeout: connectTimeout);
      }
      _socket!.listen(_onData, onError: _onError, onDone: _onDone);

      if (password != null) {
        if (username != null) {
          await _sendCommand(['AUTH', username!, password!]);
        } else {
          await _sendCommand(['AUTH', password!]);
        }
      }

      await _resubscribe();
      _reconnectAttempts = 0;
    } catch (e) {
      if (!_isReconnecting) {
        throw DaredisNetworkException('Failed to connect to $host:$port: $e');
      }
    }
  }

  bool get isConnected => _socket != null;

  bool get isClosed => _closed;

  bool _closed = false;

  Future<void> ensureConnected() async {
    if (!isConnected) {
      await connect();
    }
  }

  void _onData(Uint8List data) {
    _buffer.add(data);
    _tryDecode();
  }

  void _onError(Object error) {
    _cleanup();
    _handleReconnect();
  }

  void _onDone() {
    _cleanup();
    _handleReconnect();
  }

  void _cleanup() {
    final error = DaredisNetworkException('Connection closed');
    _socket?.destroy();
    _socket = null;
    while (_ackQueue.isNotEmpty) {
      _ackQueue.removeFirst().completer.completeError(error);
    }
  }

  void _tryDecode() {
    while (_buffer.isNotEmpty) {
      final currentData = _buffer.toBytes();
      try {
        final decoded = _decoder.decode(currentData);
        final consumed = _decoder.consumedBytes;
        final remaining = currentData.sublist(consumed);
        _buffer.clear();
        _buffer.add(remaining);

        final native = respValueToNative(decoded);
        if (native is List && native.isNotEmpty) {
          _handlePubSubFrame(native);
        }
      } on IncompleteDataException {
        break;
      } catch (_) {
        _buffer.clear();
        break;
      }
    }
  }

  void _handlePubSubFrame(List<dynamic> frame) {
    final type = frame[0].toString();
    if (type == 'message') {
      _pubSubController.add(
        PubSubMessage(type, channel: frame[1].toString(), payload: frame[2]),
      );
      return;
    }
    if (type == 'pmessage') {
      _pubSubController.add(
        PubSubMessage(
          type,
          pattern: frame[1].toString(),
          channel: frame[2].toString(),
          payload: frame[3],
        ),
      );
      return;
    }
    if (type == 'subscribe' ||
        type == 'psubscribe' ||
        type == 'unsubscribe' ||
        type == 'punsubscribe') {
      final count = frame.length > 2 ? _parseInt(frame[2]) : null;
      _pubSubController.add(
        PubSubMessage(
          type,
          channel: frame[1]?.toString(),
          subscriptionCount: count,
        ),
      );
      if (_ackQueue.isNotEmpty) {
        final waiter = _ackQueue.first;
        if (waiter.types.contains(type)) {
          waiter.remaining -= 1;
          if (waiter.remaining <= 0) {
            _ackQueue.removeFirst();
            waiter.completer.complete();
          }
        }
      }
      return;
    }
  }

  Future<void> _sendCommand(List<dynamic> command) async {
    if (_socket == null) {
      throw DaredisConnectionException("Not connected");
    }
    final encoded = _encoder.encodeCommand(command);
    _socket!.add(encoded);
  }

  Future<void> subscribe(List<String> channels) async {
    if (channels.isEmpty) return;
    _ensureOpen();
    await ensureConnected();
    _channels.addAll(channels);
    final waiter = _PubSubAckWaiter(
      types: const {'subscribe'},
      remaining: channels.length,
    );
    _ackQueue.add(waiter);
    await _sendCommand(['SUBSCRIBE', ...channels]);
    await waiter.completer.future.timeout(
      commandTimeout,
      onTimeout: () => throw DaredisTimeoutException(
        'Subscribe timed out after ${commandTimeout.inSeconds}s',
      ),
    );
  }

  Future<void> psubscribe(List<String> patterns) async {
    if (patterns.isEmpty) return;
    _ensureOpen();
    await ensureConnected();
    _patterns.addAll(patterns);
    final waiter = _PubSubAckWaiter(
      types: const {'psubscribe'},
      remaining: patterns.length,
    );
    _ackQueue.add(waiter);
    await _sendCommand(['PSUBSCRIBE', ...patterns]);
    await waiter.completer.future.timeout(
      commandTimeout,
      onTimeout: () => throw DaredisTimeoutException(
        'PSubscribe timed out after ${commandTimeout.inSeconds}s',
      ),
    );
  }

  Future<void> unsubscribe([List<String> channels = const []]) async {
    _ensureOpen();
    await ensureConnected();
    if (channels.isEmpty) {
      _channels.clear();
    } else {
      _channels.removeAll(channels);
    }
    final waiter = _PubSubAckWaiter(
      types: const {'unsubscribe'},
      remaining: channels.isEmpty ? 1 : channels.length,
    );
    _ackQueue.add(waiter);
    await _sendCommand(['UNSUBSCRIBE', ...channels]);
    await waiter.completer.future.timeout(
      commandTimeout,
      onTimeout: () => throw DaredisTimeoutException(
        'Unsubscribe timed out after ${commandTimeout.inSeconds}s',
      ),
    );
  }

  Future<void> punsubscribe([List<String> patterns = const []]) async {
    _ensureOpen();
    await ensureConnected();
    if (patterns.isEmpty) {
      _patterns.clear();
    } else {
      _patterns.removeAll(patterns);
    }
    final waiter = _PubSubAckWaiter(
      types: const {'punsubscribe'},
      remaining: patterns.isEmpty ? 1 : patterns.length,
    );
    _ackQueue.add(waiter);
    await _sendCommand(['PUNSUBSCRIBE', ...patterns]);
    await waiter.completer.future.timeout(
      commandTimeout,
      onTimeout: () => throw DaredisTimeoutException(
        'PUnsubscribe timed out after ${commandTimeout.inSeconds}s',
      ),
    );
  }

  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
  }

  Future<void> close() async {
    _closed = true;
    _channels.clear();
    _patterns.clear();
    await disconnect();
  }

  Future<void> _handleReconnect() async {
    if (_closed) return;
    if (_isReconnecting) return;
    if (reconnectPolicy.maxAttempts != null &&
        _reconnectAttempts >= reconnectPolicy.maxAttempts!) {
      return;
    }
    _isReconnecting = true;
    _reconnectAttempts += 1;
    await Future.delayed(reconnectPolicy.delay);
    try {
      await connect();
      _isReconnecting = false;
    } catch (e) {
      _isReconnecting = false;
      _handleReconnect();
    }
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  void _ensureOpen() {
    if (_closed) {
      throw DaredisStateException('Redis pubsub session is closed');
    }
  }

  Future<void> _resubscribe() async {
    if (_channels.isNotEmpty) {
      final waiter = _PubSubAckWaiter(
        types: const {'subscribe'},
        remaining: _channels.length,
      );
      _ackQueue.add(waiter);
      await _sendCommand(['SUBSCRIBE', ..._channels]);
      await waiter.completer.future.timeout(commandTimeout);
    }
    if (_patterns.isNotEmpty) {
      final waiter = _PubSubAckWaiter(
        types: const {'psubscribe'},
        remaining: _patterns.length,
      );
      _ackQueue.add(waiter);
      await _sendCommand(['PSUBSCRIBE', ..._patterns]);
      await waiter.completer.future.timeout(commandTimeout);
    }
  }
}

class _PubSubAckWaiter {
  final Set<String> types;
  final Completer<void> completer = Completer<void>();
  int remaining;

  _PubSubAckWaiter({required this.types, required this.remaining});
}
