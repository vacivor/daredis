part of '../../daredis.dart';

class ClusterSlotRange {
  final int start;
  final int end;
  final ClusterNodeAddress primary;
  final List<ClusterNodeAddress> replicas;
  final List<dynamic> raw;

  ClusterSlotRange({
    required this.start,
    required this.end,
    required this.primary,
    required this.replicas,
    required this.raw,
  });

  factory ClusterSlotRange.fromReply(dynamic reply) {
    if (reply is! List || reply.length < 3) {
      throw DaredisProtocolException(
        'Unexpected CLUSTER SLOTS entry: $reply',
      );
    }
    final start = int.parse(reply[0].toString());
    final end = int.parse(reply[1].toString());
    final primary = _clusterNodeAddressFromReply(reply[2]);
    final replicas = <ClusterNodeAddress>[];
    for (final node in reply.skip(3)) {
      replicas.add(_clusterNodeAddressFromReply(node));
    }
    return ClusterSlotRange(
      start: start,
      end: end,
      primary: primary,
      replicas: replicas,
      raw: List<dynamic>.from(reply),
    );
  }
}

class ClusterSlotAssignmentRange {
  final int start;
  final int end;

  const ClusterSlotAssignmentRange(this.start, this.end);
}

enum ClusterFailoverMode { force, takeover }

enum ClusterSlotState {
  importing,
  migrating,
  stable,
  node,
}

enum ClusterSlotStatsOrder { asc, desc }

ClusterNodeAddress _clusterNodeAddressFromReply(dynamic reply) {
  if (reply is! List || reply.length < 2) {
    throw DaredisProtocolException('Unexpected cluster node reply: $reply');
  }
  return ClusterNodeAddress(
    reply[0].toString(),
    int.parse(reply[1].toString()),
  );
}

Map<String, dynamic> _normalizeClusterShard(Map<String, dynamic> shard) {
  final normalized = Map<String, dynamic>.from(shard);
  final slots = normalized['slots'];
  if (slots is List) {
    normalized['slots'] = slots.map((entry) {
      if (entry is Map && entry.length == 1) {
        final pair = entry.entries.first;
        return [int.parse(pair.key), pair.value];
      }
      return entry;
    }).toList(growable: false);
  }
  return normalized;
}

