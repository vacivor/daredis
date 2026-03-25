import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:daredis/src/connect.dart';
import 'package:daredis/src/exceptions.dart';
import 'package:daredis/src/pubsub_message.dart';
import 'package:daredis/src/resp.dart';

/// Builds the `SUBSCRIBE` and `PSUBSCRIBE` commands needed to restore an
/// existing pub/sub session after reconnecting.
List<List<dynamic>> buildPubSubResubscribeCommands({
  required Iterable<String> channels,
  required Iterable<String> patterns,
}) {
  final commands = <List<dynamic>>[];
  final channelList = channels.toList(growable: false);
  final patternList = patterns.toList(growable: false);

  if (channelList.isNotEmpty) {
    commands.add(['SUBSCRIBE', ...channelList]);
  }
  if (patternList.isNotEmpty) {
    commands.add(['PSUBSCRIBE', ...patternList]);
  }

  return commands;
}

/// Dedicated Redis pub/sub session bound to a single subscription socket.
class RedisPubSub {
  /// Target host.
  final String host;

  /// Target port.
  final int port;

  /// Optional ACL username.
  final String? username;

  /// Optional password for `AUTH`.
  final String? password;

  /// Socket connect timeout.
  final Duration connectTimeout;

  /// Timeout used while waiting for subscribe acknowledgements.
  final Duration commandTimeout;

  /// Whether to use TLS sockets.
  final bool useSsl;

  /// Reconnect behavior for the subscription socket.
  final ReconnectPolicy reconnectPolicy;

  final _decoder = RespDecoder();
  final _encoder = RespEncoder();
  final _buffer = BytesBuilder();
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  bool _shouldReconnect = true;

  Socket? _socket;
  StreamSubscription<Uint8List>? _socketSubscription;
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

  /// Creates a pub/sub session from reusable [ConnectionOptions].
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

  /// Broadcast stream of all pub/sub frames exposed as typed messages.
  Stream<PubSubMessage> get messages => _pubSubController.stream;

  /// Subscription acknowledgement frames such as `subscribe` and
  /// `unsubscribe`.
  Stream<PubSubMessage> get subscriptionEvents =>
      messages.where((message) => message.isSubscriptionEvent);

  /// Data-bearing frames such as `message` and `pmessage`.
  Stream<PubSubMessage> get dataMessages =>
      messages.where((message) => message.isDataMessage);

  /// Alias for [messages].
  Stream<PubSubMessage> listen() => messages;

  /// Waits for the next incoming message frame.
  ///
  /// When [ignoreSubscriptionMessages] is true, only published data messages
  /// are considered. Returns `null` on timeout when [timeout] is provided.
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

