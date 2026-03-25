import 'package:daredis/src/cluster_slots.dart';
import 'package:daredis/src/exceptions.dart';

/// Strategy used to locate keys inside a Redis command.
enum KeySpecType {
  none,
  singleKeyAtIndex,
  twoKeysAtIndex,
  keysFromIndex,
  keysUntilLast,
  keyValuePairsFrom,
  numKeysAtIndex,
  numKeyValuePairsAtIndex,
  numKeysWithDest,
  streamsKeyword,
  sortStoreKeyword,
  migrateKeys,
  memorySubcommand,
  objectSubcommand,
}

/// Key extraction metadata for a single Redis command.
class CommandSpec {
  /// Extraction strategy.
  final KeySpecType type;

  /// Primary positional index used by the extraction strategy.
  final int? index;

  /// Secondary positional index used by some strategies.
  final int? secondIndex;

  const CommandSpec._(this.type, [this.index, this.secondIndex]);

  const CommandSpec.none() : this._(KeySpecType.none);

  const CommandSpec.singleKeyAt(int index)
    : this._(KeySpecType.singleKeyAtIndex, index);

  const CommandSpec.twoKeysAt(int index)
    : this._(KeySpecType.twoKeysAtIndex, index);

  const CommandSpec.keysFrom(int index)
    : this._(KeySpecType.keysFromIndex, index);

  const CommandSpec.keysUntilLast(int index)
    : this._(KeySpecType.keysUntilLast, index);

  const CommandSpec.keyValuePairsFrom(int index)
    : this._(KeySpecType.keyValuePairsFrom, index);

  const CommandSpec.numKeysAt(int index)
    : this._(KeySpecType.numKeysAtIndex, index);

  const CommandSpec.numKeyValuePairsAt(int index)
    : this._(KeySpecType.numKeyValuePairsAtIndex, index);

  const CommandSpec.numKeysWithDest(int destIndex, int numKeysIndex)
    : this._(KeySpecType.numKeysWithDest, destIndex, numKeysIndex);

  const CommandSpec.streamsKeyword() : this._(KeySpecType.streamsKeyword);

  const CommandSpec.sortStoreKeyword()
    : this._(KeySpecType.sortStoreKeyword);

  const CommandSpec.migrateKeys() : this._(KeySpecType.migrateKeys);

  const CommandSpec.memorySubcommand() : this._(KeySpecType.memorySubcommand);

  const CommandSpec.objectSubcommand() : this._(KeySpecType.objectSubcommand);
}

/// Static key-spec registry used by the cluster router.
class ClusterCommandSpec {
  /// Marker used for commands that do not carry keys.
  static const CommandSpec noKey = CommandSpec.none();

