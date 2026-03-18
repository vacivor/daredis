part of '../../daredis.dart';

mixin RedisHashCommands on RedisCommandExecutor {
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
