import 'package:daredis/src/redis_client.dart';
import 'package:daredis/src/command_executor.dart';
import 'package:daredis/src/connect.dart';

class RedisTransaction extends RedisClient implements RedisCommandExecutor {
  final Connection _connection;
  bool _closed = false;

  RedisTransaction._(this._connection);

  factory RedisTransaction.fromOptions(ConnectionOptions options) {
    return RedisTransaction._(Connection.fromOptions(options));
  }

  @override
  bool get isConnected => _connection.isConnected;

  @override
  bool get isClosed => _closed;

  @override
  Future<void> connect() async {
    if (_closed) {
      _closed = false;
    }
    await _connection.connect();
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _connection.disconnect();
  }

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    ensureReady();
    await _connection.ensureConnected();
    return _connection.sendCommand(command, timeout: timeout);
  }
}
