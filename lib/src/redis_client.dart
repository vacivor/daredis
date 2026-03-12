import 'package:daredis/src/command_executor.dart';
import 'package:daredis/src/exceptions.dart';

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
