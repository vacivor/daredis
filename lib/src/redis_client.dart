import 'package:daredis/src/command_executor.dart';
import 'package:daredis/src/exceptions.dart';

/// Lowest-level client lifecycle abstraction shared by concrete Redis clients
/// and dedicated sessions. Command mixins are composed on top of these types.
abstract class RedisClient implements RedisCommandExecutor {
  /// Whether the client currently has an active underlying connection.
  bool get isConnected;

  /// Whether the client has been permanently closed.
  bool get isClosed;

  /// Establishes the underlying connection or warms up the client.
  Future<void> connect();

  /// Closes the client and releases all underlying resources.
  Future<void> close();

  /// Throws when the client is closed or not yet connected.
  void ensureReady() {
    if (isClosed) {
      throw DaredisStateException('Redis client is closed');
    }
    if (!isConnected) {
      throw DaredisStateException('Redis client is not connected');
    }
  }
}

/// Base type for cluster-aware clients that can safely expose cluster-only
/// command mixins.
abstract class RedisClusterClient extends RedisClient {}

/// Base type for dedicated transaction sessions that can safely expose
/// WATCH/MULTI/EXEC command mixins on a pinned connection.
abstract class RedisTransactionSession extends RedisClient {}

/// Marker interface for clients that expose a dedicated pub/sub session API.
///
/// Concrete client types define the actual `openPubSub(...)` signature because
/// standalone and cluster clients accept different configuration parameters.
abstract class RedisPubSubCapable {}

/// Marker interface for clients that expose a dedicated transaction session
/// API.
///
/// Concrete client types define the actual `openTransaction(...)` signature
/// because standalone and cluster transaction openers have different routing
/// requirements.
abstract class RedisTransactionCapable {}

/// Marker interface for clients that expose a dedicated MONITOR session API.
///
/// Concrete client types define the actual `openMonitor(...)` signature because
/// standalone and cluster clients accept different configuration parameters.
abstract class RedisMonitorCapable {}
