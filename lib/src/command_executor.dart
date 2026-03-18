/// Lowest-level interface able to send a raw Redis command.
abstract class RedisCommandExecutor {
  /// Sends a command and resolves with the decoded Redis reply.
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout});
}