  /// Command name to key extraction specification.
  static const Map<String, CommandSpec> specs = {
    'PING': noKey,
    'ECHO': noKey,
    'INFO': noKey,
    'AUTH': noKey,
    'HELLO': noKey,
    'CLIENT': noKey,
    'CONFIG': noKey,
    'BGREWRITEAOF': noKey,
    'BGSAVE': noKey,
    'TIME': noKey,
    'DBSIZE': noKey,
    'FAILOVER': noKey,
    'FLUSHDB': noKey,
    'FLUSHALL': noKey,
    'HOTKEYS': noKey,
    'SCRIPT': noKey,
    'LASTSAVE': noKey,
    'LOLWUT': noKey,
    'CLUSTER': noKey,
    'PSYNC': noKey,
    'REPLCONF': noKey,
    'ROLE': noKey,
    'REPLICAOF': noKey,
    'SAVE': noKey,
    'SHUTDOWN': noKey,
    'SLAVEOF': noKey,
    'SWAPDB': noKey,
    'SYNC': noKey,
    'READONLY': noKey,
    'READWRITE': noKey,
    'COMMAND': noKey,
    'LATENCY': noKey,
    'SLOWLOG': noKey,
    'ACL': noKey,
    'MODULE': noKey,
    'FUNCTION': noKey,
    'PUBSUB': noKey,
    'PUBLISH': noKey,
    'SPUBLISH': CommandSpec.singleKeyAt(1),
    'MONITOR': noKey,
    'ASKING': noKey,
    'MEMORY': CommandSpec.memorySubcommand(),
    'OBJECT': CommandSpec.objectSubcommand(),

    'GET': CommandSpec.singleKeyAt(1),
    'DIGEST': CommandSpec.singleKeyAt(1),
    'DELEX': CommandSpec.singleKeyAt(1),
    'SET': CommandSpec.singleKeyAt(1),
    'SETNX': CommandSpec.singleKeyAt(1),
    'SETEX': CommandSpec.singleKeyAt(1),
    'PSETEX': CommandSpec.singleKeyAt(1),
    'GETSET': CommandSpec.singleKeyAt(1),
    'GETDEL': CommandSpec.singleKeyAt(1),
    'GETEX': CommandSpec.singleKeyAt(1),
    'STRLEN': CommandSpec.singleKeyAt(1),
    'APPEND': CommandSpec.singleKeyAt(1),
    'INCR': CommandSpec.singleKeyAt(1),
    'INCRBY': CommandSpec.singleKeyAt(1),
    'INCRBYFLOAT': CommandSpec.singleKeyAt(1),
    'DECR': CommandSpec.singleKeyAt(1),
    'DECRBY': CommandSpec.singleKeyAt(1),
    'GETRANGE': CommandSpec.singleKeyAt(1),
    'SETRANGE': CommandSpec.singleKeyAt(1),
    'GETBIT': CommandSpec.singleKeyAt(1),
    'SETBIT': CommandSpec.singleKeyAt(1),
    'BITCOUNT': CommandSpec.singleKeyAt(1),
    'BITPOS': CommandSpec.singleKeyAt(1),
    'BITFIELD': CommandSpec.singleKeyAt(1),
    'BITFIELD_RO': CommandSpec.singleKeyAt(1),
    'LCS': CommandSpec.twoKeysAt(1),
    'SUBSTR': CommandSpec.singleKeyAt(1),

    'DEL': CommandSpec.keysFrom(1),
    'UNLINK': CommandSpec.keysFrom(1),
    'MGET': CommandSpec.keysFrom(1),
    'MSET': CommandSpec.keyValuePairsFrom(1),
    'MSETEX': CommandSpec.numKeyValuePairsAt(1),
    'MSETNX': CommandSpec.keyValuePairsFrom(1),
    'EXISTS': CommandSpec.keysFrom(1),
    'TOUCH': CommandSpec.keysFrom(1),

    'EXPIRE': CommandSpec.singleKeyAt(1),
    'PEXPIRE': CommandSpec.singleKeyAt(1),
    'EXPIREAT': CommandSpec.singleKeyAt(1),
    'PEXPIREAT': CommandSpec.singleKeyAt(1),
    'EXPIRETIME': CommandSpec.singleKeyAt(1),
    'PEXPIRETIME': CommandSpec.singleKeyAt(1),
    'TTL': CommandSpec.singleKeyAt(1),
    'PTTL': CommandSpec.singleKeyAt(1),
    'PERSIST': CommandSpec.singleKeyAt(1),
    'TYPE': CommandSpec.singleKeyAt(1),
    'SORT': CommandSpec.sortStoreKeyword(),
    'SORT_RO': CommandSpec.singleKeyAt(1),
    'RENAME': CommandSpec.twoKeysAt(1),
    'RENAMENX': CommandSpec.twoKeysAt(1),
    'MOVE': CommandSpec.singleKeyAt(1),
    'MIGRATE': CommandSpec.migrateKeys(),
    'COPY': CommandSpec.twoKeysAt(1),
    'DUMP': CommandSpec.singleKeyAt(1),
    'RESTORE': CommandSpec.singleKeyAt(1),

    'HSET': CommandSpec.singleKeyAt(1),
    'HGET': CommandSpec.singleKeyAt(1),
    'HEXPIRE': CommandSpec.singleKeyAt(1),
    'HPEXPIRE': CommandSpec.singleKeyAt(1),
    'HEXPIREAT': CommandSpec.singleKeyAt(1),
    'HPEXPIREAT': CommandSpec.singleKeyAt(1),
    'HEXPIRETIME': CommandSpec.singleKeyAt(1),
    'HPEXPIRETIME': CommandSpec.singleKeyAt(1),
    'HTTL': CommandSpec.singleKeyAt(1),
    'HPTTL': CommandSpec.singleKeyAt(1),
    'HPERSIST': CommandSpec.singleKeyAt(1),
    'HMSET': CommandSpec.singleKeyAt(1),
    'HMGET': CommandSpec.singleKeyAt(1),
    'HGETDEL': CommandSpec.singleKeyAt(1),
    'HGETEX': CommandSpec.singleKeyAt(1),
    'HGETALL': CommandSpec.singleKeyAt(1),
    'HDEL': CommandSpec.singleKeyAt(1),
    'HEXISTS': CommandSpec.singleKeyAt(1),
    'HRANDFIELD': CommandSpec.singleKeyAt(1),
    'HKEYS': CommandSpec.singleKeyAt(1),
    'HVALS': CommandSpec.singleKeyAt(1),
    'HLEN': CommandSpec.singleKeyAt(1),
    'HINCRBY': CommandSpec.singleKeyAt(1),
    'HINCRBYFLOAT': CommandSpec.singleKeyAt(1),
    'HSETEX': CommandSpec.singleKeyAt(1),
    'HSETNX': CommandSpec.singleKeyAt(1),
    'HSTRLEN': CommandSpec.singleKeyAt(1),
    'HSCAN': CommandSpec.singleKeyAt(1),

    'LPUSH': CommandSpec.singleKeyAt(1),
    'LPUSHX': CommandSpec.singleKeyAt(1),
    'RPUSH': CommandSpec.singleKeyAt(1),
    'RPUSHX': CommandSpec.singleKeyAt(1),
    'LPOP': CommandSpec.singleKeyAt(1),
    'RPOP': CommandSpec.singleKeyAt(1),
    'RPOPLPUSH': CommandSpec.twoKeysAt(1),
    'LMOVE': CommandSpec.twoKeysAt(1),
    'BLMOVE': CommandSpec.twoKeysAt(1),
    'LLEN': CommandSpec.singleKeyAt(1),
    'LRANGE': CommandSpec.singleKeyAt(1),
    'LINDEX': CommandSpec.singleKeyAt(1),
    'LINSERT': CommandSpec.singleKeyAt(1),
    'LPOS': CommandSpec.singleKeyAt(1),
    'LSET': CommandSpec.singleKeyAt(1),
    'LTRIM': CommandSpec.singleKeyAt(1),
    'LREM': CommandSpec.singleKeyAt(1),
    'BLPOP': CommandSpec.keysUntilLast(1),
    'BRPOP': CommandSpec.keysUntilLast(1),
    'BRPOPLPUSH': CommandSpec.twoKeysAt(1),
    'BZPOPMIN': CommandSpec.keysUntilLast(1),
    'BZPOPMAX': CommandSpec.keysUntilLast(1),
    'LMPOP': CommandSpec.numKeysAt(1),
    'BLMPOP': CommandSpec.numKeysAt(2),

    'SADD': CommandSpec.singleKeyAt(1),
    'SREM': CommandSpec.singleKeyAt(1),
    'SMEMBERS': CommandSpec.singleKeyAt(1),
    'SISMEMBER': CommandSpec.singleKeyAt(1),
    'SMISMEMBER': CommandSpec.singleKeyAt(1),
    'SCARD': CommandSpec.singleKeyAt(1),
    'SPOP': CommandSpec.singleKeyAt(1),
    'SRANDMEMBER': CommandSpec.singleKeyAt(1),
    'SMOVE': CommandSpec.twoKeysAt(1),
    'SDIFF': CommandSpec.keysFrom(1),
    'SINTER': CommandSpec.keysFrom(1),
    'SUNION': CommandSpec.keysFrom(1),
    'SSCAN': CommandSpec.singleKeyAt(1),
    'SDIFFSTORE': CommandSpec.keysFrom(1),
    'SINTERSTORE': CommandSpec.keysFrom(1),
    'SUNIONSTORE': CommandSpec.keysFrom(1),
    'SINTERCARD': CommandSpec.numKeysAt(1),

    'ZADD': CommandSpec.singleKeyAt(1),
    'ZREM': CommandSpec.singleKeyAt(1),
    'ZCARD': CommandSpec.singleKeyAt(1),
    'ZCOUNT': CommandSpec.singleKeyAt(1),
    'ZRANGE': CommandSpec.singleKeyAt(1),
    'ZRANGESTORE': CommandSpec.twoKeysAt(1),
    'ZRANDMEMBER': CommandSpec.singleKeyAt(1),
    'ZREVRANGE': CommandSpec.singleKeyAt(1),
    'ZREVRANGEBYLEX': CommandSpec.singleKeyAt(1),
    'ZRANGEBYSCORE': CommandSpec.singleKeyAt(1),
    'ZREVRANGEBYSCORE': CommandSpec.singleKeyAt(1),
    'ZRANK': CommandSpec.singleKeyAt(1),
    'ZREVRANK': CommandSpec.singleKeyAt(1),
    'ZSCORE': CommandSpec.singleKeyAt(1),
    'ZMSCORE': CommandSpec.singleKeyAt(1),
    'ZINCRBY': CommandSpec.singleKeyAt(1),
    'ZPOPMIN': CommandSpec.singleKeyAt(1),
    'ZPOPMAX': CommandSpec.singleKeyAt(1),
    'ZREMRANGEBYSCORE': CommandSpec.singleKeyAt(1),
    'ZREMRANGEBYRANK': CommandSpec.singleKeyAt(1),
    'ZREMRANGEBYLEX': CommandSpec.singleKeyAt(1),
    'ZLEXCOUNT': CommandSpec.singleKeyAt(1),
    'ZRANGEBYLEX': CommandSpec.singleKeyAt(1),
    'ZSCAN': CommandSpec.singleKeyAt(1),
    'ZINTER': CommandSpec.numKeysAt(1),
    'ZINTERCARD': CommandSpec.numKeysAt(1),
    'ZUNION': CommandSpec.numKeysAt(1),
    'ZDIFF': CommandSpec.numKeysAt(1),
    'ZINTERSTORE': CommandSpec.numKeysWithDest(1, 2),
    'ZUNIONSTORE': CommandSpec.numKeysWithDest(1, 2),
    'ZDIFFSTORE': CommandSpec.numKeysWithDest(1, 2),
    'ZMPOP': CommandSpec.numKeysAt(1),
    'BZMPOP': CommandSpec.numKeysAt(2),

    'GEOADD': CommandSpec.singleKeyAt(1),
    'GEODIST': CommandSpec.singleKeyAt(1),
    'GEOHASH': CommandSpec.singleKeyAt(1),
    'GEOPOS': CommandSpec.singleKeyAt(1),
    'GEORADIUS': CommandSpec.singleKeyAt(1),
    'GEORADIUS_RO': CommandSpec.singleKeyAt(1),
    'GEORADIUSBYMEMBER': CommandSpec.singleKeyAt(1),
    'GEORADIUSBYMEMBER_RO': CommandSpec.singleKeyAt(1),
    'GEOSEARCH': CommandSpec.singleKeyAt(1),
    'GEOSEARCHSTORE': CommandSpec.twoKeysAt(1),

    'XADD': CommandSpec.singleKeyAt(1),
    'XRANGE': CommandSpec.singleKeyAt(1),
    'XREVRANGE': CommandSpec.singleKeyAt(1),
    'XLEN': CommandSpec.singleKeyAt(1),
    'XDEL': CommandSpec.singleKeyAt(1),
    'XDELEX': CommandSpec.singleKeyAt(1),
    'XTRIM': CommandSpec.singleKeyAt(1),
    'XACK': CommandSpec.singleKeyAt(1),
    'XACKDEL': CommandSpec.singleKeyAt(1),
    'XCFGSET': CommandSpec.singleKeyAt(1),
    'XGROUP': CommandSpec.singleKeyAt(2),
    'XREAD': CommandSpec.streamsKeyword(),
    'XREADGROUP': CommandSpec.streamsKeyword(),
    'XPENDING': CommandSpec.singleKeyAt(1),
    'XCLAIM': CommandSpec.singleKeyAt(1),
    'XAUTOCLAIM': CommandSpec.singleKeyAt(1),
    'XINFO': CommandSpec.singleKeyAt(2),
    'XSETID': CommandSpec.singleKeyAt(1),

    'EVAL': CommandSpec.numKeysAt(2),
    'EVALSHA': CommandSpec.numKeysAt(2),
    'EVAL_RO': CommandSpec.numKeysAt(2),
    'EVALSHA_RO': CommandSpec.numKeysAt(2),
    'FCALL': CommandSpec.numKeysAt(2),
    'FCALL_RO': CommandSpec.numKeysAt(2),

    'BITOP': CommandSpec.keysFrom(2),
    'PFADD': CommandSpec.singleKeyAt(1),
    'PFCOUNT': CommandSpec.keysFrom(1),
    'PFMERGE': CommandSpec.keysFrom(1),
    'RESTORE-ASKING': CommandSpec.singleKeyAt(1),
  };

