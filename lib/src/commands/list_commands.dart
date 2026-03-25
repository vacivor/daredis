part of '../../daredis.dart';

class ListPopResult {
  final String key;
  final List<String> values;

  ListPopResult(this.key, this.values);
}

mixin RedisListCommands on RedisCommandExecutor {
  /// Pushes one or more [values] onto the head of the list at [key].
  Future<int> lPush(String key, dynamic values) async {
    final res = await sendCommand([
      'LPUSH',
      key,
      if (values is List) ...values else values,
    ]);
    return Decoders.toInt(res);
  }

  /// Pushes one or more [values] onto the head of the list at [key] only when it exists.
  Future<int> lPushX(String key, dynamic values) async {
    final res = await sendCommand([
      'LPUSHX',
      key,
      if (values is List) ...values else values,
    ]);
    return Decoders.toInt(res);
  }

  /// Pushes one or more [values] onto the tail of the list at [key].
  Future<int> rPush(String key, dynamic values) async {
    final res = await sendCommand([
      'RPUSH',
      key,
      if (values is List) ...values else values,
    ]);
    return Decoders.toInt(res);
  }

  /// Pushes one or more [values] onto the tail of the list at [key] only when it exists.
  Future<int> rPushX(String key, dynamic values) async {
    final res = await sendCommand([
      'RPUSHX',
      key,
      if (values is List) ...values else values,
    ]);
    return Decoders.toInt(res);
  }

  /// Pops and returns the first element of the list at [key].
  Future<String?> lPop(String key) async {
    final res = await sendCommand(['LPOP', key]);
    return Decoders.toStringOrNull(res);
  }

  /// Pops up to [count] elements from the head of the list at [key].
  Future<List<String>> lPopCount(String key, int count) async {
    final res = await sendCommand(['LPOP', key, count]);
    if (res is List) return res.map((e) => e.toString()).toList();
    if (res != null) return [res.toString()];
    return [];
  }

  /// Pops and returns the last element of the list at [key].
  Future<String?> rPop(String key) async {
    final res = await sendCommand(['RPOP', key]);
    return Decoders.toStringOrNull(res);
  }

  /// Pops up to [count] elements from the tail of the list at [key].
  Future<List<String>> rPopCount(String key, int count) async {
    final res = await sendCommand(['RPOP', key, count]);
    if (res is List) return res.map((e) => e.toString()).toList();
    if (res != null) return [res.toString()];
    return [];
  }

  /// Returns the elements of the list at [key] between [start] and [stop].
  Future<List<String>> lRange(String key, int start, int stop) async {
    final res = await sendCommand(['LRANGE', key, start, stop]);
    if (res is List) return res.map((e) => e.toString()).toList();
    return [];
  }

  /// Returns the length of the list at [key].
  Future<int> lLen(String key) async {
    final res = await sendCommand(['LLEN', key]);
    return Decoders.toInt(res);
  }

  /// Returns the list element at [index].
  Future<String?> lIndex(String key, int index) async {
    final res = await sendCommand(['LINDEX', key, index]);
    return Decoders.toStringOrNull(res);
  }

  /// Returns matching positions of [element] in the list at [key].
  Future<List<int>> lPos(
    String key,
    String element, {
    int? rank,
    int? count,
    int? maxLen,
  }) async {
    final args = <dynamic>['LPOS', key, element];
    if (rank != null) args.addAll(['RANK', rank]);
    if (count != null) args.addAll(['COUNT', count]);
    if (maxLen != null) args.addAll(['MAXLEN', maxLen]);

    final res = await sendCommand(args);
    if (res is List) {
      return res.map((value) => Decoders.toInt(value)).toList();
    }
    if (res != null) {
      return [Decoders.toInt(res)];
    }
    return const [];
  }

  /// Replaces the list element at [index] with [value].
  Future<String> lSet(String key, int index, String value) async {
    final res = await sendCommand(['LSET', key, index, value]);
    return Decoders.string(res);
  }

  /// Removes occurrences of [value] from the list at [key].
  Future<int> lRem(String key, int count, String value) async {
    final res = await sendCommand(['LREM', key, count, value]);
    return Decoders.toInt(res);
  }

  /// Trims the list at [key] to the `[start, stop]` range.
  Future<String> lTrim(String key, int start, int stop) async {
    final res = await sendCommand(['LTRIM', key, start, stop]);
    return Decoders.string(res);
  }

  /// Inserts [value] before [pivot] in the list at [key].
  Future<int> lInsertBefore(String key, String pivot, String value) async {
    final res = await sendCommand(['LINSERT', key, 'BEFORE', pivot, value]);
    return Decoders.toInt(res);
  }

  /// Inserts [value] after [pivot] in the list at [key].
  Future<int> lInsertAfter(String key, String pivot, String value) async {
    final res = await sendCommand(['LINSERT', key, 'AFTER', pivot, value]);
    return Decoders.toInt(res);
  }

  /// Blocks until an element can be popped from the head of one of [keys].
  Future<Map<String, String>?> bLPop(List<String> keys, int timeout) async {
    final res = await sendCommand(['BLPOP', ...keys, timeout]);
    if (res is List && res.length == 2) {
      return {res[0].toString(): res[1].toString()};
    }
    return null;
  }

  /// Blocks until an element can be popped from the tail of one of [keys].
  Future<Map<String, String>?> bRPop(List<String> keys, int timeout) async {
    final res = await sendCommand(['BRPOP', ...keys, timeout]);
    if (res is List && res.length == 2) {
      return {res[0].toString(): res[1].toString()};
    }
    return null;
  }

  /// Pops from [source] and pushes onto [destination].
  Future<String?> rPopLPush(String source, String destination) async {
    final res = await sendCommand(['RPOPLPUSH', source, destination]);
    return Decoders.toStringOrNull(res);
  }

  /// Blocking variant of [rPopLPush].
  Future<String?> bRPopLPush(
    String source,
    String destination,
    int timeout,
  ) async {
    final res = await sendCommand([
      'BRPOPLPUSH',
      source,
      destination,
      timeout,
    ]);
    return Decoders.toStringOrNull(res);
  }

  /// Moves one element from [source] to [destination].
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

  /// Blocking variant of [lMove].
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

  /// Pops one or more elements from the first non-empty list in [keys].
  Future<ListPopResult?> lMPop(
    List<String> keys,
    String where, {
    int? count,
  }) async {
    final args = <dynamic>['LMPOP', keys.length, ...keys, where];
    if (count != null) args.addAll(['COUNT', count]);
    final res = await sendCommand(args);
    return _parseListPopResult(res);
  }

  /// Blocking variant of [lMPop].
  Future<ListPopResult?> bLMPop(
    int timeout,
    List<String> keys,
    String where, {
    int? count,
  }) async {
    final args = <dynamic>['BLMPOP', timeout, keys.length, ...keys, where];
    if (count != null) args.addAll(['COUNT', count]);
    final res = await sendCommand(args);
    return _parseListPopResult(res);
  }

  ListPopResult? _parseListPopResult(dynamic res) {
    if (res == null) return null;
    if (res is List && res.length == 2 && res[1] is List) {
      return ListPopResult(
        res[0].toString(),
        (res[1] as List).map((value) => value.toString()).toList(),
      );
    }
    throw DaredisProtocolException('Unexpected list pop response: $res');
  }
}
