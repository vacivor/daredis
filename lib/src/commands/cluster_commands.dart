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

ClusterNodeAddress _clusterNodeAddressFromReply(dynamic reply) {
  if (reply is! List || reply.length < 2) {
    throw DaredisProtocolException('Unexpected cluster node reply: $reply');
  }
  return ClusterNodeAddress(
    reply[0].toString(),
    int.parse(reply[1].toString()),
  );
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

  Future<String> clusterReset({bool hard = false}) async {
    final res = await sendCommand(['CLUSTER', 'RESET', hard ? 'HARD' : 'SOFT']);
    return Decoders.string(res);
  }

  Future<String> clusterReplicate(String nodeId) async {
    final res = await sendCommand(['CLUSTER', 'REPLICATE', nodeId]);
    return Decoders.string(res);
  }

  Future<String> clusterAddSlots(List<int> slots) async {
    final res = await sendCommand(['CLUSTER', 'ADDSLOTS', ...slots]);
    return Decoders.string(res);
  }

  Future<String> clusterDelSlots(List<int> slots) async {
    final res = await sendCommand(['CLUSTER', 'DELSLOTS', ...slots]);
    return Decoders.string(res);
  }

  Future<String> clusterMyId() async {
    final res = await sendCommand(['CLUSTER', 'MYID']);
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
