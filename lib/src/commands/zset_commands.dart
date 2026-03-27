part of '../../daredis.dart';

class ZSetScoredMember {
  final String member;
  final double score;

  ZSetScoredMember(this.member, this.score);
}

class ZSetPopResult {
  final String key;
  final List<ZSetScoredMember> entries;

  ZSetPopResult(this.key, this.entries);
}

mixin RedisSortedSetCommands on RedisCommandExecutor {
  Future<int> zAdd(
    String key,
    Map<String, double> scoreMembers, {
    bool? nx,
    bool? xx,
    bool? gt,
    bool? lt,
    bool? ch,
  }) async {
    final args = <dynamic>['ZADD', key];
    if (nx == true) args.add('NX');
    if (xx == true) args.add('XX');
    if (gt == true) args.add('GT');
    if (lt == true) args.add('LT');
    if (ch == true) args.add('CH');
    scoreMembers.forEach((member, score) => args.addAll([score, member]));
    final res = await sendCommand(args);
    return Decoders.toInt(res);
  }

  Future<int> zRem(String key, dynamic members) async {
    final res = await sendCommand([
      'ZREM',
      key,
      if (members is List) ...members else members,
    ]);
    return Decoders.toInt(res);
  }

  Future<double?> zScore(String key, String member) async {
    final res = await sendCommand(['ZSCORE', key, member]);
    return Decoders.toDoubleOrNull(res);
  }

  Future<int?> zRank(String key, String member) async {
    final res = await sendCommand(['ZRANK', key, member]);
    return Decoders.toIntOrNull(res);
  }

  Future<int?> zRevRank(String key, String member) async {
    final res = await sendCommand(['ZREVRANK', key, member]);
    return Decoders.toIntOrNull(res);
  }

  Future<int> zCard(String key) async {
    final res = await sendCommand(['ZCARD', key]);
    return Decoders.toInt(res);
  }

  Future<int> zCount(String key, dynamic min, dynamic max) async {
    final res = await sendCommand(['ZCOUNT', key, min, max]);
    return Decoders.toInt(res);
  }

  Future<List<String>> zRandMember(String key, [int? count]) async {
    final args = <dynamic>['ZRANDMEMBER', key];
    if (count != null) args.add(count);
    final res = await sendCommand(args);
    if (res is List) return res.map(Decoders.string).toList();
    if (res != null) return [Decoders.string(res)];
    return const [];
  }

  Future<List<String>> zRange(
    String key,
    int start,
    int stop, {
    bool withScores = false,
  }) async {
    var res = await sendCommand([
      'ZRANGE',
      key,
      start,
      stop,
      if (withScores) 'WITHSCORES',
    ]);

    if (res is List) {
      return res.map(Decoders.string).toList();
    }
    throw DaredisProtocolException(
      'Unexpected response type: ${res.runtimeType}',
    );
  }

  Future<List<String>> zRevRange(
    String key,
    int start,
    int stop, {
    bool withScores = false,
  }) async {
    final args = ['ZREVRANGE', key, start, stop];
    if (withScores) args.add('WITHSCORES');
    final res = await sendCommand(args);
    if (res is List) return res.map(Decoders.string).toList();
    return [];
  }

  Future<List<String>> zRangeByScore(
    String key,
    dynamic min,
    dynamic max, {
    bool withScores = false,
    int? offset,
    int? count,
  }) async {
    final args = ['ZRANGEBYSCORE', key, min, max];
    if (withScores) args.add('WITHSCORES');
    if (offset != null && count != null) args.addAll(['LIMIT', offset, count]);

    final res = await sendCommand(args);
    if (res is List) return res.map(Decoders.string).toList();
    return [];
  }

  Future<List<String>> zRevRangeByScore(
    String key,
    dynamic max,
    dynamic min, {
    bool withScores = false,
    int? offset,
    int? count,
  }) async {
    final args = <dynamic>['ZREVRANGEBYSCORE', key, max, min];
    if (withScores) args.add('WITHSCORES');
    if (offset != null && count != null) args.addAll(['LIMIT', offset, count]);

    final res = await sendCommand(args);
    if (res is List) return res.map(Decoders.string).toList();
    return const [];
  }

  Future<int> zRemRangeByScore(String key, dynamic min, dynamic max) async {
    final res = await sendCommand(['ZREMRANGEBYSCORE', key, min, max]);
    return Decoders.toInt(res);
  }

  Future<int> zRemRangeByRank(String key, int start, int stop) async {
    final res = await sendCommand(['ZREMRANGEBYRANK', key, start, stop]);
    return Decoders.toInt(res);
  }

  Future<int> zRemRangeByLex(String key, String min, String max) async {
    final res = await sendCommand(['ZREMRANGEBYLEX', key, min, max]);
    return Decoders.toInt(res);
  }

  Future<int> zLexCount(String key, String min, String max) async {
    final res = await sendCommand(['ZLEXCOUNT', key, min, max]);
    return Decoders.toInt(res);
  }

  Future<List<String>> zRangeByLex(
    String key,
    String min,
    String max, {
    int? offset,
    int? count,
  }) async {
    final args = <dynamic>['ZRANGEBYLEX', key, min, max];
    if (offset != null && count != null) args.addAll(['LIMIT', offset, count]);
    final res = await sendCommand(args);
    if (res is List) return res.map(Decoders.string).toList();
    return [];
  }

  Future<List<String>> zRevRangeByLex(
    String key,
    String max,
    String min, {
    int? offset,
    int? count,
  }) async {
    final args = <dynamic>['ZREVRANGEBYLEX', key, max, min];
    if (offset != null && count != null) args.addAll(['LIMIT', offset, count]);
    final res = await sendCommand(args);
    if (res is List) return res.map(Decoders.string).toList();
    return const [];
  }

  Future<List<String>> zInter(
    int numKeys,
    List<String> keys, {
    bool withScores = false,
  }) async {
    final args = ['ZINTER', numKeys, ...keys];
    if (withScores) args.add('WITHSCORES');
    final res = await sendCommand(args);
    if (res is List) return res.map(Decoders.string).toList();
    return [];
  }

  Future<int> zInterCard(int numKeys, List<String> keys, {int? limit}) async {
    final args = <dynamic>['ZINTERCARD', numKeys, ...keys];
    if (limit != null) args.addAll(['LIMIT', limit]);
    final res = await sendCommand(args);
    return Decoders.toInt(res);
  }

  Future<List<String>> zUnion(
    int numKeys,
    List<String> keys, {
    bool withScores = false,
  }) async {
    final args = ['ZUNION', numKeys, ...keys];
    if (withScores) args.add('WITHSCORES');
    final res = await sendCommand(args);
    if (res is List) return res.map(Decoders.string).toList();
    return [];
  }

  Future<List<String>> zDiff(int numKeys, List<String> keys) async {
    final res = await sendCommand(['ZDIFF', numKeys, ...keys]);
    if (res is List) return res.map(Decoders.string).toList();
    return [];
  }

  Future<int> zInterStore(
    String destination,
    int numKeys,
    List<String> keys,
  ) async {
    final res = await sendCommand([
      'ZINTERSTORE',
      destination,
      numKeys,
      ...keys,
    ]);
    return Decoders.toInt(res);
  }

  Future<int> zRangeStore(
    String destination,
    String source,
    int start,
    int stop,
  ) async {
    final res = await sendCommand([
      'ZRANGESTORE',
      destination,
      source,
      start,
      stop,
    ]);
    return Decoders.toInt(res);
  }

  Future<int> zUnionStore(
    String destination,
    int numKeys,
    List<String> keys,
  ) async {
    final res = await sendCommand([
      'ZUNIONSTORE',
      destination,
      numKeys,
      ...keys,
    ]);
    return Decoders.toInt(res);
  }

  Future<int> zDiffStore(
    String destination,
    int numKeys,
    List<String> keys,
  ) async {
    final res = await sendCommand([
      'ZDIFFSTORE',
      destination,
      numKeys,
      ...keys,
    ]);
    return Decoders.toInt(res);
  }

  Future<double> zIncrBy(String key, double increment, String member) async {
    final res = await sendCommand(['ZINCRBY', key, increment, member]);
    return Decoders.toDouble(res);
  }

  Future<List<double?>> zMScore(String key, List<String> members) async {
    final res = await sendCommand(['ZMSCORE', key, ...members]);
    if (res is! List) return const [];
    return res.map((value) => Decoders.toDoubleOrNull(value)).toList();
  }

  Future<List<String>> zPopMin(String key, [int? count]) async {
    final res = await sendCommand(['ZPOPMIN', key, ?count]);
    if (res is List) return res.map(Decoders.string).toList();
    return [];
  }

  Future<List<String>> zPopMax(String key, [int? count]) async {
    final res = await sendCommand(['ZPOPMAX', key, ?count]);
    if (res is List) return res.map(Decoders.string).toList();
    return [];
  }

  Future<ZSetPopResult?> zMPop(
    List<String> keys,
    String where, {
    int? count,
  }) async {
    final args = <dynamic>['ZMPOP', keys.length, ...keys, where];
    if (count != null) args.addAll(['COUNT', count]);
    final res = await sendCommand(args);
    return _parseZSetPopResult(res);
  }

  Future<ZSetPopResult?> bZMPop(
    int timeout,
    List<String> keys,
    String where, {
    int? count,
  }) async {
    final args = <dynamic>['BZMPOP', timeout, keys.length, ...keys, where];
    if (count != null) args.addAll(['COUNT', count]);
    final res = await sendCommand(args);
    return _parseZSetPopResult(res);
  }

  Future<ZSetPopResult?> bZPopMin(List<String> keys, int timeout) async {
    final res = await sendCommand(['BZPOPMIN', ...keys, timeout]);
    return _parseBlockingZSetPopResult(res);
  }

  Future<ZSetPopResult?> bZPopMax(List<String> keys, int timeout) async {
    final res = await sendCommand(['BZPOPMAX', ...keys, timeout]);
    return _parseBlockingZSetPopResult(res);
  }

  Future<ScanResult<MapEntry<String, double>>> zScan(
    String key,
    int cursor, {
    String? match,
    int? count,
  }) async {
    final args = ['ZSCAN', key, cursor];
    if (match != null) args.addAll(['MATCH', match]);
    if (count != null) args.addAll(['COUNT', count]);

    final res = await sendCommand(args);
    if (res is List && res.length == 2 && res[1] is List) {
      final nextCursor = Decoders.toInt(res[0]);
      final list = res[1] as List;
      final entries = <MapEntry<String, double>>[];
      for (var i = 0; i < list.length; i += 2) {
        final member = Decoders.string(list[i]);
        final score = Decoders.toDouble(list[i + 1]);
        entries.add(MapEntry(member, score));
      }
      return ScanResult(nextCursor, entries);
    }
    return const ScanResult(0, []);
  }

  ZSetPopResult? _parseZSetPopResult(dynamic res) {
    if (res == null) return null;
    if (res is List && res.length == 2 && res[1] is List) {
      return ZSetPopResult(
        Decoders.string(res[0]),
        _parseScoredMembers(res[1]),
      );
    }
    throw DaredisProtocolException('Unexpected sorted-set pop response: $res');
  }

  ZSetPopResult? _parseBlockingZSetPopResult(dynamic res) {
    if (res == null) return null;
    if (res is List && res.length == 3) {
      return ZSetPopResult(
        Decoders.string(res[0]),
        [ZSetScoredMember(Decoders.string(res[1]), Decoders.toDouble(res[2]))],
      );
    }
    throw DaredisProtocolException(
      'Unexpected blocking sorted-set pop response: $res',
    );
  }

  List<ZSetScoredMember> _parseScoredMembers(dynamic value) {
    if (value is! List) {
      throw DaredisProtocolException(
        'Unexpected sorted-set member list response: $value',
      );
    }
    return value.map((entry) {
      if (entry is List && entry.length == 2) {
        return ZSetScoredMember(
          Decoders.string(entry[0]),
          Decoders.toDouble(entry[1]),
        );
      }
      throw DaredisProtocolException(
        'Unexpected scored member response: $entry',
      );
    }).toList();
  }
}
