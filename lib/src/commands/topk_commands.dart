part of '../../daredis.dart';

class TopKIncrement {
  final String item;
  final int increment;

  const TopKIncrement(this.item, this.increment);
}

class TopKEntry {
  final String item;
  final int? count;

  const TopKEntry(this.item, {this.count});
}

class TopKInfo {
  final int k;
  final int width;
  final int depth;
  final double decay;
  final Map<String, dynamic> raw;

  const TopKInfo({
    required this.k,
    required this.width,
    required this.depth,
    required this.decay,
    required this.raw,
  });
}

mixin RedisTopKCommands on RedisCommandExecutor {
  Future<String> topKReserve(
    String key,
    int topK, {
    int? width,
    int? depth,
    double? decay,
  }) async {
    final hasOptional = width != null || depth != null || decay != null;
    if (hasOptional && (width == null || depth == null || decay == null)) {
      throw ArgumentError(
        'width, depth, and decay must either all be provided or all be omitted',
      );
    }
    final args = <dynamic>['TOPK.RESERVE', key, topK];
    if (hasOptional) {
      args.addAll([width, depth, decay]);
    }
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<List<String?>> topKAdd(String key, List<String> items) async {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'must not be empty');
    }
    final res = await sendCommand(['TOPK.ADD', key, ...items]);
    if (res is! List) {
      return const <String?>[];
    }
    return res.map((value) => Decoders.toStringOrNull(value)).toList(growable: false);
  }

  Future<List<int>> topKCount(String key, List<String> items) async {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'must not be empty');
    }
    final res = await sendCommand(['TOPK.COUNT', key, ...items]);
    if (res is! List) {
      return const <int>[];
    }
    return res.map(Decoders.toInt).toList(growable: false);
  }

  Future<List<String?>> topKIncrBy(String key, List<TopKIncrement> items) async {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'must not be empty');
    }
    final args = <dynamic>['TOPK.INCRBY', key];
    for (final item in items) {
      args.addAll([item.item, item.increment]);
    }
    final res = await sendCommand(args);
    if (res is! List) {
      return const <String?>[];
    }
    return res.map((value) => Decoders.toStringOrNull(value)).toList(growable: false);
  }

  Future<TopKInfo> topKInfo(String key) async {
    final res = await sendCommand(['TOPK.INFO', key]);
    final map = _serverReplyAsMap(res);
    return TopKInfo(
      k: Decoders.toInt(map['k']),
      width: Decoders.toInt(map['width']),
      depth: Decoders.toInt(map['depth']),
      decay: Decoders.toDouble(map['decay']),
      raw: map,
    );
  }

  Future<List<TopKEntry>> topKList(String key, {bool withCount = false}) async {
    final args = <dynamic>['TOPK.LIST', key];
    if (withCount) {
      args.add('WITHCOUNT');
    }
    final res = await sendCommand(args);
    if (res is! List) {
      return const <TopKEntry>[];
    }
    if (!withCount) {
      return res
          .map((value) => TopKEntry(value.toString()))
          .toList(growable: false);
    }
    final entries = <TopKEntry>[];
    for (var i = 0; i + 1 < res.length; i += 2) {
      entries.add(
        TopKEntry(
          res[i].toString(),
          count: Decoders.toInt(res[i + 1]),
        ),
      );
    }
    return entries;
  }

  Future<List<bool>> topKQuery(String key, List<String> items) async {
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'must not be empty');
    }
    final res = await sendCommand(['TOPK.QUERY', key, ...items]);
    if (res is! List) {
      return const <bool>[];
    }
    return res.map(Decoders.toBool).toList(growable: false);
  }
}
