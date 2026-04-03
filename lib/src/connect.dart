import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:daredis/src/exceptions.dart';
import 'package:daredis/src/resp.dart';

typedef PushMessageHandler = void Function(List<dynamic> message);
typedef ConnectionSetupHandler = FutureOr<void> Function(Connection connection);
typedef ReconnectFailureHandler =
    void Function(DaredisException error, StackTrace stackTrace);

/// Controls how a low-level connection retries after the socket closes.
class ReconnectPolicy {
  /// Maximum reconnect attempts before giving up.
  ///
  /// When `null`, reconnects continue indefinitely.
  final int? maxAttempts;

  /// Base delay before the first reconnect retry.
  ///
  /// Later retries back off exponentially via [backoffMultiplier] and are
  /// capped by [maxDelay].
  final Duration delay;

  /// Maximum delay used after exponential backoff is applied.
  final Duration maxDelay;

  /// Multiplier applied to [delay] for each successive retry attempt.
  final double backoffMultiplier;

  const ReconnectPolicy({
    this.maxAttempts,
    this.delay = const Duration(seconds: 2),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2,
  }) : assert(backoffMultiplier >= 1);

  /// Returns the retry delay for the 1-based reconnect [attempt].
  Duration delayForAttempt(int attempt) {
    if (attempt <= 1) {
      return delay > maxDelay ? maxDelay : delay;
    }
    var delayMicros = delay.inMicroseconds.toDouble();
    for (var i = 1; i < attempt; i++) {
      delayMicros *= backoffMultiplier;
      if (delayMicros >= maxDelay.inMicroseconds) {
        return maxDelay;
      }
    }
    final nextDelay = Duration(microseconds: delayMicros.round());
    return nextDelay > maxDelay ? maxDelay : nextDelay;
  }
}

/// Single Redis socket connection with RESP encoding, decoding, and retries.
class Connection {
  /// Target host.
  final String host;

  /// Target port.
  final int port;

  /// Optional username for ACL authentication.
  final String? username;

  /// Optional password for `AUTH`.
  final String? password;

  /// Socket connect timeout.
  final Duration connectTimeout;

  /// Default timeout used by [sendCommand].
  final Duration commandTimeout;

  /// Whether to connect with TLS.
  final bool useSsl;

  /// Reconnect behavior after disconnects.
  final ReconnectPolicy reconnectPolicy;

  /// Optional handler for RESP3 push frames.
  final PushMessageHandler? pushHandler;

  /// Optional setup callback invoked after authentication on every successful
  /// socket connect and reconnect.
  final ConnectionSetupHandler? connectionSetup;

  /// Optional callback invoked when reconnecting gives up because a reconnect
  /// attempt failed with a terminal Redis command error.
  final ReconnectFailureHandler? reconnectFailureHandler;

  final _decoder = RespDecoder();
  final _encoder = RespEncoder();
  final _completers = <Completer<dynamic>>[];
  final _buffer = BytesBuilder();
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  bool _shouldReconnect = true;

  Socket? _socket;
  StreamSubscription<Uint8List>? _socketSubscription;

  Connection({
    required this.host,
    required this.port,
    this.username,
    this.password,
    this.connectTimeout = const Duration(seconds: 5),
    this.commandTimeout = const Duration(seconds: 30),
    this.useSsl = false,
    this.reconnectPolicy = const ReconnectPolicy(),
    this.pushHandler,
    this.connectionSetup,
    this.reconnectFailureHandler,
  });

  /// Creates a connection from reusable [ConnectionOptions].
  factory Connection.fromOptions(ConnectionOptions options) {
    return Connection(
      host: options.host,
      port: options.port,
      username: options.username,
      password: options.password,
      connectTimeout: options.connectTimeout,
      commandTimeout: options.commandTimeout,
      useSsl: options.useSsl,
      reconnectPolicy: options.reconnectPolicy,
      pushHandler: options.pushHandler,
      connectionSetup: options.connectionSetup,
      reconnectFailureHandler: options.reconnectFailureHandler,
    );
  }