  /// Extracts the key arguments from a raw Redis command.
  static List<String> extractKeys(List<dynamic> command) {
    if (command.isEmpty) return const [];
    final cmd = command.first.toString().toUpperCase();
    final spec = specs[cmd];
    if (spec == null) return const [];
    switch (spec.type) {
      case KeySpecType.none:
        return const [];
      case KeySpecType.singleKeyAtIndex:
        return _keyAt(command, spec.index!);
      case KeySpecType.twoKeysAtIndex:
        final first = _keyAt(command, spec.index!);
        final second = _keyAt(command, spec.index! + 1);
        return [...first, ...second];
      case KeySpecType.keysFromIndex:
        return _keysFrom(command, spec.index!);
      case KeySpecType.keysUntilLast:
        return _keysUntilLast(command, spec.index!);
      case KeySpecType.keyValuePairsFrom:
        return _keysFromPairs(command, spec.index!);
      case KeySpecType.numKeysAtIndex:
        return _keysFromNumKeys(command, spec.index!);
      case KeySpecType.numKeyValuePairsAtIndex:
        return _keysFromNumKeyValuePairs(command, spec.index!);
      case KeySpecType.numKeysWithDest:
        return _keysFromNumKeysWithDest(
          command,
          spec.index!,
          spec.secondIndex!,
        );
      case KeySpecType.streamsKeyword:
        return _keysAfterStreams(command);
      case KeySpecType.sortStoreKeyword:
        return _keysForSort(command);
      case KeySpecType.migrateKeys:
        return _keysForMigrate(command);
      case KeySpecType.memorySubcommand:
        return _keysForMemory(command);
      case KeySpecType.objectSubcommand:
        return _keysForObject(command);
    }
  }

