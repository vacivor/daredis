import '../daredis.dart';

class Daredis extends DaredisBase {
  final ConnectionOptions options;
  final Pool<Connection> _pool;
  bool _connected = false;
  bool _closed = false;

  Daredis({
    this.options = const ConnectionOptions(),
    int poolSize = 4,
    bool testOnBorrow = true,
    bool testOnReturn = false,
    ReconnectPolicy? reconnectPolicy,
    int? maxWaiters,
    Duration? acquireTimeout,
  }) : _pool = Pool<Connection>(
         config: PoolConfig(
           maxSize: poolSize,
           maxWaiters: maxWaiters,
           acquireTimeout: acquireTimeout,
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

  PoolStats get poolStats => _pool.stats;

  @override
  Future<void> connect() async {
    if (_connected) return;
    await _pool.withResource((connection) async {
      await connection.ensureConnected();
    });
    _connected = true;
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _pool.close();
  }

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) {
    ensureReady();
    return _pool.withResource((connection) async {
      await connection.ensureConnected();
      return connection.sendCommand(command, timeout: timeout);
    });
  }

  RedisPipeline pipeline() => RedisPipeline(
    (command, timeout) => sendCommand(command, timeout: timeout),
  );

  Future<RedisPubSub> openPubSub({ReconnectPolicy? reconnectPolicy}) async {
    final pubsub = RedisPubSub.fromOptions(
      options.copyWith(
        reconnectPolicy: reconnectPolicy ?? options.reconnectPolicy,
      ),
    );
    await pubsub.connect();
    return pubsub;
  }
}
