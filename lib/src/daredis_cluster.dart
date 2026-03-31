import 'package:daredis/src/cluster_command_policy.dart';
import 'package:daredis/src/cluster_redirect.dart';
import 'package:daredis/src/cluster_slots.dart';
import 'package:daredis/src/commands/decoders.dart';
import 'package:daredis/src/exceptions.dart';

import '../daredis.dart';

/// Seed node used to bootstrap cluster topology discovery.
class ClusterNode {
  /// Seed host.
  final String host;

  /// Seed port.
  final int port;

  const ClusterNode(this.host, this.port);
}

/// Configuration for [DaredisCluster].
class ClusterOptions {
  /// Seed nodes used to fetch initial slot metadata.
  final List<ClusterNode> seeds;

  /// Base connection options applied to per-node connections.
  final ConnectionOptions connectionOptions;

  /// Per-node connection pool size.
  final int nodePoolSize;

  /// Maximum number of waiters allowed per node pool.
  final int? poolMaxWaiters;

  /// Timeout while waiting for a pooled node connection.
  final Duration? poolAcquireTimeout;

  /// How long idle node connections stay in the pool.
  final Duration? poolIdleTimeout;

  /// Frequency used to evict idle node connections.
  final Duration? poolEvictionInterval;

  /// Maximum attempts when creating node connections.
  final int poolCreateMaxAttempts;

  /// Delay between failed node connection creation attempts.
  final Duration poolCreateRetryDelay;

  /// Whether node pools use LIFO ordering.
  final bool poolUseLifo;

  /// Maximum redirect hops per command.
  final int maxRedirects;

  /// Maximum retries for retryable cluster errors.
  final int maxRetries;

  /// Delay between retry attempts.
  final Duration retryDelay;

  /// Optional reconnect policy override for node connections.
  final ReconnectPolicy? reconnectPolicy;

  const ClusterOptions({
    required this.seeds,
    this.connectionOptions = const ConnectionOptions(),
    this.nodePoolSize = 4,
    this.poolMaxWaiters,
    this.poolAcquireTimeout,
    this.poolIdleTimeout,
    this.poolEvictionInterval,
    this.poolCreateMaxAttempts = 1,
    this.poolCreateRetryDelay = const Duration(milliseconds: 50),
    this.poolUseLifo = false,
    this.maxRedirects = 3,
    this.maxRetries = 3,
    this.retryDelay = const Duration(milliseconds: 50),
    this.reconnectPolicy,
  });
}