  static List<String> _keyAt(List<dynamic> command, int index) {
    if (command.length <= index) return const [];
    return [keyToString(command[index])];
  }

  static List<String> _keysFrom(List<dynamic> command, int index) {
    if (command.length <= index) return const [];
    return command.sublist(index).map((value) => keyToString(value)).toList();
  }

  static List<String> _keysUntilLast(List<dynamic> command, int index) {
    if (command.length <= index) return const [];
    final end = command.length - 1;
    if (end <= index) return const [];
    return command
        .sublist(index, end)
        .map((value) => keyToString(value))
        .toList();
  }

  static List<String> _keysFromPairs(List<dynamic> command, int index) {
    if (command.length <= index) return const [];
    final keys = <String>[];
    for (var i = index; i < command.length; i += 2) {
      keys.add(keyToString(command[i]));
    }
    return keys;
  }

  static List<String> _keysFromNumKeys(List<dynamic> command, int index) {
    if (command.length <= index) return const [];
    final numKeys = _parseInt(command[index]);
    if (numKeys <= 0) return const [];
    final start = index + 1;
    final end = start + numKeys;
    if (command.length < end) return const [];
    return command
        .sublist(start, end)
        .map((value) => keyToString(value))
        .toList();
  }

  static List<String> _keysFromNumKeyValuePairs(
    List<dynamic> command,
    int index,
  ) {
    if (command.length <= index) return const [];
    final numKeys = _parseInt(command[index]);
    if (numKeys <= 0) return const [];
    final start = index + 1;
    final end = start + (numKeys * 2);
    if (command.length < end) return const [];

    final keys = <String>[];
    for (var i = start; i < end; i += 2) {
      keys.add(keyToString(command[i]));
    }
    return keys;
  }

