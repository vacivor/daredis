import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:daredis/src/commands/decoders.dart';
import 'package:daredis/src/connect.dart';
import 'package:daredis/src/exceptions.dart';
import 'package:daredis/src/resp.dart';

/// Dedicated Redis MONITOR session bound to a single socket.
class RedisMonitor {
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

  /// Timeout used while waiting for `AUTH` and `MONITOR` replies.
  final Duration commandTimeout;

  /// Whether to use TLS sockets.
  final bool useSsl;

  /// Reconnect behavior for the monitor socket.
  final ReconnectPolicy reconnectPolicy;

  final _decoder = RespDecoder();
  final _encoder = RespEncoder();
  final _buffer = BytesBuilder();
  final Queue<Completer<dynamic>> _responseQueue = Queue();
  final _messagesController = StreamController<String>.broadcast();
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  bool _shouldReconnect = true;
  bool _monitoring = false;
  bool _closed = false;

  Socket? _socket;
  StreamSubscription<Uint8List>? _socketSubscription;

  RedisMonitor({
    required this.host,
    required this.port,
    this.username,
    this.password,
    this.connectTimeout = const Duration(seconds: 5),
    this.commandTimeout = const Duration(seconds: 30),
    this.useSsl = false,
    this.reconnectPolicy = const ReconnectPolicy(),
  });

  /// Creates a monitor session from reusable [ConnectionOptions].
  factory RedisMonitor.fromOptions(ConnectionOptions options) {
    return RedisMonitor(
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

  /// Broadcast stream of monitor lines emitted by Redis.
  Stream<String> get messages => _messagesController.stream;

  /// Alias for [messages].
  Stream<String> listen() => messages;

  /// Waits for the next monitor line.
  Future<String?> getMessage({Duration? timeout}) async {
    if (timeout == null) {
      return messages.first;
    }
    return messages.cast<String?>().first.timeout(
      timeout,
      onTimeout: () => null,
    );
  }

  /// Opens the socket and enters MONITOR mode.
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

      _monitoring = true;
      final response = await _sendCommand(['MONITOR']);
      if (Decoders.toStringOrNull(response) != 'OK') {
        _monitoring = false;
        throw DaredisProtocolException(
          'Unexpected MONITOR reply: ${response.runtimeType}',
        );
      }
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
    _cleanup(error);
    unawaited(_handleReconnect());
  }

  void _onDone() {
    _cleanup(null);
    unawaited(_handleReconnect());
  }

  void _failPendingResponses([Object? error]) {
    final exception = error is DaredisException
        ? error
        : DaredisNetworkException(
            error == null ? 'Connection closed' : 'Connection error: $error',
          );
    while (_responseQueue.isNotEmpty) {
      _responseQueue.removeFirst().completeError(exception);
    }
  }

  void _cleanup(dynamic error) {
    _monitoring = false;
    _failPendingResponses(error);
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
    _monitoring = false;
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
    if (_buffer.isEmpty) {
      return;
    }
    final currentData = _buffer.toBytes();
    var offset = 0;
    while (offset < currentData.length) {
      try {
        final decoded = _decoder.decode(currentData, offset: offset);
        offset = _decoder.consumedBytes;

        final native = respValueToNative(decoded);
        if (_responseQueue.isNotEmpty) {
          _responseQueue.removeFirst().complete(native);
          continue;
        }
        if (_monitoring && native != null) {
          _addMessage(Decoders.string(native));
        }
      } on IncompleteDataException {
        break;
      } catch (_) {
        _buffer.clear();
        return;
      }
    }
    if (offset == 0) {
      return;
    }
    _buffer.clear();
    if (offset < currentData.length) {
      _buffer.add(Uint8List.sublistView(currentData, offset));
    }
  }

  /// Feeds a decoded monitor frame into the session.
  ///
  /// This is useful for tests and for custom transports that already decode
  /// RESP frames outside of [RedisMonitor].
  void handleFrame(dynamic frame) {
    if (frame != null) {
      _addMessage(Decoders.string(frame));
    }
  }

  void _addMessage(String message) {
    if (!_messagesController.isClosed) {
      _messagesController.add(message);
    }
  }

  Future<dynamic> _sendCommand(List<dynamic> command) async {
    final socket = _socket;
    if (socket == null) {
      throw DaredisConnectionException('Not connected');
    }
    final encoded = _encoder.encodeCommand(command);
    final completer = Completer<dynamic>();
    _responseQueue.add(completer);
    try {
      socket.add(encoded);
    } catch (error) {
      _responseQueue.remove(completer);
      rethrow;
    }
    return completer.future.timeout(
      commandTimeout,
      onTimeout: () {
        _responseQueue.remove(completer);
        throw DaredisTimeoutException(
          'Command timed out after ${commandTimeout.inSeconds}s',
        );
      },
    );
  }

  /// Closes the socket without clearing the closed state.
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _isReconnecting = false;
    _reconnectAttempts = 0;
    _failPendingResponses(DaredisConnectionException('Connection closed'));
    await _disposeSocket(graceful: true);
  }

  /// Permanently closes the session and closes the message stream.
  Future<void> close() async {
    if (_closed) {
      if (!_messagesController.isClosed) {
        await _messagesController.close();
      }
      return;
    }
    _closed = true;
    await disconnect();
    if (!_messagesController.isClosed) {
      await _messagesController.close();
    }
  }

  Future<void> _handleReconnect() async {
    if (!_shouldReconnect || _isReconnecting) return;
    if (reconnectPolicy.maxAttempts != null &&
        _reconnectAttempts >= reconnectPolicy.maxAttempts!) {
      return;
    }
    _isReconnecting = true;
    _reconnectAttempts += 1;
    await Future.delayed(reconnectPolicy.delayForAttempt(_reconnectAttempts));
    if (!_shouldReconnect) {
      _isReconnecting = false;
      return;
    }
    try {
      await connect();
      _isReconnecting = false;
    } on DaredisCommandException catch (error, stackTrace) {
      _isReconnecting = false;
      _shouldReconnect = false;
      Zone.current.handleUncaughtError(error, stackTrace);
    } catch (_) {
      _isReconnecting = false;
      unawaited(_handleReconnect());
    }
  }

  void _ensureOpen() {
    if (_closed) {
      throw DaredisStateException('Redis monitor session is closed');
    }
  }
}
