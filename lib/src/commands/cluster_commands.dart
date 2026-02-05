part of '../../daredis.dart';

extension RedisClusterCommands on RedisCommandExecutor {
  Future<dynamic> clusterSlots() => sendCommand(['CLUSTER', 'SLOTS']);

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

  Future<String> readonly() async {
    final res = await sendCommand(['READONLY']);
    return Decoders.string(res);
  }

  Future<String> readwrite() async {
    final res = await sendCommand(['READWRITE']);
    return Decoders.string(res);
  }
}