/// Redis Cluster client with slot-aware routing and per-node connection pools.
class DaredisCluster extends RedisClusterClient
    with
        RedisServerCommands,
        RedisServerIntrospectionCommands,
        RedisStringCommands,
        RedisKeyCommands,
        RedisListCommands,
        RedisHashCommands,
        RedisSetCommands,
        RedisSortedSetCommands,
        RedisStreamCommands,
        RedisScriptingCommands,
        RedisGeoCommands,
        RedisJsonCommands,
        RedisSearchCommands,
        RedisTimeSeriesCommands,
        RedisTopKCommands,
        RedisVectorSetCommands,
        RedisHyperLogLogCommands,
        RedisClusterCommands
    implements RedisPubSubCapable, RedisMonitorCapable {
  final ClusterOptions options;
  final _DaredisClusterConnection _router;
  bool _connected = false;
  bool _closed = false;

  /// Creates a cluster client.
  DaredisCluster({
    required this.options,
    bool testOnBorrow = true,
    bool testOnReturn = false,
  }) : _router = _DaredisClusterConnection(
         options,
         testOnBorrow: testOnBorrow,
         testOnReturn: testOnReturn,
       );

  @override
  bool get isConnected => _connected;

  @override
  bool get isClosed => _closed;

  /// Runtime statistics for the per-node connection pools.
  PoolStats get poolStats => _router.poolStats;

  @override
  /// Warms up the client by connecting one pooled cluster session.
  Future<void> connect() async {
    if (_connected) return;
    await _router.connect();
    _connected = true;
  }

  @override
  /// Closes the client and all underlying node pools.
  Future<void> close() async {
    _closed = true;
    _connected = false;
    await _router.close();
  }

  @override
  /// Sends a command through a slot-aware pooled cluster session.
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) {
    ensureReady();
    return _router.sendCommand(command, timeout: timeout);
  }

  /// Creates a cluster-aware pipeline helper.
  ClusterPipeline pipeline() => ClusterPipeline(
    (items) => _router.sendPipeline(items),
  );

  @override
  /// Opens a pub/sub session against a chosen cluster node.
  Future<RedisPubSub> openPubSub({ClusterNode? node}) async {
    if (options.seeds.isEmpty) {
      throw DaredisStateException('Cluster seeds cannot be empty');
    }
    final target = node ?? options.seeds.first;
    final opts = options.connectionOptions.copyWith(
      host: target.host,
      port: target.port,
      reconnectPolicy:
          options.reconnectPolicy ?? options.connectionOptions.reconnectPolicy,
    );
    final pubsub = RedisPubSub.fromOptions(opts);
    await pubsub.connect();
    return pubsub;
  }

  @override
  /// Opens a dedicated MONITOR session against a chosen cluster node.
  Future<RedisMonitor> openMonitor({ClusterNode? node}) async {
    if (options.seeds.isEmpty) {
      throw DaredisStateException('Cluster seeds cannot be empty');
    }
    final target = node ?? options.seeds.first;
    final opts = options.connectionOptions.copyWith(
      host: target.host,
      port: target.port,
      reconnectPolicy:
          options.reconnectPolicy ?? options.connectionOptions.reconnectPolicy,
    );
    final monitor = RedisMonitor.fromOptions(opts);
    await monitor.connect();
    return monitor;
  }

  /// Opens a transaction pinned to the slot derived from [routingKey].
  ///
  /// All subsequent keyed commands issued through the returned session must
  /// target the same Redis Cluster slot.
  Future<RedisClusterTransaction> openTransaction(String routingKey) {
    ensureReady();
    return _router.openTransaction(routingKey);
  }
}

/// Dedicated cluster transaction session pinned to one slot and one node.
class RedisClusterTransaction extends RedisTransactionSession
    with
        RedisServerCommands,
        RedisDedicatedConnectionCommands,
        RedisStringCommands,
        RedisKeyCommands,
        RedisListCommands,
        RedisHashCommands,
        RedisSetCommands,
        RedisSortedSetCommands,
        RedisStreamCommands,
        RedisScriptingCommands,
        RedisGeoCommands,
        RedisSearchCommands,
        RedisTimeSeriesCommands,
        RedisTopKCommands,
        RedisVectorSetCommands,
        RedisHyperLogLogCommands,
        RedisTransactionCommands {
  final Connection _connection;
  final ClusterSlotCache _slotCache = ClusterSlotCache();
  final int slot;
  final ClusterNodeAddress nodeAddress;
  bool _closed = false;

  RedisClusterTransaction._(this._connection, this.slot, this.nodeAddress);

  @override
  bool get isConnected => _connection.isConnected;

  @override
  bool get isClosed => _closed;

  @override
  Future<void> connect() async {
    _ensureOpen();
    await _connection.connect();
  }

  @override
  /// Permanently closes the pinned cluster transaction connection.
  Future<void> close() async {
    _closed = true;
    await _connection.disconnect();
  }

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    ensureReady();
    ClusterCommandPolicy.requireKnownSpec(
      command,
      context: 'transaction routing',
    );
    ClusterCommandPolicy.validatePinnedSlot(
      command,
      slot: slot,
      slotCache: _slotCache,
    );
    await _connection.ensureConnected();
    try {
      return await _connection.sendCommand(command, timeout: timeout);
    } catch (error) {
      if (isClusterRoutingError(error)) {
        throw DaredisClusterException(
          'Cluster transaction for slot $slot on $nodeAddress can no longer '
          'continue: $error',
        );
      }
      rethrow;
    }
  }

  /// Sends `QUIT` and closes the pinned cluster transaction connection.
  Future<void> quit() async {
    _ensureOpen();
    _closed = true;
    await _connection.quit();
  }

  void _ensureOpen() {
    if (_closed) {
      throw DaredisStateException('Redis cluster transaction session is closed');
    }
  }
}

