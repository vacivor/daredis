abstract class RedisCommandExecutor {
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout});
}
