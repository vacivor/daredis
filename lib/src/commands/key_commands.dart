part of '../../daredis.dart';

mixin RedisKeyCommands on RedisCommandExecutor {
  Future<int> exists(dynamic keys) async {
    final res = await sendCommand([
      'EXISTS',
      if (keys is List) ...keys else keys,
    ]);
    return Decoders.toInt(res);
  }

  Future<int> persist(String key) async {
    final res = await sendCommand(['PERSIST', key]);
    return Decoders.toInt(res);
  }

  Future<String> type(String key) async {
    final res = await sendCommand(['TYPE', key]);
    return Decoders.string(res);
  }

  Future<int> expire(String key, int seconds) async {
    final res = await sendCommand(['EXPIRE', key, seconds]);
    return Decoders.toInt(res);
  }

  Future<int> pExpire(String key, int milliseconds) async {
    final res = await sendCommand(['PEXPIRE', key, milliseconds]);
    return Decoders.toInt(res);
  }

  Future<int> expireAt(String key, int timestamp) async {
    final res = await sendCommand(['EXPIREAT', key, timestamp]);
    return Decoders.toInt(res);
  }

  Future<int> pExpireAt(String key, int timestampMs) async {
    final res = await sendCommand(['PEXPIREAT', key, timestampMs]);
    return Decoders.toInt(res);
  }

  Future<int> expireTime(String key) async {
    final res = await sendCommand(['EXPIRETIME', key]);
    return Decoders.toInt(res);
  }

  Future<int> pExpireTime(String key) async {
    final res = await sendCommand(['PEXPIRETIME', key]);
    return Decoders.toInt(res);
  }

  Future<int> ttl(String key) async {
    final res = await sendCommand(['TTL', key]);
    return Decoders.toInt(res);
  }

  Future<int> pttl(String key) async {
    final res = await sendCommand(['PTTL', key]);
    return Decoders.toInt(res);
  }

  Future<int> del(dynamic keys) async {
    final res = await sendCommand(['DEL', if (keys is List) ...keys else keys]);
    return Decoders.toInt(res);
  }

  Future<int> unlink(dynamic keys) async {
    final res = await sendCommand([
      'UNLINK',
      if (keys is List) ...keys else keys,
    ]);
    return Decoders.toInt(res);
  }

  Future<int> touch(dynamic keys) async {
    final res = await sendCommand([
      'TOUCH',
      if (keys is List) ...keys else keys,
    ]);
    return Decoders.toInt(res);
  }

  Future<String> rename(String key, String newKey) async {
    final res = await sendCommand(['RENAME', key, newKey]);
    return Decoders.string(res);
  }

  Future<int> renameNx(String key, String newKey) async {
    final res = await sendCommand(['RENAMENX', key, newKey]);
    return Decoders.toInt(res);
  }

  Future<int> move(String key, int db) async {
    final res = await sendCommand(['MOVE', key, db]);
    return Decoders.toInt(res);
  }

  Future<int> copy(
    String source,
    String destination, {
    int? db,
    bool replace = false,
  }) async {
    final args = <dynamic>['COPY', source, destination];
    if (db != null) args.addAll(['DB', db]);
    if (replace) args.add('REPLACE');
    final res = await sendCommand(args);
    return Decoders.toInt(res);
  }

  Future<List<String>> keys(String pattern) async {
    final res = await sendCommand(['KEYS', pattern]);
    if (res is List) return res.map((e) => e.toString()).toList();
    return [];
  }

  Future<String?> randomKey() async {
    final res = await sendCommand(['RANDOMKEY']);
    return Decoders.toStringOrNull(res);
  }

  Future<String> objectEncoding(String key) async {
    final res = await sendCommand(['OBJECT', 'ENCODING', key]);
    return Decoders.string(res);
  }

  Future<int> objectRefCount(String key) async {
    final res = await sendCommand(['OBJECT', 'REFCOUNT', key]);
    return Decoders.toInt(res);
  }

  Future<int> objectIdleTime(String key) async {
    final res = await sendCommand(['OBJECT', 'IDLETIME', key]);
    return Decoders.toInt(res);
  }

  Future<int> objectFreq(String key) async {
    final res = await sendCommand(['OBJECT', 'FREQ', key]);
    return Decoders.toInt(res);
  }

  Future<int?> memoryUsage(String key, {int? samples}) async {
    final args = <dynamic>['MEMORY', 'USAGE', key];
    if (samples != null) args.addAll(['SAMPLES', samples]);
    final res = await sendCommand(args);
    return Decoders.toIntOrNull(res);
  }

  Future<ScanResult<String>> scan(
    int cursor, {
    String? match,
    int? count,
  }) async {
    final args = ['SCAN', cursor];
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