class _DaredisClusterConnection extends RedisClusterClient {
  final ClusterOptions options;
  final bool testOnBorrow;
  final bool testOnReturn;
  final ClusterSlotCache _slotCache = ClusterSlotCache();
  final Map<ClusterNodeAddress, Pool<Connection>> _pools = {};
  late final PoolConfig _nodePoolConfig;
  bool _connected = false;
  bool _closed = false;

  _DaredisClusterConnection(
    this.options, {
    required this.testOnBorrow,
    required this.testOnReturn,
  }) : _nodePoolConfig = PoolConfig(
         maxSize: options.nodePoolSize,
         maxWaiters: options.poolMaxWaiters,
         acquireTimeout: options.poolAcquireTimeout,
         idleTimeout: options.poolIdleTimeout,
         evictionInterval: options.poolEvictionInterval,
         createMaxAttempts: options.poolCreateMaxAttempts,
         createRetryDelay: options.poolCreateRetryDelay,
         useLifo: options.poolUseLifo,
         testOnBorrow: testOnBorrow,
         testOnReturn: testOnReturn,
       );

  @override
  bool get isConnected => _connected;

  @override
  bool get isClosed => _closed;

  PoolStats get poolStats {
    if (_pools.isEmpty) {
      return PoolStats(
        total: 0,
        idle: 0,
        inUse: 0,
        creating: 0,
        waiters: 0,
        maxSize: _nodePoolConfig.maxSize,
        maxIdle: _nodePoolConfig.maxIdle,
        minIdle: _nodePoolConfig.minIdle,
        createdCount: 0,
        disposedCount: 0,
        createFailureCount: 0,
        lastEvictionAt: null,
        lastCreateFailureAt: null,
        isClosed: _closed,
      );
    }

    var total = 0;
    var idle = 0;
    var inUse = 0;
    var creating = 0;
    var waiters = 0;
    var maxSize = 0;
    var maxIdle = 0;
    var minIdle = 0;
    var createdCount = 0;
    var disposedCount = 0;
    var createFailureCount = 0;
    DateTime? lastEvictionAt;
    DateTime? lastCreateFailureAt;

    for (final pool in _pools.values) {
      final stats = pool.stats;
      total += stats.total;
      idle += stats.idle;
      inUse += stats.inUse;
      creating += stats.creating;
      waiters += stats.waiters;
      maxSize += stats.maxSize;
      maxIdle += stats.maxIdle;
      minIdle += stats.minIdle;
      createdCount += stats.createdCount;
      disposedCount += stats.disposedCount;
      createFailureCount += stats.createFailureCount;
      if (stats.lastEvictionAt != null &&
          (lastEvictionAt == null ||
              stats.lastEvictionAt!.isAfter(lastEvictionAt))) {
        lastEvictionAt = stats.lastEvictionAt;
      }
      if (stats.lastCreateFailureAt != null &&
          (lastCreateFailureAt == null ||
              stats.lastCreateFailureAt!.isAfter(lastCreateFailureAt))) {
        lastCreateFailureAt = stats.lastCreateFailureAt;
      }
    }

    return PoolStats(
      total: total,
      idle: idle,
      inUse: inUse,
      creating: creating,
      waiters: waiters,
      maxSize: maxSize,
      maxIdle: maxIdle,
      minIdle: minIdle,
      createdCount: createdCount,
      disposedCount: disposedCount,
      createFailureCount: createFailureCount,
      lastEvictionAt: lastEvictionAt,
      lastCreateFailureAt: lastCreateFailureAt,
      isClosed: _closed,
    );
  }