  /// Opens the socket and authenticates when credentials are configured.
  Future<void> connect() async {
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
          await sendCommand(['AUTH', username!, password!]);
        } else {
          await sendCommand(['AUTH', password!]);
        }
      }
      await connectionSetup?.call(this);
      _reconnectAttempts = 0;
    } on DaredisException {
      await _disposeSocket(graceful: true);
      rethrow;
    } catch (e) {
      await _disposeSocket(graceful: true);
      throw DaredisNetworkException('Failed to connect to $host:$port: $e');
    }
  }

  /// Whether the underlying socket is currently open.
  bool get isConnected => _socket != null;

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

  void _completePending(dynamic error) {
    final exception = error is DaredisException
        ? error
        : DaredisNetworkException(
            error == null ? 'Connection closed' : 'Connection error: $error',
          );
    for (final completer in _completers) {
      completer.completeError(exception);
    }
    _completers.clear();
  }

  void _cleanup(dynamic error) {
    _completePending(error);
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
    if (_buffer.isEmpty) {
      return;
    }
    final currentData = _buffer.toBytes();
    var offset = 0;
    while (offset < currentData.length) {
      try {
        final decoded = _decoder.decode(currentData, offset: offset);
        offset = _decoder.consumedBytes;

        if (decoded is RespPush) {
          final native = respValueToNative(decoded);
          if (native is List) {
            pushHandler?.call(native);
          }
          continue;
        }
        final native = respValueToNative(decoded);
        if (_completers.isNotEmpty) {
          final completer = _completers.removeAt(0);
          completer.complete(native);
        }
      } on IncompleteDataException {
        break;
      } catch (e) {
        if (_completers.isNotEmpty) {
          final completer = _completers.removeAt(0);
          completer.completeError(e);
        }
        offset = currentData.length;
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

  /// Closes the socket without attempting to reconnect.
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _isReconnecting = false;
    _reconnectAttempts = 0;
    _completePending(DaredisConnectionException('Connection closed'));
    await _disposeSocket(graceful: true);
  }

  /// Sends `QUIT` and closes the socket without attempting to reconnect.
  Future<void> quit() async {
    if (_socket == null) {
      return;
    }
    _shouldReconnect = false;
    _isReconnecting = false;
    _reconnectAttempts = 0;
    try {
      _socket!.add(_encoder.encodeCommand(['QUIT']));
      await _socket!.flush();
    } catch (_) {
      // The server may close the connection before the client sees a reply.
    }
    _completePending(DaredisConnectionException('Connection closed'));
    await _disposeSocket(graceful: true);
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
      _reportReconnectFailure(error, stackTrace);
    } on DaredisException catch (error, stackTrace) {
      _isReconnecting = false;
      if (reconnectPolicy.maxAttempts != null &&
          _reconnectAttempts >= reconnectPolicy.maxAttempts!) {
        _shouldReconnect = false;
        _reportReconnectFailure(error, stackTrace);
        return;
      }
      unawaited(_handleReconnect());
    }
  }

  void _reportReconnectFailure(
    DaredisException error,
    StackTrace stackTrace,
  ) {
    final handler = reconnectFailureHandler;
    if (handler != null) {
      try {
        handler(error, stackTrace);
        return;
      } catch (handlerError, handlerStackTrace) {
        Zone.current.handleUncaughtError(handlerError, handlerStackTrace);
      }
    }
    Zone.current.handleUncaughtError(error, stackTrace);
  }

  /// Sends a single Redis command and resolves with the decoded response.
  Future<dynamic> sendCommand(
    List<dynamic> command, {
    Duration? timeout,
  }) async {
    final socket = _socket;
    if (socket == null) {
      throw DaredisConnectionException("Not connected");
    }
    final completer = Completer<dynamic>();
    _completers.add(completer);
    try {
      final encoded = _encoder.encodeCommand(command);
      socket.add(encoded);
    } catch (error, stackTrace) {
      _completers.remove(completer);
      Error.throwWithStackTrace(error, stackTrace);
    }

    final effectiveTimeout = timeout ?? commandTimeout;
    return completer.future.timeout(
      effectiveTimeout,
      onTimeout: () {
        _completers.remove(completer);
        final error = DaredisTimeoutException(
          'Command timed out after ${effectiveTimeout.inSeconds}s',
        );
        _cleanup(error);
        throw error;
      },
    );
  }

  /// Sends `HELLO` with optional authentication arguments.
  Future<dynamic> hello(int version, {String? password, String? username}) {
    return sendCommand([
      'HELLO',
      version,
      if (password != null) ...['AUTH', username ?? 'default', password],
    ]);
  }
}

/// Immutable configuration for creating [Connection] instances.
class ConnectionOptions {
  /// Redis host.
  final String host;

  /// Redis port.
  final int port;

  /// Optional ACL username.
  final String? username;

  /// Optional password for `AUTH`.
  final String? password;

  /// Socket connect timeout.
  final Duration connectTimeout;

  /// Default command timeout.
  final Duration commandTimeout;

  /// Whether to use TLS sockets.
  final bool useSsl;

  /// Reconnect behavior for newly created connections.
  final ReconnectPolicy reconnectPolicy;

  /// Optional RESP3 push frame handler.
  final PushMessageHandler? pushHandler;

  /// Optional setup callback invoked after authentication on every successful
  /// socket connect and reconnect.
  final ConnectionSetupHandler? connectionSetup;

  /// Optional callback invoked when reconnecting gives up because a reconnect
  /// attempt failed with a terminal Redis command error.
  final ReconnectFailureHandler? reconnectFailureHandler;

  const ConnectionOptions({
    this.host = 'localhost',
    this.port = 6379,
    this.username,
    this.password,
    this.connectTimeout = const Duration(seconds: 5),
    this.commandTimeout = const Duration(seconds: 30),
    this.useSsl = false,
    this.reconnectPolicy = const ReconnectPolicy(),
    this.pushHandler,
    this.connectionSetup,
    this.reconnectFailureHandler,
  });

  /// Returns a copy with the provided fields replaced.
  ConnectionOptions copyWith({
    String? host,
    int? port,
    String? username,
    String? password,
    Duration? connectTimeout,
    Duration? commandTimeout,
    bool? useSsl,
    ReconnectPolicy? reconnectPolicy,
    PushMessageHandler? pushHandler,
    ConnectionSetupHandler? connectionSetup,
    ReconnectFailureHandler? reconnectFailureHandler,
  }) {
    return ConnectionOptions(
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      commandTimeout: commandTimeout ?? this.commandTimeout,
      useSsl: useSsl ?? this.useSsl,
      reconnectPolicy: reconnectPolicy ?? this.reconnectPolicy,
      pushHandler: pushHandler ?? this.pushHandler,
      connectionSetup: connectionSetup ?? this.connectionSetup,
      reconnectFailureHandler:
          reconnectFailureHandler ?? this.reconnectFailureHandler,
    );
  }
}
