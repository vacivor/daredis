part of '../../daredis.dart';

class JsonMSetEntry {
  final String key;
  final String path;
  final String value;

  const JsonMSetEntry({
    required this.key,
    required this.path,
    required this.value,
  });
}

dynamic _jsonIntReply(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item == null ? null : Decoders.toInt(item))
        .toList(growable: false);
  }
  if (value == null) {
    return null;
  }
  return Decoders.toInt(value);
}

dynamic _jsonStringReply(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item?.toString())
        .toList(growable: false);
  }
  return Decoders.toStringOrNull(value);
}

dynamic _jsonNormalizedReply(dynamic value) {
  if (value is List) {
    return value.map(_jsonNormalizedReply).toList(growable: false);
  }
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key.toString(),
        _jsonNormalizedReply(nestedValue),
      ),
    );
  }
  return value;
}

mixin RedisJsonCommands on RedisCommandExecutor {
  Future<dynamic> jsonArrAppend(
    String key,
    List<String> values, {
    String path = r'$',
  }) async {
    if (values.isEmpty) {
      throw ArgumentError.value(values, 'values', 'must not be empty');
    }
    final res = await sendCommand(['JSON.ARRAPPEND', key, path, ...values]);
    return _jsonIntReply(res);
  }

  Future<dynamic> jsonArrIndex(
    String key,
    String value, {
    String path = r'$',
    int? start,
    int? stop,
  }) async {
    final args = <dynamic>['JSON.ARRINDEX', key, path, value];
    if (start != null) {
      args.add(start);
    }
    if (stop != null) {
      args.add(stop);
    }
    final res = await sendCommand(args);
    return _jsonIntReply(res);
  }

  Future<dynamic> jsonArrInsert(
    String key,
    String path,
    int index,
    List<String> values,
  ) async {
    if (values.isEmpty) {
      throw ArgumentError.value(values, 'values', 'must not be empty');
    }
    final res = await sendCommand([
      'JSON.ARRINSERT',
      key,
      path,
      index,
      ...values,
    ]);
    return _jsonIntReply(res);
  }

  Future<dynamic> jsonArrLen(String key, {String path = r'$'}) async {
    final res = await sendCommand(['JSON.ARRLEN', key, path]);
    return _jsonIntReply(res);
  }

  Future<dynamic> jsonArrPop(
    String key, {
    String path = r'$',
    int? index,
  }) async {
    final args = <dynamic>['JSON.ARRPOP', key, path];
    if (index != null) {
      args.add(index);
    }
    final res = await sendCommand(args);
    return _jsonStringReply(res);
  }

  Future<dynamic> jsonArrTrim(
    String key,
    String path,
    int start,
    int stop,
  ) async {
    final res = await sendCommand(['JSON.ARRTRIM', key, path, start, stop]);
    return _jsonIntReply(res);
  }

  Future<dynamic> jsonClear(String key, {String path = r'$'}) async {
    final res = await sendCommand(['JSON.CLEAR', key, path]);
    return _jsonIntReply(res);
  }

  Future<dynamic> jsonDebugMemory(String key, {String path = r'$'}) async {
    final res = await sendCommand(['JSON.DEBUG', 'MEMORY', key, path]);
    return _jsonIntReply(res);
  }

  Future<dynamic> jsonDel(String key, {String path = r'$'}) async {
    final res = await sendCommand(['JSON.DEL', key, path]);
    return _jsonIntReply(res);
  }

  Future<dynamic> jsonForget(String key, {String path = r'$'}) async {
    final res = await sendCommand(['JSON.FORGET', key, path]);
    return _jsonIntReply(res);
  }

  Future<String?> jsonGet(
    String key, {
    List<String>? paths,
    String? indent,
    String? newline,
    String? space,
  }) async {
    final args = <dynamic>['JSON.GET', key];
    if (indent != null) {
      args.addAll(['INDENT', indent]);
    }
    if (newline != null) {
      args.addAll(['NEWLINE', newline]);
    }
    if (space != null) {
      args.addAll(['SPACE', space]);
    }
    args.addAll(paths == null || paths.isEmpty ? [r'$'] : paths);
    final res = await sendCommand(args);
    return Decoders.toStringOrNull(res);
  }

  Future<String> jsonMerge(String key, String path, String value) async {
    final res = await sendCommand(['JSON.MERGE', key, path, value]);
    return Decoders.string(res);
  }

  Future<List<String?>> jsonMGet(List<String> keys, {String path = r'$'}) async {
    if (keys.isEmpty) {
      throw ArgumentError.value(keys, 'keys', 'must not be empty');
    }
    final res = await sendCommand(['JSON.MGET', ...keys, path]);
    if (res is List) {
      return res
          .map((item) => item?.toString())
          .toList(growable: false);
    }
    return const <String?>[];
  }

  Future<String> jsonMSet(List<JsonMSetEntry> entries) async {
    if (entries.isEmpty) {
      throw ArgumentError.value(entries, 'entries', 'must not be empty');
    }
    final args = <dynamic>['JSON.MSET'];
    for (final entry in entries) {
      args.addAll([entry.key, entry.path, entry.value]);
    }
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<String?> jsonNumIncrBy(String key, String path, num value) async {
    final res = await sendCommand(['JSON.NUMINCRBY', key, path, value]);
    return Decoders.toStringOrNull(res);
  }

  Future<String?> jsonNumMultBy(String key, String path, num value) async {
    final res = await sendCommand(['JSON.NUMMULTBY', key, path, value]);
    return Decoders.toStringOrNull(res);
  }

  Future<dynamic> jsonObjKeys(String key, {String path = r'$'}) async {
    final res = await sendCommand(['JSON.OBJKEYS', key, path]);
    return _jsonNormalizedReply(res);
  }

  Future<dynamic> jsonObjLen(String key, {String path = r'$'}) async {
    final res = await sendCommand(['JSON.OBJLEN', key, path]);
    return _jsonIntReply(res);
  }

  Future<dynamic> jsonResp(String key, {String path = r'$'}) async {
    final res = await sendCommand(['JSON.RESP', key, path]);
    return _jsonNormalizedReply(res);
  }

  Future<String?> jsonSet(
    String key,
    String path,
    String value, {
    bool nx = false,
    bool xx = false,
  }) async {
    if (nx && xx) {
      throw ArgumentError('JSON.SET cannot combine NX and XX');
    }
    final args = <dynamic>['JSON.SET', key, path, value];
    if (nx) {
      args.add('NX');
    }
    if (xx) {
      args.add('XX');
    }
    final res = await sendCommand(args);
    return Decoders.toStringOrNull(res);
  }

  Future<dynamic> jsonStrAppend(
    String key,
    String value, {
    String path = r'$',
  }) async {
    final res = await sendCommand(['JSON.STRAPPEND', key, path, value]);
    return _jsonIntReply(res);
  }

  Future<dynamic> jsonStrLen(String key, {String path = r'$'}) async {
    final res = await sendCommand(['JSON.STRLEN', key, path]);
    return _jsonIntReply(res);
  }

  Future<dynamic> jsonToggle(String key, {String path = r'$'}) async {
    final res = await sendCommand(['JSON.TOGGLE', key, path]);
    return _jsonIntReply(res);
  }

  Future<dynamic> jsonType(String key, {String path = r'$'}) async {
    final res = await sendCommand(['JSON.TYPE', key, path]);
    return _jsonStringReply(res);
  }
}
