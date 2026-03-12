part of '../../daredis.dart';

extension RedisSetCommands on RedisCommandExecutor {
  Future<int> sAdd(String key, dynamic members) async {
    final res = await sendCommand([
      'SADD',
      key,
      if (members is List) ...members else members,
    ]);
    return Decoders.toInt(res);
  }

  Future<int> sRem(String key, dynamic members) async {
    final res = await sendCommand([
      'SREM',
      key,
      if (members is List) ...members else members,
    ]);
    return Decoders.toInt(res);
  }

  Future<List<String>> sMembers(String key) async {
    final res = await sendCommand(['SMEMBERS', key]);
    if (res is List) return res.map((e) => e.toString()).toList();
    return [];
  }

  Future<bool> sIsMember(String key, String member) async {
    final res = await sendCommand(['SISMEMBER', key, member]);
    return Decoders.toBool(res);
  }

  Future<int> sCard(String key) async {
    final res = await sendCommand(['SCARD', key]);
    return Decoders.toInt(res);
  }

  Future<List<String>> sPop(String key, [int? count]) async {
    final res = await sendCommand(['SPOP', key, ?count]);
    if (res is List) return res.map((e) => e.toString()).toList();
    if (res != null) return [res.toString()];
    return [];
  }

  Future<List<String>> sRandMember(String key, [int? count]) async {
    final args = <dynamic>['SRANDMEMBER', key];
    if (count != null) args.add(count);
    final res = await sendCommand(args);
    if (res is List) return res.map((e) => e.toString()).toList();
    if (res != null) return [res.toString()];
    return [];
  }

  Future<bool> sMove(String source, String destination, String member) async {
    final res = await sendCommand(['SMOVE', source, destination, member]);
    return Decoders.toBool(res);
  }

  Future<List<String>> sDiff(List<String> keys) async {
    final res = await sendCommand(['SDIFF', ...keys]);
    if (res is List) return res.map((e) => e.toString()).toList();
    return [];
  }

  Future<List<String>> sInter(List<String> keys) async {
    final res = await sendCommand(['SINTER', ...keys]);
    if (res is List) return res.map((e) => e.toString()).toList();
    return [];
  }

  Future<List<String>> sUnion(List<String> keys) async {
    final res = await sendCommand(['SUNION', ...keys]);
    if (res is List) return res.map((e) => e.toString()).toList();
    return [];
  }

  Future<int> sDiffStore(String destination, List<String> keys) async {
    final res = await sendCommand(['SDIFFSTORE', destination, ...keys]);
    return Decoders.toInt(res);
  }

  Future<int> sInterStore(String destination, List<String> keys) async {
    final res = await sendCommand(['SINTERSTORE', destination, ...keys]);
    return Decoders.toInt(res);
  }

  Future<int> sUnionStore(String destination, List<String> keys) async {
    final res = await sendCommand(['SUNIONSTORE', destination, ...keys]);
    return Decoders.toInt(res);
  }

  Future<int> sInterCard(List<String> keys, {int? limit}) async {
    final args = ['SINTERCARD', keys.length, ...keys];
    if (limit != null) args.addAll(['LIMIT', limit]);
    final res = await sendCommand(args);
    return Decoders.toInt(res);
  }

  Future<ScanResult<String>> sScan(
    String key,
    int cursor, {
    String? match,
    int? count,
  }) async {
    final args = ['SSCAN', key, cursor];
    if (match != null) args.addAll(['MATCH', match]);
    if (count != null) args.addAll(['COUNT', count]);

    final res = await sendCommand(args);
    if (res is List && res.length == 2 && res[1] is List) {
      final nextCursor = int.tryParse(res[0].toString()) ?? 0;
      final items = (res[1] as List).map((e) => e.toString()).toList();
      return ScanResult(nextCursor, items);
    }
    return const ScanResult(0, []);
  }
}
