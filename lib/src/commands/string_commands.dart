part of '../../daredis.dart';

mixin RedisStringCommands on RedisCommandExecutor {
  void _appendDelexCondition(
    List<dynamic> args, {
    String? ifEq,
    String? ifNe,
    String? ifDigestEq,
    String? ifDigestNe,
  }) {
    final conditions = [
      if (ifEq != null) 'IFEQ',
      if (ifNe != null) 'IFNE',
      if (ifDigestEq != null) 'IFDEQ',
      if (ifDigestNe != null) 'IFDNE',
    ];
    if (conditions.length > 1) {
      throw ArgumentError('DELEX accepts only one conditional option');
    }
    if (ifEq != null) args.addAll(['IFEQ', ifEq]);
    if (ifNe != null) args.addAll(['IFNE', ifNe]);
    if (ifDigestEq != null) args.addAll(['IFDEQ', ifDigestEq]);
    if (ifDigestNe != null) args.addAll(['IFDNE', ifDigestNe]);
  }

  /// Returns the string value stored at [key], or `null` when the key is absent.
  Future<String?> get(String key) async {
    var res = await sendCommand(['GET', key]);
    return Decoders.toStringOrNull(res);
  }

  /// Returns the raw bytes stored at [key], or `null` when the key is absent.
  Future<Uint8List?> getBytes(String key) async {
    final res = await sendCommand(['GET', key]);
    return Decoders.toBytesOrNull(res);
  }

  /// Sets [key] to [value].
  ///
  /// Optional flags map to the standard Redis `SET` modifiers such as `EX`,
  /// `PX`, `NX`, and `XX`.
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

  /// Sets [key] only when it does not already exist.
  Future<bool> setNx(String key, String value) async {
    final res = await sendCommand(['SETNX', key, value]);
    return Decoders.toBool(res);
  }

  /// Sets [key] with a TTL of [seconds].
  Future<String> setEx(String key, int seconds, String value) async {
    final res = await sendCommand(['SETEX', key, seconds, value]);
    return Decoders.string(res);
  }

  /// Sets [key] and returns the previous value when supported by Redis.
  Future<String?> setGet(
    String key,
    String value, {
    int? ex,
    int? px,
    bool? nx,
    bool? xx,
  }) async {
    final args = <dynamic>['SET', key, value, 'GET'];
    if (ex != null) args.addAll(['EX', ex]);
    if (px != null) args.addAll(['PX', px]);
    if (nx == true) args.add('NX');
    if (xx == true) args.add('XX');

    final res = await sendCommand(args);
    return Decoders.toStringOrNull(res);
  }

  /// Returns the current value of [key] and deletes the key.
  Future<String?> getDel(String key) async {
    final res = await sendCommand(['GETDEL', key]);
    return Decoders.toStringOrNull(res);
  }

  /// Returns the raw bytes of [key] and deletes the key.
  Future<Uint8List?> getDelBytes(String key) async {
    final res = await sendCommand(['GETDEL', key]);
    return Decoders.toBytesOrNull(res);
  }

  /// Returns the value of [key] while optionally updating its expiry.
  Future<String?> getEx(
    String key, {
    int? ex,
    int? px,
    bool? nx,
    bool? xx,
  }) async {
    final args = <dynamic>['GETEX', key];
    if (ex != null) args.addAll(['EX', ex]);
    if (px != null) args.addAll(['PX', px]);
    if (nx == true) args.add('NX');
    if (xx == true) args.add('XX');

    final res = await sendCommand(args);
    return Decoders.toStringOrNull(res);
  }

  /// Returns the raw bytes of [key] while optionally updating its expiry.
  Future<Uint8List?> getExBytes(
    String key, {
    int? ex,
    int? px,
    bool? nx,
    bool? xx,
  }) async {
    final args = <dynamic>['GETEX', key];
    if (ex != null) args.addAll(['EX', ex]);
    if (px != null) args.addAll(['PX', px]);
    if (nx == true) args.add('NX');
    if (xx == true) args.add('XX');

    final res = await sendCommand(args);
    return Decoders.toBytesOrNull(res);
  }

  /// Replaces the value at [key] and returns the previous value.
  Future<String?> getSet(String key, String value) async {
    final res = await sendCommand(['GETSET', key, value]);
    return Decoders.toStringOrNull(res);
  }

  /// Replaces the value at [key] and returns the previous raw bytes.
  Future<Uint8List?> getSetBytes(String key, String value) async {
    final res = await sendCommand(['GETSET', key, value]);
    return Decoders.toBytesOrNull(res);
  }

  /// Overwrites the value at [key] starting at [offset].
  Future<int> setRange(String key, int offset, String value) async {
    final res = await sendCommand(['SETRANGE', key, offset, value]);
    return Decoders.toInt(res);
  }

  /// Returns the substring of [key] between [start] and [end].
  Future<String> getRange(String key, int start, int end) async {
    final res = await sendCommand(['GETRANGE', key, start, end]);
    return Decoders.string(res);
  }

  /// Returns the values for all [keys] in request order.
  Future<List<String?>> mGet(List<String> keys) async {
    final res = await sendCommand(['MGET', ...keys]);
    if (res is List) return res.map(Decoders.toStringOrNull).toList();
    return [];
  }

  /// Returns the raw values for all [keys] in request order.
  Future<List<Uint8List?>> mGetBytes(List<String> keys) async {
    final res = await sendCommand(['MGET', ...keys]);
    if (res is! List) return const [];
    return res.map(Decoders.toBytesOrNull).toList(growable: false);
  }

  /// Sets multiple string key/value pairs atomically.
  Future<String> mSet(Map<String, String> keyValues) async {
    final args = ['MSET'];
    keyValues.forEach((k, v) => args.addAll([k, v]));
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  /// Increments the integer value stored at [key] by one.
  Future<int> incr(String key) async {
    final res = await sendCommand(['INCR', key]);
    return Decoders.toInt(res);
  }

  /// Increments the integer value stored at [key] by [increment].
  Future<int> incrBy(String key, int increment) async {
    final res = await sendCommand(['INCRBY', key, increment]);
    return Decoders.toInt(res);
  }

  /// Increments the floating-point value stored at [key] by [increment].
  Future<double> incrByFloat(String key, double increment) async {
    var res = await sendCommand(['INCRBYFLOAT', key, increment]);
    return Decoders.toDouble(res);
  }

  /// Decrements the integer value stored at [key] by one.
  Future<int> decr(String key) async {
    final res = await sendCommand(['DECR', key]);
    return Decoders.toInt(res);
  }

  /// Decrements the integer value stored at [key] by [decrement].
  Future<int> decrBy(String key, int decrement) async {
    final res = await sendCommand(['DECRBY', key, decrement]);
    return Decoders.toInt(res);
  }

  /// Appends [value] to the string stored at [key].
  Future<int> append(String key, String value) async {
    final res = await sendCommand(['APPEND', key, value]);
    return Decoders.toInt(res);
  }

  /// Returns the length of the string stored at [key].
  Future<int> strlen(String key) async {
    final res = await sendCommand(['STRLEN', key]);
    return Decoders.toInt(res);
  }

  /// Sets [key] with a TTL measured in milliseconds.
  Future<String> pSetEx(String key, int milliseconds, String value) async {
    final res = await sendCommand(['PSETEX', key, milliseconds, value]);
    return Decoders.string(res);
  }

  /// Sets the bit at [offset] in [key] to [value].
  Future<int> setBit(String key, int offset, int value) async {
    final res = await sendCommand(['SETBIT', key, offset, value]);
    return Decoders.toInt(res);
  }

  /// Returns the bit value at [offset] in [key].
  Future<int> getBit(String key, int offset) async {
    final res = await sendCommand(['GETBIT', key, offset]);
    return Decoders.toInt(res);
  }

  /// Sets multiple key/value pairs when none of the keys already exist.
  Future<bool> mSetNx(Map<String, String> keyValues) async {
    final args = ['MSETNX'];
    keyValues.forEach((k, v) => args.addAll([k, v]));
    final res = await sendCommand(args);
    return Decoders.toBool(res);
  }

  /// Counts set bits in [key], optionally within the `[start, end]` range.
  Future<int> bitCount(String key, {int? start, int? end}) async {
    final args = <dynamic>['BITCOUNT', key];
    if (start != null && end != null) {
      args.addAll([start, end]);
    }
    final res = await sendCommand(args);
    return Decoders.toInt(res);
  }

  /// Returns the first bit position matching [bit] in [key].
  Future<int> bitPos(String key, int bit, {int? start, int? end}) async {
    final args = ['BITPOS', key, bit];
    if (start != null) args.add(start);
    if (end != null) args.add(end);
    final res = await sendCommand(args);
    return Decoders.toInt(res);
  }

  /// Executes a `BITFIELD` command against [key].
  Future<List<int?>> bitField(String key, List<dynamic> subcommands) async {
    final args = ['BITFIELD', key, ...subcommands];
    final res = await sendCommand(args);
    if (res is List) {
      return res.map((e) => e == null ? null : e as int).toList();
    }
    return [];
  }

  /// Executes a `BITFIELD` command using [builder] to define subcommands.
  Future<List<int?>> bitFieldWith(String key, BitFieldBuilder builder) {
    return bitField(key, builder.subcommands);
  }

  /// Executes a read-only `BITFIELD_RO` command against [key].
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

  /// Executes a read-only `BITFIELD_RO` command using [builder].
  Future<List<int?>> bitFieldReadonlyWith(String key, BitFieldBuilder builder) {
    return bitFieldReadonly(key, builder.subcommands);
  }

  /// Applies a bitwise [operation] across [srcKeys] and stores the result in [destKey].
  Future<int> bitOp(
    String operation,
    String destKey,
    List<String> srcKeys,
  ) async {
    final args = ['BITOP', operation, destKey, ...srcKeys];
    final res = await sendCommand(args);
    return Decoders.toInt(res);
  }

  /// Runs the Redis `LCS` command for [key1] and [key2].
  Future<String?> lcs(String key1, String key2, {bool? len, bool? idx}) async {
    final args = ['LCS', key1, key2];
    if (len == true) args.add('LEN');
    if (idx == true) args.add('IDX');
    final res = await sendCommand(args);
    return Decoders.toStringOrNull(res);
  }

  /// Legacy alias for `GETRANGE`.
  Future<String?> substr(String key, int start, int end) async {
    final res = await sendCommand(['SUBSTR', key, start, end]);
    return Decoders.toStringOrNull(res);
  }

  /// Returns the XXH3 digest for the string stored at [key].
  Future<String?> digest(String key) async {
    final res = await sendCommand(['DIGEST', key]);
    return Decoders.toStringOrNull(res);
  }

  /// Deletes [key], optionally applying a single conditional check first.
  Future<bool> delex(
    String key, {
    String? ifEq,
    String? ifNe,
    String? ifDigestEq,
    String? ifDigestNe,
  }) async {
    final args = <dynamic>['DELEX', key];
    _appendDelexCondition(
      args,
      ifEq: ifEq,
      ifNe: ifNe,
      ifDigestEq: ifDigestEq,
      ifDigestNe: ifDigestNe,
    );
    final res = await sendCommand(args);
    return Decoders.toBool(res);
  }

  /// Sets multiple string key/value pairs atomically with shared expiry options.
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
    final args = <dynamic>['MSETEX', keyValues.length];
    keyValues.forEach((key, value) => args.addAll([key, value]));
    if (ex != null) args.addAll(['EX', ex]);
    if (px != null) args.addAll(['PX', px]);
    if (exAt != null) args.addAll(['EXAT', exAt]);
    if (pxAt != null) args.addAll(['PXAT', pxAt]);
    if (keepTtl == true) args.add('KEEPTTL');
    if (nx == true) args.add('NX');
    if (xx == true) args.add('XX');

    final res = await sendCommand(args);
    return Decoders.toInt(res);
  }
}