  @override
  Future<void> connect() async {
    if (_connected) return;
    if (options.seeds.isEmpty) {
      throw DaredisConnectionException('Cluster seeds cannot be empty');
    }

    for (final seed in options.seeds) {
      final seedOptions = options.connectionOptions.copyWith(
        host: seed.host,
        port: seed.port,
        reconnectPolicy:
            options.reconnectPolicy ??
            options.connectionOptions.reconnectPolicy,
      );
      final connection = Connection.fromOptions(seedOptions);
      try {
        await connection.connect();
        final slots = await connection.sendCommand(['CLUSTER', 'SLOTS']);
        _slotCache.updateFromSlotsResponse(slots);
        await connection.disconnect();
        if (_slotCache.isEmpty) {
          throw DaredisConnectionException(
            'Cluster slots response did not contain any nodes',
          );
        }
        _buildPoolsFromSlots();
        _connected = true;
        return;
      } catch (_) {
        await connection.disconnect();
      }
    }

    throw DaredisConnectionException('Unable to connect to any cluster seed');
  }

  @override
  Future<void> close() async {
    _closed = true;
    _connected = false;
    for (final pool in _pools.values) {
      await pool.close();
    }
    _pools.clear();
  }

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) {
    ensureReady();
    ClusterCommandPolicy.validateSameSlot(command, _slotCache);
    return _sendWithRedirect(command, timeout: timeout, attempt: 0);
  }

  void validateCommandKeys(List<dynamic> command) {
    ClusterCommandPolicy.validateSameSlot(command, _slotCache);
  }

  Future<List<dynamic>> sendPipeline(List<PipelineItem> items) async {
    ensureReady();
    if (items.isEmpty) {
      return const [];
    }

    final pool = await _pipelinePoolForItems(items);
    return pool.withResource((connection) async {
      await connection.ensureConnected();
      final futures = [
        for (final item in items)
          connection.sendCommand(item.command, timeout: item.timeout),
      ];
      return Future.wait(futures);
    });
  }

  Future<RedisClusterTransaction> openTransaction(String routingKey) async {
    final slot = _slotCache.slotForKey(routingKey);
    var node = _slotCache.nodeForSlot(slot);
    if (node == null) {
      await _refreshSlots();
      node = _slotCache.nodeForSlot(slot);
    }
    if (node == null) {
      throw DaredisClusterException(
        'Unable to resolve a cluster node for routing key "$routingKey" in slot $slot',
      );
    }

    final connection = Connection.fromOptions(_optionsForAddress(node));
    await connection.connect();
    return RedisClusterTransaction._(connection, slot, node);
  }

  Future<dynamic> _sendWithRedirect(
    List<dynamic> command, {
    Duration? timeout,
    required int attempt,
  }) async {
    final key = ClusterCommandPolicy.firstKey(command);
    final pool = key == null ? _anyPool() : _poolForKey(key);
    try {
      return await pool.withResource(
        (connection) => connection.sendCommand(command, timeout: timeout),
      );
    } catch (error) {
      if (isRetryableClusterError(error) && attempt < options.maxRetries) {
        await Future.delayed(options.retryDelay);
        return _sendWithRedirect(
          command,
          timeout: timeout,
          attempt: attempt + 1,
        );
      }
      final redirect = parseClusterRedirect(error);
      if (redirect == null || attempt >= options.maxRedirects) {
        if (error is DaredisClusterException) {
          rethrow;
        }
        if (isClusterRoutingError(error)) {
          throw DaredisClusterException(error.toString());
        }
        rethrow;
      }
      final redirectPool = _poolForAddress(redirect.address);
      if (redirect.isMoved) {
        _slotCache.updateSlot(redirect.slot, redirect.address);
        await _refreshSlots(hint: redirect.address);
        return redirectPool.withResource(
          (connection) => connection.sendCommand(command, timeout: timeout),
        );
      }
      return redirectPool.withResource((connection) async {
        await connection.sendCommand(['ASKING']);
        return connection.sendCommand(command, timeout: timeout);
      });
    }
  }

  void _buildPoolsFromSlots() {
    for (final node in _slotCache.uniqueNodes()) {
      _pools.putIfAbsent(node, () => _createNodePool(_optionsForAddress(node)));
    }
  }

  Pool<Connection> _anyPool() {
    if (_pools.isEmpty) {
      throw DaredisConnectionException('Cluster pools are not initialized');
    }
    return _pools.values.first;
  }

  Pool<Connection> _poolForKey(String key) {
    final node = _slotCache.nodeForKey(key);
    if (node == null) {
      return _anyPool();
    }
    return _poolForAddress(node);
  }

  Pool<Connection> _poolForAddress(ClusterNodeAddress address) {
    return _pools.putIfAbsent(
      address,
      () => _createNodePool(_optionsForAddress(address)),
    );
  }

  Future<Pool<Connection>> _pipelinePoolForItems(List<PipelineItem> items) async {
    ClusterNodeAddress? pipelineNode;

    for (final item in items) {
      ClusterCommandPolicy.requireKnownSpec(
        item.command,
        context: 'pipeline routing',
      );
      ClusterCommandPolicy.validateSameSlot(item.command, _slotCache);
      final key = ClusterCommandPolicy.firstKey(item.command);
      if (key == null) {
        continue;
      }

      var node = _slotCache.nodeForKey(key);
      if (node == null) {
        await _refreshSlots();
        node = _slotCache.nodeForKey(key);
      }
      if (node == null) {
        throw DaredisClusterException(
          'Unable to resolve a cluster node for pipeline command ${item.command.first}',
        );
      }
      if (pipelineNode != null && pipelineNode != node) {
        throw DaredisClusterException(
          'Cluster pipeline commands must route to the same node. '
          'Use hash tags or separate pipelines.',
        );
      }
      pipelineNode = node;
    }

    return pipelineNode == null ? _anyPool() : _poolForAddress(pipelineNode);
  }

  Pool<Connection> _createNodePool(ConnectionOptions options) {
    return Pool<Connection>(
      config: _nodePoolConfig,
      create: () async {
        final connection = Connection.fromOptions(options);
        await connection.connect();
        return connection;
      },
      dispose: (connection) => connection.disconnect(),
      validate: (connection) async {
        try {
          await connection.ensureConnected();
          final res = await connection.sendCommand(['PING']);
          final text = Decoders.toStringOrNull(res);
          return text == 'PONG' || text == 'OK';
        } catch (_) {
          return false;
        }
      },
    );
  }

  ConnectionOptions _optionsForAddress(ClusterNodeAddress address) {
    return options.connectionOptions.copyWith(
      host: address.host,
      port: address.port,
      reconnectPolicy:
          options.reconnectPolicy ??
          options.connectionOptions.reconnectPolicy,
    );
  }

  Future<void> _refreshSlots({ClusterNodeAddress? hint}) async {
    final candidates = <ClusterNodeAddress>[?hint, ..._pools.keys];
    for (final node in candidates) {
      final pool = _poolForAddress(node);
      try {
        final slots = await pool.withResource(
          (connection) => connection.sendCommand(['CLUSTER', 'SLOTS']),
        );
        _slotCache.updateFromSlotsResponse(slots);
        _buildPoolsFromSlots();
        return;
      } catch (_) {
        continue;
      }
    }
  }

}

class ClusterPipeline extends RedisPipeline {
  ClusterPipeline(super.sender);
}