  static List<String> _keysFromNumKeysWithDest(
    List<dynamic> command,
    int destIndex,
    int numKeysIndex,
  ) {
    final keys = <String>[];
    if (command.length > destIndex) {
      keys.add(keyToString(command[destIndex]));
    }
    keys.addAll(_keysFromNumKeys(command, numKeysIndex));
    return keys;
  }

  static List<String> _keysAfterStreams(List<dynamic> command) {
    final streamsIndex = command.indexWhere(
      (item) => item.toString().toUpperCase() == 'STREAMS',
    );
    if (streamsIndex == -1 || streamsIndex + 1 >= command.length) {
      return const [];
    }
    final remaining = command.length - streamsIndex - 1;
    if (remaining <= 0) return const [];
    final keyCount = remaining ~/ 2;
    if (keyCount <= 0) return const [];
    return command
        .sublist(streamsIndex + 1, streamsIndex + 1 + keyCount)
        .map((value) => keyToString(value))
        .toList();
  }

  static List<String> _keysForSort(List<dynamic> command) {
    final keys = _keyAt(command, 1);
    if (keys.isEmpty) return const [];

    for (var i = 2; i < command.length - 1; i++) {
      if (command[i].toString().toUpperCase() == 'STORE') {
        keys.add(keyToString(command[i + 1]));
        break;
      }
    }
    return keys;
  }

