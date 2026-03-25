part of '../../daredis.dart';

enum HashFieldExpireCondition { nx, xx, gt, lt }

mixin RedisHashCommands on RedisCommandExecutor {
  void _appendHashFields(List<dynamic> args, List<String> fields) {
    args.addAll(['FIELDS', fields.length, ...fields]);
  }

  void _appendHashExpireCondition(
    List<dynamic> args,
    HashFieldExpireCondition? condition,
  ) {
    switch (condition) {
      case HashFieldExpireCondition.nx:
        args.add('NX');
      case HashFieldExpireCondition.xx:
        args.add('XX');
      case HashFieldExpireCondition.gt:
        args.add('GT');
      case HashFieldExpireCondition.lt:
        args.add('LT');
      case null:
        break;
    }
  }

  void _appendHashGetExModifier(
    List<dynamic> args, {
    int? ex,
    int? px,
    int? exAt,
    int? pxAt,
    bool persist = false,
  }) {
    final modifiers = [
      if (ex != null) 'EX',
      if (px != null) 'PX',
      if (exAt != null) 'EXAT',
      if (pxAt != null) 'PXAT',
      if (persist) 'PERSIST',
    ];
    if (modifiers.length > 1) {
      throw ArgumentError('Only one HGETEX expiration modifier may be set');
    }
    if (ex != null) args.addAll(['EX', ex]);
    if (px != null) args.addAll(['PX', px]);
    if (exAt != null) args.addAll(['EXAT', exAt]);
    if (pxAt != null) args.addAll(['PXAT', pxAt]);
    if (persist) args.add('PERSIST');
  }

  void _appendHashSetExModifier(
    List<dynamic> args, {
    bool fnx = false,
    bool fxx = false,
    int? ex,
    int? px,
    int? exAt,
    int? pxAt,
    bool keepTtl = false,
  }) {
    if (fnx && fxx) {
      throw ArgumentError('HSETEX accepts only one of FNX or FXX');
    }
    final ttlModifiers = [
      if (ex != null) 'EX',
      if (px != null) 'PX',
      if (exAt != null) 'EXAT',
      if (pxAt != null) 'PXAT',
      if (keepTtl) 'KEEPTTL',
    ];
    if (ttlModifiers.length > 1) {
      throw ArgumentError(
        'Only one HSETEX TTL modifier may be set',
      );
    }
    if (fnx) args.add('FNX');
    if (fxx) args.add('FXX');
    if (ex != null) args.addAll(['EX', ex]);
    if (px != null) args.addAll(['PX', px]);
    if (exAt != null) args.addAll(['EXAT', exAt]);
    if (pxAt != null) args.addAll(['PXAT', pxAt]);
    if (keepTtl) args.add('KEEPTTL');
  }

  List<int> _decodeIntList(dynamic res) {
    if (res is! List) return const [];
    return res.map(Decoders.toInt).toList(growable: false);
  }

  List<String?> _decodeNullableStringList(dynamic res) {
    if (res is! List) return const [];
    return res.map(Decoders.toStringOrNull).toList(growable: false);
  }

  /// Sets the hash field [field] in [key] to [value].
  Future<int> hSet(String key, String field, String value) async {
    final res = await sendCommand(['HSET', key, field, value]);
    return Decoders.toInt(res);
  }

  /// Returns the hash field [field] from [key].
  Future<String?> hGet(String key, String field) async {
    final res = await sendCommand(['HGET', key, field]);
    return Decoders.toStringOrNull(res);
  }

  /// Sets multiple [fieldValues] on the hash stored at [key].
  Future<String> hmSet(String key, Map<String, dynamic> fieldValues) async {
    final args = ['HMSET', key];
    fieldValues.forEach((k, v) => args.addAll([k, v]));
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  /// Returns the values of [fields] from the hash stored at [key].
  Future<List<String?>> hmGet(String key, List<String> fields) async {
    final res = await sendCommand(['HMGET', key, ...fields]);
    if (res is List) return res.map((e) => e?.toString()).toList();
    return List.filled(fields.length, null);
  }

  /// Returns the entire hash stored at [key].
  Future<Map<String, String>> hGetAll(String key) async {
    final res = await sendCommand(['HGETALL', key]);
    final map = <String, String>{};
    if (res is Map) {
      res.forEach((k, v) => map[k.toString()] = v.toString());
      return map;
    }
    if (res is List) {
      for (var i = 0; i < res.length; i += 2) {
        map[res[i].toString()] = res[i + 1].toString();
      }
    }
    return map;
  }

  /// Deletes [fields] from the hash stored at [key].
  Future<int> hDel(String key, List<String> fields) async {
    final res = await sendCommand(['HDEL', key, ...fields]);
    return Decoders.toInt(res);
  }

  /// Returns whether [field] exists in the hash stored at [key].
  Future<bool> hExists(String key, String field) async {
    final res = await sendCommand(['HEXISTS', key, field]);
    return Decoders.toBool(res);
  }

  /// Sets an expiration time in seconds for one or more hash [fields].
  Future<List<int>> hExpire(
    String key,
    int seconds,
    List<String> fields, {
    HashFieldExpireCondition? condition,
  }) async {
    final args = <dynamic>['HEXPIRE', key, seconds];
    _appendHashExpireCondition(args, condition);
    _appendHashFields(args, fields);
    final res = await sendCommand(args);
    return _decodeIntList(res);
  }

  /// Sets an expiration time in milliseconds for one or more hash [fields].
  Future<List<int>> hPExpire(
    String key,
    int milliseconds,
    List<String> fields, {
    HashFieldExpireCondition? condition,
  }) async {
    final args = <dynamic>['HPEXPIRE', key, milliseconds];
    _appendHashExpireCondition(args, condition);
    _appendHashFields(args, fields);
    final res = await sendCommand(args);
    return _decodeIntList(res);
  }

  /// Sets an absolute expiration time in seconds for one or more hash [fields].
  Future<List<int>> hExpireAt(
    String key,
    int unixTimeSeconds,
    List<String> fields, {
    HashFieldExpireCondition? condition,
  }) async {
    final args = <dynamic>['HEXPIREAT', key, unixTimeSeconds];
    _appendHashExpireCondition(args, condition);
    _appendHashFields(args, fields);
    final res = await sendCommand(args);
    return _decodeIntList(res);
  }

  /// Sets an absolute expiration time in milliseconds for one or more hash [fields].
  Future<List<int>> hPExpireAt(
    String key,
    int unixTimeMilliseconds,
    List<String> fields, {
    HashFieldExpireCondition? condition,
  }) async {
    final args = <dynamic>['HPEXPIREAT', key, unixTimeMilliseconds];
    _appendHashExpireCondition(args, condition);
    _appendHashFields(args, fields);
    final res = await sendCommand(args);
    return _decodeIntList(res);
  }

  /// Returns the absolute expiration timestamp in seconds for [fields].
  Future<List<int>> hExpireTime(String key, List<String> fields) async {
    final args = <dynamic>['HEXPIRETIME', key];
    _appendHashFields(args, fields);
    final res = await sendCommand(args);
    return _decodeIntList(res);
  }

  /// Returns the absolute expiration timestamp in milliseconds for [fields].
  Future<List<int>> hPExpireTime(String key, List<String> fields) async {
    final args = <dynamic>['HPEXPIRETIME', key];
    _appendHashFields(args, fields);
    final res = await sendCommand(args);
    return _decodeIntList(res);
  }

  /// Returns the remaining TTL in seconds for [fields].
  Future<List<int>> hTtl(String key, List<String> fields) async {
    final args = <dynamic>['HTTL', key];
    _appendHashFields(args, fields);
    final res = await sendCommand(args);
    return _decodeIntList(res);
  }

  /// Returns the remaining TTL in milliseconds for [fields].
  Future<List<int>> hPTtl(String key, List<String> fields) async {
    final args = <dynamic>['HPTTL', key];
    _appendHashFields(args, fields);
    final res = await sendCommand(args);
    return _decodeIntList(res);
  }

  /// Removes existing expiration metadata from [fields].
  Future<List<int>> hPersist(String key, List<String> fields) async {
    final args = <dynamic>['HPERSIST', key];
    _appendHashFields(args, fields);
    final res = await sendCommand(args);
    return _decodeIntList(res);
  }

  /// Returns and deletes the values of [fields].
  Future<List<String?>> hGetDel(String key, List<String> fields) async {
    final args = <dynamic>['HGETDEL', key];
    _appendHashFields(args, fields);
    final res = await sendCommand(args);
    return _decodeNullableStringList(res);
  }

  /// Returns the values of [fields] and optionally updates their expiration.
  Future<List<String?>> hGetEx(
    String key,
    List<String> fields, {
    int? ex,
    int? px,
    int? exAt,
    int? pxAt,
    bool persist = false,
  }) async {
    final args = <dynamic>['HGETEX', key];
    _appendHashGetExModifier(
      args,
      ex: ex,
      px: px,
      exAt: exAt,
      pxAt: pxAt,
      persist: persist,
    );
    _appendHashFields(args, fields);
    final res = await sendCommand(args);
    return _decodeNullableStringList(res);
  }

  /// Returns one random field from the hash at [key].
  Future<String?> hRandField(String key) async {
    final res = await sendCommand(['HRANDFIELD', key]);
    return Decoders.toStringOrNull(res);
  }

  /// Returns random fields from the hash at [key].
  Future<List<String>> hRandFields(String key, int count) async {
    final res = await sendCommand(['HRANDFIELD', key, count]);
    if (res is List) return res.map((value) => value.toString()).toList();
    if (res != null) return [res.toString()];
    return const [];
  }

  /// Returns random field/value pairs from the hash at [key].
  Future<Map<String, String?>> hRandFieldsWithValues(
    String key,
    int count,
  ) async {
    final res = await sendCommand(['HRANDFIELD', key, count, 'WITHVALUES']);
    final map = <String, String?>{};
    if (res is List) {
      for (var i = 0; i < res.length; i += 2) {
        map[res[i].toString()] = Decoders.toStringOrNull(res[i + 1]);
      }
    }
    return map;
  }

  /// Returns all field names from the hash stored at [key].
  Future<List<String>> hKeys(String key) async {
    final res = await sendCommand(['HKEYS', key]);
    if (res is List) return res.map((e) => e.toString()).toList();
    return [];
  }

  /// Returns all field values from the hash stored at [key].
  Future<List<String>> hVals(String key) async {
    final res = await sendCommand(['HVALS', key]);
    if (res is List) return res.map((e) => e.toString()).toList();
    return [];
  }

  /// Returns the number of fields in the hash stored at [key].
  Future<int> hLen(String key) async {
    final res = await sendCommand(['HLEN', key]);
    return Decoders.toInt(res);
  }

  /// Increments hash field [field] in [key] by [increment].
  Future<int> hIncrBy(String key, String field, int increment) async {
    final res = await sendCommand(['HINCRBY', key, field, increment]);
    return Decoders.toInt(res);
  }

  /// Increments hash field [field] in [key] by a floating-point [increment].
  Future<double> hIncrByFloat(
    String key,
    String field,
    double increment,
  ) async {
    final res = await sendCommand(['HINCRBYFLOAT', key, field, increment]);
    return Decoders.toDouble(res);
  }

  /// Sets hash field [field] only when it does not already exist.
  Future<int> hSetNx(String key, String field, String value) async {
    final res = await sendCommand(['HSETNX', key, field, value]);
    return Decoders.toInt(res);
  }

  /// Sets one or more fields and optionally updates their expiration metadata.
  Future<bool> hSetEx(
    String key,
    Map<String, dynamic> fieldValues, {
    bool fnx = false,
    bool fxx = false,
    int? ex,
    int? px,
    int? exAt,
    int? pxAt,
    bool keepTtl = false,
  }) async {
    final args = <dynamic>['HSETEX', key];
    _appendHashSetExModifier(
      args,
      fnx: fnx,
      fxx: fxx,
      ex: ex,
      px: px,
      exAt: exAt,
      pxAt: pxAt,
      keepTtl: keepTtl,
    );
    args.addAll(['FIELDS', fieldValues.length]);
    fieldValues.forEach((field, value) => args.addAll([field, value]));
    final res = await sendCommand(args);
    return Decoders.toBool(res);
  }

  /// Returns the string length of the value stored at [field].
  Future<int> hStrLen(String key, String field) async {
    final res = await sendCommand(['HSTRLEN', key, field]);
    return Decoders.toInt(res);
  }

  /// Iterates hash entries stored at [key] starting from [cursor].
  Future<ScanResult<MapEntry<String, String>>> hScan(
    String key,
    int cursor, {
    String? match,
    int? count,
  }) async {
    final args = ['HSCAN', key, cursor];
    if (match != null) args.addAll(['MATCH', match]);
    if (count != null) args.addAll(['COUNT', count]);

    final res = await sendCommand(args);
    if (res is List && res.length == 2 && res[1] is List) {
      final nextCursor = int.tryParse(res[0].toString()) ?? 0;
      final list = res[1] as List;
      final entries = <MapEntry<String, String>>[];
      for (var i = 0; i < list.length; i += 2) {
        entries.add(MapEntry(list[i].toString(), list[i + 1].toString()));
      }
      return ScanResult(nextCursor, entries);
    }
    return const ScanResult(0, []);
  }
}
