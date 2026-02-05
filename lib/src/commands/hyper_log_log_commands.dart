part of '../../daredis.dart';

extension RedisHyperLogLogCommands on RedisCommandExecutor {
  Future<int> pfAdd(String key, dynamic elements) async {
    final res = await sendCommand([
      'PFADD',
      key,
      if (elements is List) ...elements else elements,
    ]);
    return Decoders.toInt(res);
  }

  Future<int> pfCount(dynamic keys) async {
    final res = await sendCommand([
      'PFCOUNT',
      if (keys is List) ...keys else keys,
    ]);
    return Decoders.toInt(res);
  }

  Future<String> pfMerge(String destKey, List<String> sourceKeys) async {
    final args = ['PFMERGE', destKey, ...sourceKeys];
    final res = await sendCommand(args);
    return Decoders.string(res);
  }
}
