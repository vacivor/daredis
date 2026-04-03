import 'package:daredis/src/cluster_command_spec.dart';
import 'package:daredis/src/cluster_slots.dart';
import 'package:daredis/src/exceptions.dart';

/// Internal cluster command routing and validation rules.
///
/// This keeps cluster-specific semantics concentrated in the routing layer
/// instead of spreading them across individual command helpers.
class ClusterCommandPolicy {
  static const Set<String> _readOnlyCommands = {
    'PING',
    'ECHO',
    'GET',
    'STRLEN',
    'GETRANGE',
    'GETBIT',
    'BITCOUNT',
    'BITPOS',
    'BITFIELD_RO',
    'DIGEST',
    'LCS',
    'SUBSTR',
    'MGET',
    'EXISTS',
    'TYPE',
    'TTL',
    'PTTL',
    'EXPIRETIME',
    'PEXPIRETIME',
    'DUMP',
    'HGET',
    'HMGET',
    'HGETALL',
    'HEXISTS',
    'HRANDFIELD',
    'HKEYS',
    'HVALS',
    'HLEN',
    'HSTRLEN',
    'HSCAN',
    'HTTL',
    'HPTTL',
    'HEXPIRETIME',
    'HPEXPIRETIME',
    'LLEN',
    'LRANGE',
    'LINDEX',
    'LPOS',
    'SMEMBERS',
    'SISMEMBER',
    'SMISMEMBER',
    'SCARD',
    'SRANDMEMBER',
    'SDIFF',
    'SINTER',
    'SUNION',
    'SSCAN',
    'ZSCORE',
    'ZMSCORE',
    'ZCARD',
    'ZCOUNT',
    'ZLEXCOUNT',
    'ZRANK',
    'ZREVRANK',
    'ZRANDMEMBER',
    'ZRANGE',
    'ZREVRANGE',
    'ZRANGEBYSCORE',
    'ZREVRANGEBYSCORE',
    'ZRANGEBYLEX',
    'ZREVRANGEBYLEX',
    'ZINTER',
    'ZUNION',
    'ZDIFF',
    'ZINTERCARD',
    'ZSCAN',
    'XLEN',
    'XRANGE',
    'XREVRANGE',
    'XREAD',
    'XPENDING',
    'GEOHASH',
    'GEOPOS',
    'GEODIST',
    'GEOSEARCH',
    'GEORADIUS_RO',
    'GEORADIUSBYMEMBER_RO',
    'JSON.GET',
    'JSON.MGET',
    'JSON.TYPE',
    'JSON.ARRLEN',
    'JSON.OBJLEN',
    'JSON.OBJKEYS',
    'JSON.RESP',
    'JSON.STRLEN',
    'TS.GET',
    'TS.INFO',
    'TS.RANGE',
    'TS.REVRANGE',
    'TS.MGET',
    'TS.MRANGE',
    'TS.MREVRANGE',
    'TS.QUERYINDEX',
    'TOPK.COUNT',
    'TOPK.INFO',
    'TOPK.LIST',
    'TOPK.QUERY',
    'VCARD',
    'VDIM',
    'VEMB',
    'VGETATTR',
    'VINFO',
    'VISMEMBER',
    'VLINKS',
    'VRANDMEMBER',
    'VRANGE',
    'VSIM',
    'PFCOUNT',
    'SORT_RO',
    'EVAL_RO',
    'EVALSHA_RO',
    'FCALL_RO',
    'XINFO',
    'OBJECT',
  };

  static const Set<String> _roundRobinKeylessCommands = {
    'PING',
    'ECHO',
  };

  /// Returns whether [command] has a registered cluster key specification.
  static bool hasKnownSpec(List<dynamic> command) {
    if (command.isEmpty) return false;
    final cmd = command.first.toString().toUpperCase();
    return ClusterCommandSpec.specs.containsKey(cmd);
  }

  /// Returns whether [command] is known to be read-only for routing purposes.
  static bool isReadOnly(List<dynamic> command) {
    if (command.isEmpty) return false;
    final cmd = command.first.toString().toUpperCase();
    if (_readOnlyCommands.contains(cmd)) {
      return true;
    }
    if (cmd == 'GEORADIUS' || cmd == 'GEORADIUSBYMEMBER') {
      return !_containsAnyOption(command, const {'STORE', 'STOREDIST'});
    }
    if (cmd == 'SORT') {
      return !_containsAnyOption(command, const {'STORE'});
    }
    if (cmd == 'JSON.DEBUG') {
      return command.length > 1 &&
          command[1].toString().toUpperCase() == 'MEMORY';
    }
    if (cmd == 'JSON.ARRINDEX') {
      return true;
    }
    if (cmd == 'MEMORY') {
      return command.length > 1 &&
          command[1].toString().toUpperCase() == 'USAGE';
    }
    return false;
  }

  /// Returns whether a keyless [command] is safe to distribute across primaries.
  ///
  /// Most keyless commands stay on a stable primary because their effects or
  /// observations can be node-local in Redis Cluster (for example `SCRIPT`).
  static bool canRoundRobinKeyless(List<dynamic> command) {
    if (command.isEmpty) return false;
    final cmd = command.first.toString().toUpperCase();
    return _roundRobinKeylessCommands.contains(cmd);
  }

  static bool _containsAnyOption(
    List<dynamic> command,
    Set<String> options,
  ) {
    for (final part in command.skip(1)) {
      if (options.contains(part.toString().toUpperCase())) {
        return true;
      }
    }
    return false;
  }

  /// Ensures [command] uses a registered cluster key specification.
  static void requireKnownSpec(List<dynamic> command, {required String context}) {
    if (hasKnownSpec(command)) return;
    final name = command.isEmpty ? '<empty>' : command.first.toString();
    throw DaredisUnsupportedException(
      'Cluster $context requires a known command spec for "$name". '
      'Use cluster.sendCommand() or add a ClusterCommandSpec entry first.',
    );
  }

  /// Returns the first extracted key for [command], or `null` when none exist.
  static String? firstKey(List<dynamic> command) {
    final keys = ClusterCommandSpec.extractKeys(command);
    if (keys.isEmpty) return null;
    return keys.first;
  }

  /// Validates that all keys in [command] hash to the same slot.
  static void validateSameSlot(
    List<dynamic> command,
    ClusterSlotCache slotCache,
  ) {
    final keys = ClusterCommandSpec.extractKeys(command);
    if (keys.length <= 1) return;
    ClusterCommandSpec.validateSameSlot(keys, slotCache);
  }

  /// Validates that all keys in [command] stay within the pinned [slot].
  static void validatePinnedSlot(
    List<dynamic> command, {
    required int slot,
    required ClusterSlotCache slotCache,
  }) {
    final keys = ClusterCommandSpec.extractKeys(command);
    for (final key in keys) {
      final nextSlot = slotCache.slotForKey(key);
      if (nextSlot != slot) {
        throw DaredisClusterException(
          'CROSSSLOT Transaction is pinned to slot $slot but key "$key" '
          'maps to slot $nextSlot',
        );
      }
    }
  }
}