  /// Opens the pub/sub socket and replays tracked subscriptions if needed.
  Future<void> connect() async {
    _ensureOpen();
    if (_socket != null) {
      return;
    }
    _shouldReconnect = true;
    try {
      final socket = useSsl
          ? await SecureSocket.connect(host, port, timeout: connectTimeout)
          : await Socket.connect(host, port, timeout: connectTimeout);
      _socket = socket;
      _socketSubscription = socket.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
      );

      if (password != null) {
        if (username != null) {
          await _sendCommand(['AUTH', username!, password!]);
        } else {
          await _sendCommand(['AUTH', password!]);
        }
      }

      await _resubscribe();
      _reconnectAttempts = 0;
    } on DaredisException {
      await _disposeSocket(graceful: true);
      rethrow;
    } catch (e) {
      await _disposeSocket(graceful: true);
      if (!_isReconnecting) {
        throw DaredisNetworkException('Failed to connect to $host:$port: $e');
      }
    }
  }

  /// Whether the underlying socket is currently open.
  bool get isConnected => _socket != null;

  /// Whether the session has been explicitly closed.
  bool get isClosed => _closed;

  bool _closed = false;

  /// Connects lazily when the socket is not yet open.
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
    unawaited(_handleReconnect());
  }

  void _onDone() {
    _cleanup();
    unawaited(_handleReconnect());
  }

  void _failPendingAcks([DaredisException? error]) {
    final exception = error ?? DaredisNetworkException('Connection closed');
    while (_ackQueue.isNotEmpty) {
      _ackQueue.removeFirst().completer.completeError(exception);
    }
  }

  void _cleanup() {
    _failPendingAcks();
    final subscription = _socketSubscription;
    final socket = _socket;
    _socketSubscription = null;
    _socket = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    socket?.destroy();
  }

  Future<void> _disposeSocket({required bool graceful}) async {
    final subscription = _socketSubscription;
    final socket = _socket;
    _socketSubscription = null;
    _socket = null;
    if (subscription != null) {
      await subscription.cancel();
    }
    if (graceful) {
      await socket?.close();
    } else {
      socket?.destroy();
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
      _addMessage(
        PubSubMessage(type, channel: frame[1].toString(), payload: frame[2]),
      );
      return;
    }
    if (type == 'pmessage') {
      _addMessage(
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
      _addMessage(
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

  /// Feeds a decoded pub/sub frame into the session.
  ///
  /// This is useful for tests and for custom transports that already decode
  /// RESP frames outside of [RedisPubSub].
  void handleFrame(List<dynamic> frame) {
    _handlePubSubFrame(frame);
  }

  Future<void> _sendCommand(List<dynamic> command) async {
    if (_socket == null) {
      throw DaredisConnectionException("Not connected");
    }
    final encoded = _encoder.encodeCommand(command);
    _socket!.add(encoded);
  }

  /// Subscribes to one or more channels.
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

  /// Pattern-subscribes to one or more glob-style channel patterns.
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

  /// Unsubscribes from specific channels, or from all channels when omitted.
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

  /// Unsubscribes from specific patterns, or from all patterns when omitted.
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

  /// Closes the socket without clearing the closed state.
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _isReconnecting = false;
    _reconnectAttempts = 0;
    _failPendingAcks(DaredisConnectionException('Connection closed'));
    await _disposeSocket(graceful: true);
  }

  /// Permanently closes the session and clears tracked subscriptions.
  Future<void> close() async {
    if (_closed) {
      if (!_pubSubController.isClosed) {
        await _pubSubController.close();
      }
      return;
    }
    _closed = true;
    _channels.clear();
    _patterns.clear();
    await disconnect();
    if (!_pubSubController.isClosed) {
      await _pubSubController.close();
    }
  }

  Future<void> _handleReconnect() async {
    if (_closed || !_shouldReconnect || _isReconnecting) return;
    if (reconnectPolicy.maxAttempts != null &&
        _reconnectAttempts >= reconnectPolicy.maxAttempts!) {
      return;
    }
    _isReconnecting = true;
    _reconnectAttempts += 1;
    await Future.delayed(reconnectPolicy.delay);
    if (_closed || !_shouldReconnect) {
      _isReconnecting = false;
      return;
    }
    try {
      await connect();
      _isReconnecting = false;
    } on DaredisCommandException {
      _isReconnecting = false;
    } catch (_) {
      _isReconnecting = false;
      unawaited(_handleReconnect());
    }
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  void _addMessage(PubSubMessage message) {
    if (_pubSubController.isClosed) {
      return;
    }
    _pubSubController.add(message);
  }

  void _ensureOpen() {
    if (_closed) {
      throw DaredisStateException('Redis pubsub session is closed');
    }
  }

  Future<void> _resubscribe() async {
    final commands = buildPubSubResubscribeCommands(
      channels: _channels,
      patterns: _patterns,
    );

    for (final command in commands) {
      if (command.first == 'SUBSCRIBE') {
        final waiter = _PubSubAckWaiter(
          types: const {'subscribe'},
          remaining: command.length - 1,
        );
        _ackQueue.add(waiter);
        await _sendCommand(command);
        await waiter.completer.future.timeout(commandTimeout);
        continue;
      }

      final waiter = _PubSubAckWaiter(
        types: const {'psubscribe'},
        remaining: command.length - 1,
      );
      _ackQueue.add(waiter);
      await _sendCommand(command);
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
