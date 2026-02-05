import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:daredis/src/exceptions.dart';
import 'package:daredis/src/resp.dart';

typedef PushMessageHandler = void Function(List<dynamic> message);

class ReconnectPolicy {
  final int? maxAttempts;
  final Duration delay;

  const ReconnectPolicy({
    this.maxAttempts,
    this.delay = const Duration(seconds: 2),
  });
}

class Connection {
  final String host;
  final int port;
  final String? username;
  final String? password;
  final Duration connectTimeout;
  final Duration commandTimeout;
  final bool useSsl;
  final ReconnectPolicy reconnectPolicy;
  final PushMessageHandler? pushHandler;

  final _decoder = RespDecoder();
  final _encoder = RespEncoder();
  final _completers = <Completer<dynamic>>[];
  final _buffer = BytesBuilder();
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;

  late Socket? _socket;

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
  });

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
    );
  }

  Future<void> connect() async {
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
          await sendCommand(['AUTH', username!, password!]);
        } else {
          await sendCommand(['AUTH', password!]);
        }
      }
      _reconnectAttempts = 0;
    } catch (e) {
      if (!_isReconnecting) {
        throw DaredisNetworkException('Failed to connect to $host:$port: $e');
      }
    }
  }

  bool get isConnected => _socket != null;

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
    _handleReconnect();
  }

  void _onDone() {
    _cleanup(null);
    _handleReconnect();
  }

  void _cleanup(dynamic error) {
    final e = error is DaredisException
        ? error
        : DaredisNetworkException(
            error == null ? 'Connection closed' : 'Connection error: $error',
          );
    for (var completer in _completers) {
      completer.completeError(e);
    }
    _completers.clear();
    _socket?.destroy();
    _socket = null;
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
        _buffer.clear();
        break;
      }
    }
  }

  // 断开连接
  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
  }

  Future<void> _handleReconnect() async {
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

  // 发送命令并获取结果
  Future<dynamic> sendCommand(
    List<dynamic> command, {
    Duration? timeout,
  }) async {
    if (_socket == null) {
      throw DaredisConnectionException("Not connected");
    }
    final encoded = _encoder.encodeCommand(command);
    _socket!.add(encoded);
    final completer = Completer<dynamic>();
    _completers.add(completer);

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

  Future<dynamic> hello(int version, {String? password, String? username}) {
    return sendCommand([
      'HELLO',
      version.toString(),
      if (password != null) ...['AUTH', username ?? 'default', password],
    ]);
  }
}

class ConnectionOptions {
  final String host;
  final int port;
  final String? username;
  final String? password;
  final Duration connectTimeout;
  final Duration commandTimeout;
  final bool useSsl;
  final ReconnectPolicy reconnectPolicy;
  final PushMessageHandler? pushHandler;

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
  });

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
    );
  }
}
