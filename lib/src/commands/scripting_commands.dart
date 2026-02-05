part of '../../daredis.dart';

extension RedisScrptingCommands on RedisCommandExecutor {
  Future<dynamic> eval(
    String script,
    int numKeys,
    List<String> keys,
    List<dynamic> args,
  ) {
    return sendCommand(['EVAL', script, numKeys, ...keys, ...args]);
  }

  Future<dynamic> evalRo(
    String script,
    int numKeys,
    List<String> keys,
    List<dynamic> args,
  ) {
    return sendCommand(['EVAL_RO', script, numKeys, ...keys, ...args]);
  }

  Future<dynamic> evalSha(
    String sha1,
    int numKeys,
    List<String> keys,
    List<dynamic> args,
  ) {
    return sendCommand(['EVALSHA', sha1, numKeys, ...keys, ...args]);
  }

  Future<dynamic> evalShaRo(
    String sha1,
    int numKeys,
    List<String> keys,
    List<dynamic> args,
  ) {
    return sendCommand(['EVALSHA_RO', sha1, numKeys, ...keys, ...args]);
  }

  Future<String> scriptLoad(String script) async {
    final res = await sendCommand(['SCRIPT', 'LOAD', script]);
    return Decoders.string(res);
  }

  Future<List<bool>> scriptExists(List<String> sha1s) async {
    final res = await sendCommand(['SCRIPT', 'EXISTS', ...sha1s]);
    if (res is List) {
      return res.map((e) => Decoders.toBool(e)).toList();
    }
    return [];
  }

  Future<String> scriptFlush() async {
    final res = await sendCommand(['SCRIPT', 'FLUSH']);
    return Decoders.string(res);
  }
}
