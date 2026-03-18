import '../daredis.dart';

/// Standalone Redis client backed by a reusable connection pool.
class Daredis extends RedisClient
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
        RedisHyperLogLogCommands
    implements RedisPubSubCapable, RedisTransactionCapable {
  final ConnectionOptions options;
  final Pool<Connection> _pool;
  bool _connected = false;
  bool _closed = false;

  /// Creates a standalone client with pooled connections.
  Daredis({
    this.options = const ConnectionOptions(),
    int poolSize = 4,
    bool testOnBorrow = true,
    bool testOnReturn = false,
    ReconnectPolicy? reconnectPolicy,
    int? maxWaiters,
    Duration? acquireTimeout,
    Duration? idleTimeout,
    Duration? evictionInterval,
    int createMaxAttempts = 1,
    Duration createRetryDelay = const Duration(milliseconds: 50),
    bool useLifo = false,
  }) : _pool = Pool<Connection>(
         config: PoolConfig(
           maxSize: poolSize,
           maxWaiters: maxWaiters,
           acquireTimeout: acquireTimeout,
           idleTimeout: idleTimeout,
           evictionInterval: evictionInterval,
           createMaxAttempts: createMaxAttempts,
           createRetryDelay: createRetryDelay,
           useLifo: useLifo,
           testOnBorrow: testOnBorrow,
           testOnReturn: testOnReturn,
         ),
         create: () async {
           final connection = Connection.fromOptions(
             options.copyWith(
               reconnectPolicy: reconnectPolicy ?? options.reconnectPolicy,
             ),
           );
           await connection.connect();
           return connection;
         },
         dispose: (connection) => connection.disconnect(),
         validate: (connection) async {
           try {
             await connection.ensureConnected();
             final res = await connection.sendCommand(['PING']);
             final text = res?.toString();
             return text == 'PONG' || text == 'OK';
           } catch (_) {
             return false;
           }
         },
       );

  @override
  bool get isConnected => _connected;

  @override
  bool get isClosed => _closed;

  /// Runtime statistics for the underlying connection pool.
  PoolStats get poolStats => _pool.stats;

  @override
  /// Warms up the pool by acquiring and validating a connection.
  Future<void> connect() async {
    if (_connected) return;
    await _pool.withResource((connection) async {
      await connection.ensureConnected();
    });
    _connected = true;
  }

  @override
  /// Closes the client and disposes the underlying connection pool.
  Future<void> close() async {
    _closed = true;
    await _pool.close();
  }

  @override
  /// Sends a command using a pooled connection.
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) {
    ensureReady();
    return _pool.withResource((connection) async {
      await connection.ensureConnected();
      return connection.sendCommand(command, timeout: timeout);
    });
  }

  /// Creates a pipeline helper that executes through this client.
  RedisPipeline pipeline() => RedisPipeline(
    (command, timeout) => sendCommand(command, timeout: timeout),
  );

  @override
  /// Opens a dedicated pub/sub session using the client's connection options.
  Future<RedisPubSub> openPubSub({ReconnectPolicy? reconnectPolicy}) async {
    final pubsub = RedisPubSub.fromOptions(
      options.copyWith(
        reconnectPolicy: reconnectPolicy ?? options.reconnectPolicy,
      ),
    );
    await pubsub.connect();
    return pubsub;
  }

  @override
  /// Opens a dedicated transaction session on a pinned connection.
  Future<RedisTransaction> openTransaction({
    ReconnectPolicy? reconnectPolicy,
  }) async {
    final transaction = RedisTransaction.fromOptions(
      options.copyWith(
        reconnectPolicy: reconnectPolicy ?? options.reconnectPolicy,
      ),
    );
    await transaction.connect();
    return transaction;
  }
}
