import 'package:daredis/src/command_executor.dart';
import 'package:daredis/src/exceptions.dart';

/// Lowest-level client lifecycle abstraction shared by concrete Redis clients
/// and dedicated sessions. Command mixins are composed on top of these types.
abstract class RedisClient implements RedisCommandExecutor {
  bool get isConnected;

  bool get isClosed;

  Future<void> connect();

  Future<void> close();

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

abstract class RedisPubSubCapable {
  Future<dynamic> openPubSub();
}

abstract class RedisTransactionCapable {
  Future<dynamic> openTransaction();
}
