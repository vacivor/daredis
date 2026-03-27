part of '../../daredis.dart';

mixin RedisKeyCommands on RedisCommandExecutor {
  List<dynamic> _sortArgs(
    String command,
    String key, {
    String? byPattern,
    int? offset,
    int? count,
    List<String>? getPatterns,
    bool descending = false,
    bool alpha = false,
    String? storeDestination,
  }) {
    if ((offset == null) != (count == null)) {
      throw ArgumentError('SORT LIMIT requires both offset and count');
    }

    final args = <dynamic>[command, key];
    if (byPattern != null) args.addAll(['BY', byPattern]);
    if (offset != null && count != null) args.addAll(['LIMIT', offset, count]);
    if (getPatterns != null) {
      for (final pattern in getPatterns) {
        args.addAll(['GET', pattern]);
      }
    }
    args.add(descending ? 'DESC' : 'ASC');
    if (alpha) args.add('ALPHA');
    if (storeDestination != null) args.addAll(['STORE', storeDestination]);
    return args;
  }

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
    if (res is List) return res.map(Decoders.string).toList();
    return [];
  }

  /// Returns the serialized value stored at [key], or `null` when missing.
  Future<String?> dump(String key) async {
    final res = await sendCommand(['DUMP', key]);
    return Decoders.toStringOrNull(res);
  }

  /// Restores a value created by [dump] into [key].
  Future<String> restore(
    String key,
    int ttlMilliseconds,
    dynamic serializedValue, {
    bool replace = false,
    bool absTtl = false,
    int? idleTimeSeconds,
    int? frequency,
  }) async {
    final args = <dynamic>['RESTORE', key, ttlMilliseconds, serializedValue];
    if (replace) args.add('REPLACE');
    if (absTtl) args.add('ABSTTL');
    if (idleTimeSeconds != null) args.addAll(['IDLETIME', idleTimeSeconds]);
    if (frequency != null) args.addAll(['FREQ', frequency]);
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  /// Sorts the elements stored at [key] and returns the resulting values.
  Future<List<String?>> sort(
    String key, {
    String? byPattern,
    int? offset,
    int? count,
    List<String>? getPatterns,
    bool descending = false,
    bool alpha = false,
  }) async {
    final res = await sendCommand(
      _sortArgs(
        'SORT',
        key,
        byPattern: byPattern,
        offset: offset,
        count: count,
        getPatterns: getPatterns,
        descending: descending,
        alpha: alpha,
      ),
    );
    if (res is! List) return const [];
    return res.map(Decoders.toStringOrNull).toList(growable: false);
  }

  /// Sorts the elements stored at [key] and stores the result into [destination].
  Future<int> sortStore(
    String key,
    String destination, {
    String? byPattern,
    int? offset,
    int? count,
    List<String>? getPatterns,
    bool descending = false,
    bool alpha = false,
  }) async {
    final res = await sendCommand(
      _sortArgs(
        'SORT',
        key,
        byPattern: byPattern,
        offset: offset,
        count: count,
        getPatterns: getPatterns,
        descending: descending,
        alpha: alpha,
        storeDestination: destination,
      ),
    );
    return Decoders.toInt(res);
  }

  /// Read-only variant of [sort].
  Future<List<String?>> sortRo(
    String key, {
    String? byPattern,
    int? offset,
    int? count,
    List<String>? getPatterns,
    bool descending = false,
    bool alpha = false,
  }) async {
    final res = await sendCommand(
      _sortArgs(
        'SORT_RO',
        key,
        byPattern: byPattern,
        offset: offset,
        count: count,
        getPatterns: getPatterns,
        descending: descending,
        alpha: alpha,
      ),
    );
    if (res is! List) return const [];
    return res.map(Decoders.toStringOrNull).toList(growable: false);
  }

  /// Atomically migrates one key or a batch of [keys] to another Redis instance.
  Future<String> migrate(
    String host,
    int port, {
    String? key,
    List<String>? keys,
    required int destinationDb,
    required int timeoutMilliseconds,
    bool copy = false,
    bool replace = false,
    String? authPassword,
    String? authUsername,
  }) async {
    final hasSingleKey = key != null;
    final hasMultipleKeys = keys != null && keys.isNotEmpty;

    if (hasSingleKey == hasMultipleKeys) {
      throw ArgumentError('Provide exactly one of key or keys');
    }
    if (authUsername != null && authPassword == null) {
      throw ArgumentError('AUTH2 requires both username and password');
    }

    final args = <dynamic>[
      'MIGRATE',
      host,
      port,
      if (hasSingleKey) key else '',
      destinationDb,
      timeoutMilliseconds,
    ];
    if (copy) args.add('COPY');
    if (replace) args.add('REPLACE');
    if (authUsername != null) {
      args.addAll(['AUTH2', authUsername, authPassword!]);
    } else if (authPassword != null) {
      args.addAll(['AUTH', authPassword]);
    }
    if (hasMultipleKeys) {
      args.addAll(['KEYS', ...keys]);
    }

    final res = await sendCommand(args);
    return Decoders.string(res);
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
      final nextCursor = Decoders.toInt(res[0]);
      final items = (res[1] as List).map(Decoders.string).toList();
      return ScanResult(nextCursor, items);
    }
    return const ScanResult(0, []);
  }
}
