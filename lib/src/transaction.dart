import '../daredis.dart';

/// Dedicated Redis transaction session bound to a single connection.
///
/// Use [Daredis.openTransaction] to obtain an instance that can safely issue
/// `WATCH`, `MULTI`, `EXEC`, and `DISCARD` on the same socket.
class RedisTransaction extends RedisTransactionSession
    with
        RedisServerCommands,
        RedisStringCommands,
        RedisKeyCommands,
        RedisListCommands,
        RedisHashCommands,
        RedisSetCommands,
        RedisSortedSetCommands,
        RedisStreamCommands,
        RedisScriptingCommands,
        RedisGeoCommands,
        RedisHyperLogLogCommands,
        RedisTransactionCommands {
  final Connection _connection;
  bool _closed = false;

  RedisTransaction._(this._connection);

  /// Creates a transaction session from reusable [ConnectionOptions].
  factory RedisTransaction.fromOptions(ConnectionOptions options) {
    return RedisTransaction._(Connection.fromOptions(options));
  }

  @override
  bool get isConnected => _connection.isConnected;

  @override
  bool get isClosed => _closed;

  @override
  /// Opens the underlying pinned connection.
  Future<void> connect() async {
    if (_closed) {
      _closed = false;
    }
    await _connection.connect();
  }

  @override
  /// Closes the pinned transaction connection.
  Future<void> close() async {
    _closed = true;
    await _connection.disconnect();
  }

  @override
  /// Sends a command through the dedicated transaction connection.
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    ensureReady();
    await _connection.ensureConnected();
    return _connection.sendCommand(command, timeout: timeout);
  }
}
