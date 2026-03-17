part of '../../daredis.dart';

mixin RedisStringCommands on RedisCommandExecutor {
  Future<String?> get(String key) async {
    var res = await sendCommand(['GET', key]);
    return Decoders.toStringOrNull(res);
  }

  Future<bool> set(
    String key,
    String value, {
    int? ex,
    int? px,
    bool? nx,
    bool? xx,
  }) async {
    final args = <dynamic>['SET', key, value];
    if (ex != null) args.addAll(['EX', ex]);
    if (px != null) args.addAll(['PX', px]);
    if (nx == true) args.add('NX');
    if (xx == true) args.add('XX');
    var res = await sendCommand(args);
    return Decoders.toBool(res);
  }

  Future<bool> setNx(String key, String value) async {
    final res = await sendCommand(['SETNX', key, value]);
    return Decoders.toBool(res);
  }

  Future<String> setEx(String key, int seconds, String value) async {
    final res = await sendCommand(['SETEX', key, seconds, value]);
    return Decoders.string(res);
  }

  Future<String?> setGet(
    String key,
    String value, {
    int? ex,
    int? px,
    bool? nx,
    bool? xx,
  }) async {
    final args = ['SET', key, value, 'GET'];
    if (ex != null) args.addAll(['EX', ex.toString()]);
    if (px != null) args.addAll(['PX', px.toString()]);
    if (nx == true) args.add('NX');
    if (xx == true) args.add('XX');

    final res = await sendCommand(args);
    return Decoders.toStringOrNull(res);
  }

  Future<String?> getDel(String key) async {
    final res = await sendCommand(['GETDEL', key]);
    return Decoders.toStringOrNull(res);
  }

  Future<String?> getEx(
    String key, {
    int? ex,
    int? px,
    bool? nx,
    bool? xx,
  }) async {
    final args = ['GETEX', key];
    if (ex != null) args.addAll(['EX', ex.toString()]);
    if (px != null) args.addAll(['PX', px.toString()]);
    if (nx == true) args.add('NX');
    if (xx == true) args.add('XX');

    final res = await sendCommand(args);
    return Decoders.toStringOrNull(res);
  }

  Future<String?> getSet(String key, String value) async {
    final res = await sendCommand(['GETSET', key, value]);
    return Decoders.toStringOrNull(res);
  }

  Future<int> setRange(String key, int offset, String value) async {
    final res = await sendCommand(['SETRANGE', key, offset, value]);
    return Decoders.toInt(res);
  }

  Future<String> getRange(String key, int start, int end) async {
    final res = await sendCommand(['GETRANGE', key, start, end]);
    return Decoders.string(res);
  }

  Future<List<String?>> mGet(List<String> keys) async {
    final res = await sendCommand(['MGET', ...keys]);
    if (res is List) return res.map((e) => e?.toString()).toList();
    return [];
  }

  Future<String> mSet(Map<String, String> keyValues) async {
    final args = ['MSET'];
    keyValues.forEach((k, v) => args.addAll([k, v]));
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<int> incr(String key) async {
    final res = await sendCommand(['INCR', key]);
    return Decoders.toInt(res);
  }

  Future<int> incrBy(String key, int increment) async {
    final res = await sendCommand(['INCRBY', key, increment]);
    return Decoders.toInt(res);
  }

  Future<double> incrByFloat(String key, double increment) async {
    var res = await sendCommand(['INCRBYFLOAT', key, increment]);
    return Decoders.toDouble(res);
  }

  Future<int> decr(String key) async {
    final res = await sendCommand(['DECR', key]);
    return Decoders.toInt(res);
  }

  Future<int> decrBy(String key, int decrement) async {
    final res = await sendCommand(['DECRBY', key, decrement]);
    return Decoders.toInt(res);
  }

  Future<int> append(String key, String value) async {
    final res = await sendCommand(['APPEND', key, value]);
    return Decoders.toInt(res);
  }

  Future<int> strlen(String key) async {
    final res = await sendCommand(['STRLEN', key]);
    return Decoders.toInt(res);
  }

  Future<String> pSetEx(String key, int milliseconds, String value) async {
    final res = await sendCommand(['PSETEX', key, milliseconds, value]);
    return Decoders.string(res);
  }

  Future<int> setBit(String key, int offset, int value) async {
    final res = await sendCommand(['SETBIT', key, offset, value]);
    return Decoders.toInt(res);
  }

  Future<int> getBit(String key, int offset) async {
    final res = await sendCommand(['GETBIT', key, offset]);
    return Decoders.toInt(res);
  }

  Future<bool> mSetNx(Map<String, String> keyValues) async {
    final args = ['MSETNX'];
    keyValues.forEach((k, v) => args.addAll([k, v]));
    final res = await sendCommand(args);
    return Decoders.toBool(res);
  }

  Future<int> bitCount(String key, {int? start, int? end}) async {
    final args = ['BITCOUNT', key];
    if (start != null && end != null) {
      args.addAll([start.toString(), end.toString()]);
    }
    final res = await sendCommand(args);
    return Decoders.toInt(res);
  }

  Future<int> bitPos(String key, int bit, {int? start, int? end}) async {
    final args = ['BITPOS', key, bit];
    if (start != null) args.add(start);
    if (end != null) args.add(end);
    final res = await sendCommand(args);
    return Decoders.toInt(res);
  }

  Future<List<int?>> bitField(String key, List<dynamic> subcommands) async {
    final args = ['BITFIELD', key, ...subcommands];
    final res = await sendCommand(args);
    if (res is List) {
      return res.map((e) => e == null ? null : e as int).toList();
    }
    return [];
  }

  Future<List<int?>> bitFieldWith(String key, BitFieldBuilder builder) {
    return bitField(key, builder.subcommands);
  }

  Future<List<int?>> bitFieldReadonly(
    String key,
    List<dynamic> subcommands,
  ) async {
    final args = ['BITFIELD_RO', key, ...subcommands];
    final res = await sendCommand(args);
    if (res is List) {
      return res.map((e) => e == null ? null : e as int).toList();
    }
    return [];
  }

  Future<List<int?>> bitFieldReadonlyWith(String key, BitFieldBuilder builder) {
    return bitFieldReadonly(key, builder.subcommands);
  }

  Future<int> bitOp(
    String operation,
    String destKey,
    List<String> srcKeys,
  ) async {
    final args = ['BITOP', operation, destKey, ...srcKeys];
    final res = await sendCommand(args);
    return Decoders.toInt(res);
  }

  Future<String?> lcs(String key1, String key2, {bool? len, bool? idx}) async {
    final args = ['LCS', key1, key2];
    if (len == true) args.add('LEN');
    if (idx == true) args.add('IDX');
    final res = await sendCommand(args);
    return Decoders.toStringOrNull(res);
  }

  Future<String?> substr(String key, int start, int end) async {
    final res = await sendCommand(['SUBSTR', key, start, end]);
    return Decoders.toStringOrNull(res);
  }

  Future<int> mSetEx(
    Map<String, String> keyValues, {
    bool? nx,
    bool? xx,
    int? ex,
    int? px,
    int? exAt,
    int? pxAt,
    bool? keepTtl,
  }) async {
    throw DaredisUnsupportedException(
      'MSETEX is not a Redis command. Use SET with EX/PX for each key.',
    );
  }
}
