part of '../../daredis.dart';

mixin RedisScriptingCommands on RedisCommandExecutor {
  Future<T> _decodeEval<T>(
    Future<dynamic> Function() execute,
    T Function(dynamic res) decode,
  ) async {
    final res = await execute();
    return decode(res);
  }

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

  Future<String?> evalString(
    String script,
    int numKeys,
    List<String> keys,
    List<dynamic> args,
  ) => _decodeEval(
    () => eval(script, numKeys, keys, args),
    Decoders.toStringOrNull,
  );

  Future<int?> evalInt(
    String script,
    int numKeys,
    List<String> keys,
    List<dynamic> args,
  ) => _decodeEval(
    () => eval(script, numKeys, keys, args),
    Decoders.toIntOrNull,
  );

  Future<List<String>> evalListString(
    String script,
    int numKeys,
    List<String> keys,
    List<dynamic> args,
  ) => _decodeEval(
    () => eval(script, numKeys, keys, args),
    Decoders.toStringList,
  );

  Future<String?> evalRoString(
    String script,
    int numKeys,
    List<String> keys,
    List<dynamic> args,
  ) => _decodeEval(
    () => evalRo(script, numKeys, keys, args),
    Decoders.toStringOrNull,
  );

  Future<int?> evalRoInt(
    String script,
    int numKeys,
    List<String> keys,
    List<dynamic> args,
  ) => _decodeEval(
    () => evalRo(script, numKeys, keys, args),
    Decoders.toIntOrNull,
  );

  Future<List<String>> evalRoListString(
    String script,
    int numKeys,
    List<String> keys,
    List<dynamic> args,
  ) => _decodeEval(
    () => evalRo(script, numKeys, keys, args),
    Decoders.toStringList,
  );

  Future<String?> evalShaString(
    String sha1,
    int numKeys,
    List<String> keys,
    List<dynamic> args,
  ) => _decodeEval(
    () => evalSha(sha1, numKeys, keys, args),
    Decoders.toStringOrNull,
  );

  Future<int?> evalShaInt(
    String sha1,
    int numKeys,
    List<String> keys,
    List<dynamic> args,
  ) => _decodeEval(
    () => evalSha(sha1, numKeys, keys, args),
    Decoders.toIntOrNull,
  );

  Future<List<String>> evalShaListString(
    String sha1,
    int numKeys,
    List<String> keys,
    List<dynamic> args,
  ) => _decodeEval(
    () => evalSha(sha1, numKeys, keys, args),
    Decoders.toStringList,
  );

  Future<String?> evalShaRoString(
    String sha1,
    int numKeys,
    List<String> keys,
    List<dynamic> args,
  ) => _decodeEval(
    () => evalShaRo(sha1, numKeys, keys, args),
    Decoders.toStringOrNull,
  );

  Future<int?> evalShaRoInt(
    String sha1,
    int numKeys,
    List<String> keys,
    List<dynamic> args,
  ) => _decodeEval(
    () => evalShaRo(sha1, numKeys, keys, args),
    Decoders.toIntOrNull,
  );

  Future<List<String>> evalShaRoListString(
    String sha1,
    int numKeys,
    List<String> keys,
    List<dynamic> args,
  ) => _decodeEval(
    () => evalShaRo(sha1, numKeys, keys, args),
    Decoders.toStringList,
  );

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
