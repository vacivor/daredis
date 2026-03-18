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

/// Capability interface for clients that can open a dedicated pub/sub session.
abstract class RedisPubSubCapable {
  /// Opens a pub/sub session.
  Future<dynamic> openPubSub();
}

/// Capability interface for clients that can open a dedicated transaction
/// session.
abstract class RedisTransactionCapable {
  /// Opens a transaction session.
  Future<dynamic> openTransaction();
}
