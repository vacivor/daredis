import 'package:daredis/src/cluster_command_policy.dart';
import 'package:daredis/src/cluster_slots.dart';
import 'package:daredis/src/exceptions.dart';

import '../daredis.dart';

/// Parsed `MOVED` or `ASK` redirect returned by a Redis cluster node.
class ClusterRedirect {
  /// Hash slot that triggered the redirect.
  final int slot;

  /// Redirect target node.
  final ClusterNodeAddress address;

  /// Whether the redirect is permanent (`MOVED`) rather than transient (`ASK`).
  final bool isMoved;

  const ClusterRedirect({
    required this.slot,
    required this.address,
    required this.isMoved,
  });
}

/// Parses a `host:port` or `[ipv6]:port` cluster node address.
ClusterNodeAddress? parseClusterNodeAddress(String value) {
  if (value.startsWith('[')) {
    final endBracket = value.indexOf(']');
    if (endBracket == -1) return null;
    final host = value.substring(1, endBracket);
    final portPart = value.substring(endBracket + 2);
    final port = int.tryParse(portPart);
    if (port == null) return null;
    return ClusterNodeAddress(host, port);
  }

  final separator = value.lastIndexOf(':');
  if (separator == -1) return null;
  final host = value.substring(0, separator);
  final port = int.tryParse(value.substring(separator + 1));
  if (port == null) return null;
  return ClusterNodeAddress(host, port);
}

/// Parses a Redis error into a structured cluster redirect when possible.
ClusterRedirect? parseClusterRedirect(Object error) {
  final message = error.toString();
  final movedIndex = message.indexOf('MOVED ');
  final askIndex = message.indexOf('ASK ');
  final isMoved = movedIndex != -1;
  final isAsk = askIndex != -1;
  if (!isMoved && !isAsk) return null;

  final start = isMoved ? movedIndex : askIndex;
  final parts = message.substring(start).split(' ');
  if (parts.length < 3) return null;
  final slot = int.tryParse(parts[1]) ?? -1;
  final address = parseClusterNodeAddress(parts[2]);
  if (address == null || slot < 0) return null;
  return ClusterRedirect(slot: slot, address: address, isMoved: isMoved);
}

/// Whether an error indicates a retryable cluster condition.
bool isRetryableClusterError(Object error) {
  final message = error.toString().toUpperCase();
  return message.contains('TRYAGAIN') ||
      message.contains('CLUSTERDOWN') ||
      message.contains('LOADING');
}

/// Whether an error indicates cluster routing needs to be refreshed.
bool isClusterRoutingError(Object error) {
  final message = error.toString().toUpperCase();
  return message.contains('MOVED ') ||
      message.contains('ASK ') ||
      message.contains('CLUSTERDOWN') ||
      message.contains('TRYAGAIN') ||
      message.contains('CROSSSLOT');
}

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
        RedisClusterCommands
    implements RedisPubSubCapable {
  final ClusterOptions options;
  final Pool<_DaredisClusterConnection> _pool;
  bool _connected = false;
  bool _closed = false;

  /// Creates a cluster client.
  DaredisCluster({
    required this.options,
    int clientPoolSize = 4,
    bool testOnBorrow = true,
    bool testOnReturn = false,
  }) : _pool = Pool<_DaredisClusterConnection>(
         config: PoolConfig(
           maxSize: clientPoolSize,
           maxWaiters: options.poolMaxWaiters,
           acquireTimeout: options.poolAcquireTimeout,
           idleTimeout: options.poolIdleTimeout,
           evictionInterval: options.poolEvictionInterval,
           createMaxAttempts: options.poolCreateMaxAttempts,
           createRetryDelay: options.poolCreateRetryDelay,
           useLifo: options.poolUseLifo,
           testOnBorrow: testOnBorrow,
           testOnReturn: testOnReturn,
         ),
         create: () async {
           final client = _DaredisClusterConnection(options);
           await client.connect();
           return client;
         },
         dispose: (client) => client.close(),
         validate: (client) async {
           try {
             if (!client.isConnected) {
               await client.connect();
             }
             await client.sendCommand(['PING']);
             return true;
           } catch (_) {
             return false;
           }
         },
       );

  @override
  bool get isConnected => _connected;

  @override
  bool get isClosed => _closed;

  /// Runtime statistics for the outer client pool.
  PoolStats get poolStats => _pool.stats;

  @override
  /// Warms up the client by connecting one pooled cluster session.
  Future<void> connect() async {
    if (_connected) return;
    await _pool.withResource((client) async {
      if (!client.isConnected) {
        await client.connect();
      }
    });
    _connected = true;
  }

  @override
  /// Closes the client and all underlying node pools.
  Future<void> close() async {
    _closed = true;
    await _pool.close();
  }

  @override
  /// Sends a command through a slot-aware pooled cluster session.
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) {
    ensureReady();
    return _pool.withResource((client) async {
      if (!client.isConnected) {
        await client.connect();
      }
      return client.sendCommand(command, timeout: timeout);
    });
  }

  /// Creates a cluster-aware pipeline helper.
  ClusterPipeline pipeline() => ClusterPipeline(
    (commands) => _pool.withResource((client) async {
      for (final command in commands) {
        client.validateCommandKeys(command);
      }
    }),
    (command, timeout) => sendCommand(command, timeout: timeout),
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

  /// Opens a transaction pinned to the slot derived from [routingKey].
  ///
  /// All subsequent keyed commands issued through the returned session must
  /// target the same Redis Cluster slot.
  Future<RedisClusterTransaction> openTransaction(String routingKey) {
    ensureReady();
    return _pool.withResource((client) async {
      if (!client.isConnected) {
        await client.connect();
      }
      return client.openTransaction(routingKey);
    });
  }
}

