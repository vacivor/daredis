part of '../../daredis.dart';

mixin RedisKeyCommands on RedisCommandExecutor {
  /// Returns how many of [keys] currently exist.
  Future<int> exists(dynamic keys) async {
    final res = await sendCommand([
      'EXISTS',
      if (keys is List) ...keys else keys,
    ]);
    return Decoders.toInt(res);
  }

  /// Removes the existing TTL from [key].
  Future<int> persist(String key) async {
    final res = await sendCommand(['PERSIST', key]);
    return Decoders.toInt(res);
  }

  /// Returns the Redis type name for [key].
  Future<String> type(String key) async {
    final res = await sendCommand(['TYPE', key]);
    return Decoders.string(res);
  }

  /// Sets the TTL of [key] to [seconds].
  Future<int> expire(String key, int seconds) async {
    final res = await sendCommand(['EXPIRE', key, seconds]);
    return Decoders.toInt(res);
  }

  /// Sets the TTL of [key] to [milliseconds].
  Future<int> pExpire(String key, int milliseconds) async {
    final res = await sendCommand(['PEXPIRE', key, milliseconds]);
    return Decoders.toInt(res);
  }

  /// Sets the absolute expiry time of [key] using a Unix timestamp in seconds.
  Future<int> expireAt(String key, int timestamp) async {
    final res = await sendCommand(['EXPIREAT', key, timestamp]);
    return Decoders.toInt(res);
  }

  /// Sets the absolute expiry time of [key] using a Unix timestamp in milliseconds.
  Future<int> pExpireAt(String key, int timestampMs) async {
    final res = await sendCommand(['PEXPIREAT', key, timestampMs]);
    return Decoders.toInt(res);
  }

  /// Returns the absolute expiry timestamp of [key] in seconds.
  Future<int> expireTime(String key) async {
    final res = await sendCommand(['EXPIRETIME', key]);
    return Decoders.toInt(res);
  }

  /// Returns the absolute expiry timestamp of [key] in milliseconds.
  Future<int> pExpireTime(String key) async {
    final res = await sendCommand(['PEXPIRETIME', key]);
    return Decoders.toInt(res);
  }

  /// Returns the remaining TTL of [key] in seconds.
  Future<int> ttl(String key) async {
    final res = await sendCommand(['TTL', key]);
    return Decoders.toInt(res);
  }

  /// Returns the remaining TTL of [key] in milliseconds.
  Future<int> pttl(String key) async {
    final res = await sendCommand(['PTTL', key]);
    return Decoders.toInt(res);
  }

  /// Deletes one or more [keys].
  Future<int> del(dynamic keys) async {
    final res = await sendCommand(['DEL', if (keys is List) ...keys else keys]);
    return Decoders.toInt(res);
  }

  /// Unlinks one or more [keys] asynchronously on the Redis server.
  Future<int> unlink(dynamic keys) async {
    final res = await sendCommand([
      'UNLINK',
      if (keys is List) ...keys else keys,
    ]);
    return Decoders.toInt(res);
  }

  /// Touches one or more [keys] to update their idle time.
  Future<int> touch(dynamic keys) async {
    final res = await sendCommand([
      'TOUCH',
      if (keys is List) ...keys else keys,
    ]);
    return Decoders.toInt(res);
  }

  /// Renames [key] to [newKey].
  Future<String> rename(String key, String newKey) async {
    final res = await sendCommand(['RENAME', key, newKey]);
    return Decoders.string(res);
  }

  /// Renames [key] to [newKey] only when [newKey] does not yet exist.
  Future<int> renameNx(String key, String newKey) async {
    final res = await sendCommand(['RENAMENX', key, newKey]);
    return Decoders.toInt(res);
  }

  /// Moves [key] to Redis database [db].
  Future<int> move(String key, int db) async {
    final res = await sendCommand(['MOVE', key, db]);
    return Decoders.toInt(res);
  }

  /// Copies [source] to [destination].
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

  /// Returns all keys matching [pattern].
  Future<List<String>> keys(String pattern) async {
    final res = await sendCommand(['KEYS', pattern]);
    if (res is List) return res.map((e) => e.toString()).toList();
    return [];
  }

  /// Returns a random key from the current database, or `null` when empty.
  Future<String?> randomKey() async {
    final res = await sendCommand(['RANDOMKEY']);
    return Decoders.toStringOrNull(res);
  }

  /// Returns the internal Redis object encoding for [key].
  Future<String> objectEncoding(String key) async {
    final res = await sendCommand(['OBJECT', 'ENCODING', key]);
    return Decoders.string(res);
  }

  /// Returns the internal Redis reference count for [key].
  Future<int> objectRefCount(String key) async {
    final res = await sendCommand(['OBJECT', 'REFCOUNT', key]);
    return Decoders.toInt(res);
  }

  /// Returns the idle time of [key] in seconds.
  Future<int> objectIdleTime(String key) async {
    final res = await sendCommand(['OBJECT', 'IDLETIME', key]);
    return Decoders.toInt(res);
  }

  /// Returns the LFU frequency counter of [key].
  Future<int> objectFreq(String key) async {
    final res = await sendCommand(['OBJECT', 'FREQ', key]);
    return Decoders.toInt(res);
  }

  /// Returns the approximate memory usage of [key].
  Future<int?> memoryUsage(String key, {int? samples}) async {
    final args = <dynamic>['MEMORY', 'USAGE', key];
    if (samples != null) args.addAll(['SAMPLES', samples]);
    final res = await sendCommand(args);
    return Decoders.toIntOrNull(res);
  }

  /// Iterates the keyspace starting from [cursor].
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