  static List<String> _keysForMigrate(List<dynamic> command) {
    if (command.length <= 3) return const [];

    final directKey = keyToString(command[3]);
    if (directKey.isNotEmpty) {
      return [directKey];
    }

    final keysIndex = command.indexWhere(
      (item) => item.toString().toUpperCase() == 'KEYS',
    );
    if (keysIndex == -1 || keysIndex + 1 >= command.length) {
      return const [];
    }
    return command
        .sublist(keysIndex + 1)
        .map((value) => keyToString(value))
        .toList();
  }

  static List<String> _keysForMemory(List<dynamic> command) {
    if (command.length <= 2) return const [];
    final subcommand = command[1].toString().toUpperCase();
    if (subcommand != 'USAGE') return const [];
    return [keyToString(command[2])];
  }

  static List<String> _keysForObject(List<dynamic> command) {
    if (command.length <= 2) return const [];
    final subcommand = command[1].toString().toUpperCase();
    switch (subcommand) {
      case 'ENCODING':
      case 'FREQ':
      case 'IDLETIME':
      case 'REFCOUNT':
        return [keyToString(command[2])];
      default:
        return const [];
    }
  }

  static void validateSameSlot(List<String> keys, ClusterSlotCache slotCache) {
    if (keys.length <= 1) return;
    final slot = slotCache.slotForKey(keys.first);
    for (final key in keys.skip(1)) {
      final nextSlot = slotCache.slotForKey(key);
      if (nextSlot != slot) {
        throw RespException(
          'CROSSSLOT Keys in request do not hash to the same slot',
        );
      }
    }
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