mixin RedisClusterCommands on RedisClusterClient {
  Future<String> asking() async {
    final res = await sendCommand(['ASKING']);
    return Decoders.string(res);
  }

  Future<dynamic> clusterSlots() => sendCommand(['CLUSTER', 'SLOTS']);

  Future<List<ClusterSlotRange>> clusterSlotRanges() async {
    final res = await clusterSlots();
    if (res is List) {
      return res.map((entry) => ClusterSlotRange.fromReply(entry)).toList();
    }
    return [];
  }

  Future<String> clusterNodes() async {
    final res = await sendCommand(['CLUSTER', 'NODES']);
    return Decoders.string(res);
  }

  Future<String> clusterInfo() async {
    final res = await sendCommand(['CLUSTER', 'INFO']);
    return Decoders.string(res);
  }

  Future<List<Map<String, dynamic>>> clusterShards() async {
    final res = await sendCommand(['CLUSTER', 'SHARDS']);
    return _serverReplyAsMapList(
      res,
    ).map(_normalizeClusterShard).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> clusterSlotStatsSlotsRange(
    int startSlot,
    int endSlot,
  ) async {
    final res = await sendCommand([
      'CLUSTER',
      'SLOT-STATS',
      'SLOTSRANGE',
      startSlot,
      endSlot,
    ]);
    return _serverReplyAsMapList(res);
  }

  Future<List<Map<String, dynamic>>> clusterSlotStatsOrderBy(
    String metric, {
    int? limit,
    ClusterSlotStatsOrder? order,
  }) async {
    final args = <dynamic>['CLUSTER', 'SLOT-STATS', 'ORDERBY', metric];
    if (limit != null) args.addAll(['LIMIT', limit]);
    if (order != null) {
      args.add(order == ClusterSlotStatsOrder.asc ? 'ASC' : 'DESC');
    }
    final res = await sendCommand(args);
    return _serverReplyAsMapList(res);
  }

  Future<int> clusterKeyslot(String key) async {
    final res = await sendCommand(['CLUSTER', 'KEYSLOT', key]);
    return Decoders.toInt(res);
  }

  Future<int> clusterCountKeysInSlot(int slot) async {
    final res = await sendCommand(['CLUSTER', 'COUNTKEYSINSLOT', slot]);
    return Decoders.toInt(res);
  }

  Future<List<String>> clusterGetKeysInSlot(int slot, int count) async {
    final res = await sendCommand(['CLUSTER', 'GETKEYSINSLOT', slot, count]);
    if (res is List) return res.map((e) => e.toString()).toList();
    return [];
  }

  Future<String> clusterMeet(String ip, int port) async {
    final res = await sendCommand(['CLUSTER', 'MEET', ip, port]);
    return Decoders.string(res);
  }

  Future<String> clusterForget(String nodeId) async {
    final res = await sendCommand(['CLUSTER', 'FORGET', nodeId]);
    return Decoders.string(res);
  }

  Future<List<Map<String, dynamic>>> clusterLinks() async {
    final res = await sendCommand(['CLUSTER', 'LINKS']);
    return _serverReplyAsMapList(res);
  }

  Future<String> clusterReset({bool hard = false}) async {
    final res = await sendCommand(['CLUSTER', 'RESET', hard ? 'HARD' : 'SOFT']);
    return Decoders.string(res);
  }

  Future<String> clusterFailover({ClusterFailoverMode? mode}) async {
    final args = <dynamic>['CLUSTER', 'FAILOVER'];
    if (mode != null) {
      args.add(mode == ClusterFailoverMode.force ? 'FORCE' : 'TAKEOVER');
    }
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<String> clusterReplicate(String nodeId) async {
    final res = await sendCommand(['CLUSTER', 'REPLICATE', nodeId]);
    return Decoders.string(res);
  }

  Future<String> clusterMigrationImport(
    List<ClusterSlotAssignmentRange> ranges,
  ) async {
    final args = <dynamic>['CLUSTER', 'MIGRATION', 'IMPORT'];
    for (final range in ranges) {
      args.addAll([range.start, range.end]);
    }
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<String> clusterMigrationCancel({String? taskId, bool all = false}) async {
    final args = <dynamic>['CLUSTER', 'MIGRATION', 'CANCEL'];
    if (all) {
      args.add('ALL');
    } else if (taskId != null) {
      args.addAll(['ID', taskId]);
    } else {
      throw ArgumentError('Provide taskId or set all=true');
    }
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<dynamic> clusterMigrationStatus({String? taskId, bool all = false}) {
    final args = <dynamic>['CLUSTER', 'MIGRATION', 'STATUS'];
    if (all) {
      args.add('ALL');
    } else if (taskId != null) {
      args.addAll(['ID', taskId]);
    }
    return sendCommand(args);
  }

  Future<List<String>> clusterReplicas(String nodeId) async {
    final res = await sendCommand(['CLUSTER', 'REPLICAS', nodeId]);
    if (res is List) {
      return res.map((value) => value.toString()).toList(growable: false);
    }
    return const [];
  }

  Future<List<String>> clusterSlaves(String nodeId) async {
    final res = await sendCommand(['CLUSTER', 'SLAVES', nodeId]);
    if (res is List) {
      return res.map((value) => value.toString()).toList(growable: false);
    }
    return const [];
  }

  Future<String> clusterAddSlots(List<int> slots) async {
    final res = await sendCommand(['CLUSTER', 'ADDSLOTS', ...slots]);
    return Decoders.string(res);
  }

  Future<String> clusterAddSlotsRange(
    List<ClusterSlotAssignmentRange> ranges,
  ) async {
    final args = <dynamic>['CLUSTER', 'ADDSLOTSRANGE'];
    for (final range in ranges) {
      args.addAll([range.start, range.end]);
    }
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<String> clusterDelSlots(List<int> slots) async {
    final res = await sendCommand(['CLUSTER', 'DELSLOTS', ...slots]);
    return Decoders.string(res);
  }

  Future<String> clusterDelSlotsRange(
    List<ClusterSlotAssignmentRange> ranges,
  ) async {
    final args = <dynamic>['CLUSTER', 'DELSLOTSRANGE'];
    for (final range in ranges) {
      args.addAll([range.start, range.end]);
    }
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<String> clusterBumpEpoch() async {
    final res = await sendCommand(['CLUSTER', 'BUMPEPOCH']);
    return Decoders.string(res);
  }

  Future<int> clusterCountFailureReports(String nodeId) async {
    final res = await sendCommand(['CLUSTER', 'COUNT-FAILURE-REPORTS', nodeId]);
    return Decoders.toInt(res);
  }

  Future<String> clusterFlushSlots() async {
    final res = await sendCommand(['CLUSTER', 'FLUSHSLOTS']);
    return Decoders.string(res);
  }

  Future<String> clusterMyId() async {
    final res = await sendCommand(['CLUSTER', 'MYID']);
    return Decoders.string(res);
  }

  Future<String> clusterMyShardId() async {
    final res = await sendCommand(['CLUSTER', 'MYSHARDID']);
    return Decoders.string(res);
  }

  Future<String> clusterSaveConfig() async {
    final res = await sendCommand(['CLUSTER', 'SAVECONFIG']);
    return Decoders.string(res);
  }

  Future<String> clusterSetConfigEpoch(int configEpoch) async {
    final res = await sendCommand([
      'CLUSTER',
      'SET-CONFIG-EPOCH',
      configEpoch,
    ]);
    return Decoders.string(res);
  }

  Future<String> clusterSetSlotStable(int slot) async {
    final res = await sendCommand(['CLUSTER', 'SETSLOT', slot, 'STABLE']);
    return Decoders.string(res);
  }

  Future<String> clusterSetSlotImporting(int slot, String nodeId) async {
    final res = await sendCommand([
      'CLUSTER',
      'SETSLOT',
      slot,
      'IMPORTING',
      nodeId,
    ]);
    return Decoders.string(res);
  }

  Future<String> clusterSetSlotMigrating(int slot, String nodeId) async {
    final res = await sendCommand([
      'CLUSTER',
      'SETSLOT',
      slot,
      'MIGRATING',
      nodeId,
    ]);
    return Decoders.string(res);
  }

  Future<String> clusterSetSlotNode(int slot, String nodeId) async {
    final res = await sendCommand(['CLUSTER', 'SETSLOT', slot, 'NODE', nodeId]);
    return Decoders.string(res);
  }

  Future<String> readOnly() async {
    final res = await sendCommand(['READONLY']);
    return Decoders.string(res);
  }

  Future<String> readWrite() async {
    final res = await sendCommand(['READWRITE']);
    return Decoders.string(res);
  }

  Future<String> restoreAsking(
    String key,
    int ttlMilliseconds,
    dynamic serializedValue, {
    bool replace = false,
    bool absTtl = false,
    int? idleTimeSeconds,
    int? frequency,
  }) async {
    final args = <dynamic>[
      'RESTORE-ASKING',
      key,
      ttlMilliseconds,
      serializedValue,
    ];
    if (replace) args.add('REPLACE');
    if (absTtl) args.add('ABSTTL');
    if (idleTimeSeconds != null) args.addAll(['IDLETIME', idleTimeSeconds]);
    if (frequency != null) args.addAll(['FREQ', frequency]);
    final res = await sendCommand(args);
    return Decoders.string(res);
  }
}