/// Dedicated cluster transaction session pinned to one slot and one node.
class RedisClusterTransaction extends RedisTransactionSession
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
}

class _DaredisClusterConnection extends RedisClusterClient {
  final ClusterOptions options;
  final ClusterSlotCache _slotCache = ClusterSlotCache();
  final Map<ClusterNodeAddress, Pool<Connection>> _pools = {};
  bool _connected = false;
  bool _closed = false;

  _DaredisClusterConnection(this.options);

  @override
  bool get isConnected => _connected;

  @override
  bool get isClosed => _closed;

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
      _pools.putIfAbsent(node, () {
        final opts = _optionsForAddress(node);
        return Pool<Connection>(
          config: PoolConfig(
            maxSize: options.nodePoolSize,
            maxWaiters: options.poolMaxWaiters,
            acquireTimeout: options.poolAcquireTimeout,
            idleTimeout: options.poolIdleTimeout,
            evictionInterval: options.poolEvictionInterval,
            createMaxAttempts: options.poolCreateMaxAttempts,
            createRetryDelay: options.poolCreateRetryDelay,
            useLifo: options.poolUseLifo,
            testOnBorrow: true,
            testOnReturn: false,
          ),
          create: () async {
            final connection = Connection.fromOptions(opts);
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
      });
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
    return _pools.putIfAbsent(address, () {
      final opts = _optionsForAddress(address);
      return Pool<Connection>(
        config: PoolConfig(
          maxSize: options.nodePoolSize,
          maxWaiters: options.poolMaxWaiters,
          acquireTimeout: options.poolAcquireTimeout,
          idleTimeout: options.poolIdleTimeout,
          evictionInterval: options.poolEvictionInterval,
          createMaxAttempts: options.poolCreateMaxAttempts,
          createRetryDelay: options.poolCreateRetryDelay,
          useLifo: options.poolUseLifo,
        ),
        create: () async {
          final connection = Connection.fromOptions(opts);
          await connection.connect();
          return connection;
        },
        dispose: (connection) => connection.disconnect(),
      );
    });
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

class ClusterPipeline {
  final Future<void> Function(List<List<dynamic>> commands) _validator;
  final Future<dynamic> Function(List<dynamic> command, Duration? timeout)
  _sender;
  final List<PipelineItem> _items = [];
  bool _executed = false;

  ClusterPipeline(this._validator, this._sender);

  void add(List<dynamic> command, {Duration? timeout}) {
    if (_executed) {
      throw DaredisStateException('Pipeline already executed');
    }
    _items.add(PipelineItem(command, timeout));
  }

  Future<List<dynamic>> execute({Duration? timeout}) async {
    if (_executed) {
      throw DaredisStateException('Pipeline already executed');
    }
    _executed = true;
    final commands = _items.map((item) => item.command).toList();
    await _validator(commands);
    final futures = _items.map((item) => _sender(item.command, item.timeout));
    final batch = Future.wait(futures);
    if (timeout == null) {
      return await batch;
    }
    return await batch.timeout(
      timeout,
      onTimeout: () => throw DaredisTimeoutException('Pipeline timed out'),
    );
  }
}
