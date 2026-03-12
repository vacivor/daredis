part of '../../daredis.dart';

extension RedisListCommands on RedisCommandExecutor {
  Future<int> lPush(String key, dynamic values) async {
    final res = await sendCommand([
      'LPUSH',
      key,
      if (values is List) ...values else values,
    ]);
    return Decoders.toInt(res);
  }

  Future<int> rPush(String key, dynamic values) async {
    final res = await sendCommand([
      'RPUSH',
      key,
      if (values is List) ...values else values,
    ]);
    return Decoders.toInt(res);
  }

  Future<String?> lPop(String key) async {
    final res = await sendCommand(['LPOP', key]);
    return Decoders.toStringOrNull(res);
  }

  Future<List<String>> lPopCount(String key, int count) async {
    final res = await sendCommand(['LPOP', key, count]);
    if (res is List) return res.map((e) => e.toString()).toList();
    if (res != null) return [res.toString()];
    return [];
  }

  Future<String?> rPop(String key) async {
    final res = await sendCommand(['RPOP', key]);
    return Decoders.toStringOrNull(res);
  }

  Future<List<String>> rPopCount(String key, int count) async {
    final res = await sendCommand(['RPOP', key, count]);
    if (res is List) return res.map((e) => e.toString()).toList();
    if (res != null) return [res.toString()];
    return [];
  }

  Future<List<String>> lRange(String key, int start, int stop) async {
    final res = await sendCommand(['LRANGE', key, start, stop]);
    if (res is List) return res.map((e) => e.toString()).toList();
    return [];
  }

  Future<int> lLen(String key) async {
    final res = await sendCommand(['LLEN', key]);
    return Decoders.toInt(res);
  }

  Future<String?> lIndex(String key, int index) async {
    final res = await sendCommand(['LINDEX', key, index]);
    return Decoders.toStringOrNull(res);
  }

  Future<String> lSet(String key, int index, String value) async {
    final res = await sendCommand(['LSET', key, index, value]);
    return Decoders.string(res);
  }

  Future<int> lRem(String key, int count, String value) async {
    final res = await sendCommand(['LREM', key, count, value]);
    return Decoders.toInt(res);
  }

  Future<String> lTrim(String key, int start, int stop) async {
    final res = await sendCommand(['LTRIM', key, start, stop]);
    return Decoders.string(res);
  }

  Future<int> lInsertBefore(String key, String pivot, String value) async {
    final res = await sendCommand(['LINSERT', key, 'BEFORE', pivot, value]);
    return Decoders.toInt(res);
  }

  Future<int> lInsertAfter(String key, String pivot, String value) async {
    final res = await sendCommand(['LINSERT', key, 'AFTER', pivot, value]);
    return Decoders.toInt(res);
  }

  Future<Map<String, String>?> bLPop(List<String> keys, int timeout) async {
    final res = await sendCommand(['BLPOP', ...keys, timeout]);
    if (res is List && res.length == 2) {
      return {res[0].toString(): res[1].toString()};
    }
    return null;
  }

  Future<Map<String, String>?> bRPop(List<String> keys, int timeout) async {
    final res = await sendCommand(['BRPOP', ...keys, timeout]);
    if (res is List && res.length == 2) {
      return {res[0].toString(): res[1].toString()};
    }
    return null;
  }

  Future<String?> rPopLPush(String source, String destination) async {
    final res = await sendCommand(['RPOPLPUSH', source, destination]);
    return Decoders.toStringOrNull(res);
  }

  Future<String?> lMove(
    String source,
    String destination,
    String whereFrom,
    String whereTo,
  ) async {
    final res = await sendCommand([
      'LMOVE',
      source,
      destination,
      whereFrom,
      whereTo,
    ]);
    return Decoders.toStringOrNull(res);
  }

  Future<String?> bLMove(
    String source,
    String destination,
    String whereFrom,
    String whereTo,
    int timeout,
  ) async {
    final res = await sendCommand([
      'BLMOVE',
      source,
      destination,
      whereFrom,
      whereTo,
      timeout,
    ]);
    return Decoders.toStringOrNull(res);
  }
}
