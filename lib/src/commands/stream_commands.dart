part of '../../daredis.dart';

class StreamMessage {
  final String id;
  final Map<String, String> fields;

  StreamMessage(this.id, this.fields);
}

class StreamPendingInfo {
  final int count;
  final String? lowerId;
  final String? higherId;
  final Map<String, int>? consumers;

  StreamPendingInfo(this.count, {this.lowerId, this.higherId, this.consumers});
}

class StreamGroupInfo {
  final String name;
  final int consumers;
  final int pending;
  final String? lastDeliveredId;
  final Map<String, dynamic> raw;

  StreamGroupInfo({
    required this.name,
    required this.consumers,
    required this.pending,
    required this.lastDeliveredId,
    required this.raw,
  });

  factory StreamGroupInfo.fromReply(dynamic reply) {
    final map = _streamReplyAsMap(reply);
    return StreamGroupInfo(
      name: Decoders.toStringOrNull(map['name']) ?? '',
      consumers: Decoders.toIntOrNull(map['consumers']) ?? 0,
      pending: Decoders.toIntOrNull(map['pending']) ?? 0,
      lastDeliveredId: Decoders.toStringOrNull(map['last-delivered-id']),
      raw: map,
    );
  }
}

class StreamConsumerInfo {
  final String name;
  final int pending;
  final int idle;
  final Map<String, dynamic> raw;

  StreamConsumerInfo({
    required this.name,
    required this.pending,
    required this.idle,
    required this.raw,
  });

  factory StreamConsumerInfo.fromReply(dynamic reply) {
    final map = _streamReplyAsMap(reply);
    return StreamConsumerInfo(
      name: Decoders.toStringOrNull(map['name']) ?? '',
      pending: Decoders.toIntOrNull(map['pending']) ?? 0,
      idle: Decoders.toIntOrNull(map['idle']) ?? 0,
      raw: map,
    );
  }
}

enum StreamDeletionPolicy {
  keepRef('KEEPREF'),
  delRef('DELREF'),
  acked('ACKED');

  final String token;

  const StreamDeletionPolicy(this.token);
}

class StreamInfo {
  final int length;
  final int? radixTreeKeys;
  final int? radixTreeNodes;
  final int? groups;
  final int? lastGeneratedIdMs;
  final String? lastGeneratedId;
  final String? maxDeletedEntryId;
  final String? entriesAdded;
  final String? recordedFirstEntryId;
  final Map<String, dynamic> raw;

  StreamInfo({
    required this.length,
    required this.radixTreeKeys,
    required this.radixTreeNodes,
    required this.groups,
    required this.lastGeneratedIdMs,
    required this.lastGeneratedId,
    required this.maxDeletedEntryId,
    required this.entriesAdded,
    required this.recordedFirstEntryId,
    required this.raw,
  });

  factory StreamInfo.fromReply(dynamic reply) {
    final map = _streamReplyAsMap(reply);
    return StreamInfo(
      length: Decoders.toIntOrNull(map['length']) ?? 0,
      radixTreeKeys: Decoders.toIntOrNull(map['radix-tree-keys']),
      radixTreeNodes: Decoders.toIntOrNull(map['radix-tree-nodes']),
      groups: Decoders.toIntOrNull(map['groups']),
      lastGeneratedIdMs: Decoders.toIntOrNull(map['last-generated-id-ms']),
      lastGeneratedId: Decoders.toStringOrNull(map['last-generated-id']),
      maxDeletedEntryId: Decoders.toStringOrNull(map['max-deleted-entry-id']),
      entriesAdded: Decoders.toStringOrNull(map['entries-added']),
      recordedFirstEntryId: Decoders.toStringOrNull(
        map['recorded-first-entry-id'],
      ),
      raw: map,
    );
  }
}

Map<String, dynamic> _streamReplyAsMap(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(Decoders.string(key), nestedValue),
    );
  }
  if (value is List && value is! Uint8List && value.length.isEven) {
    final map = <String, dynamic>{};
    for (var i = 0; i < value.length; i += 2) {
      map[Decoders.string(value[i])] = value[i + 1];
    }
    return map;
  }
  throw DaredisProtocolException('Unexpected stream reply: $value');
}

List<int> _streamReplyAsIntList(dynamic value) {
  if (value is! List) {
    throw DaredisProtocolException('Unexpected stream integer list reply: $value');
  }
  return value.map(Decoders.toInt).toList();
}

void _appendStreamDeletionIds(
  List<dynamic> args,
  List<String> ids,
  StreamDeletionPolicy policy,
) {
  if (ids.isEmpty) {
    throw ArgumentError.value(ids, 'ids', 'must not be empty');
  }
  args.add(policy.token);
  args.addAll(['IDS', ids.length, ...ids]);
}

mixin RedisStreamCommands on RedisCommandExecutor {
  Future<String> xAdd(
    String key, {
    String id = '*',
    required Map<String, String> fields,
    String? maxLenStrategy,
    int? maxLenCount,
    bool approximate = false,
  }) async {
    final args = ['XADD', key, id];

    if (maxLenStrategy != null && maxLenCount != null) {
      args.add(maxLenStrategy);
      if (approximate) args.add('~');
      args.add(maxLenCount.toString());
    }

    fields.forEach((k, v) => args.addAll([k, v]));
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<List<StreamMessage>> xRange(
    String key,
    String start,
    String end, {
    int? count,
  }) async {
    final args = ['XRANGE', key, start, end];
    if (count != null) args.addAll(['COUNT', count.toString()]);
    final res = await sendCommand(args);
    return _parseStreamList(res);
  }

  Future<List<Map<String, List<StreamMessage>>>> xRead({
    int? count,
    int? block,
    required List<String> keys,
    required List<String> ids,
  }) async {
    final args = ['XREAD'];
    if (count != null) args.addAll(['COUNT', count.toString()]);
    if (block != null) args.addAll(['BLOCK', block.toString()]);
    args.add('STREAMS');
    args.addAll(keys);
    args.addAll(ids);

    final res = await sendCommand(args);
    return _parseStreamRead(res);
  }

  Future<int> xLen(String key) async {
    final res = await sendCommand(['XLEN', key]);
    return Decoders.toInt(res);
  }

  Future<int> xDel(String key, List<String> ids) async {
    final res = await sendCommand(['XDEL', key, ...ids]);
    return Decoders.toInt(res);
  }

  Future<int> xTrim(
    String key, {
    String? strategy,
    dynamic count,
    bool approximate = false,
  }) async {
    final args = ['XTRIM', key];
    if (strategy != null && count != null) {
      args.add(strategy);
      if (approximate) args.add('~');
      args.add(count);
    }
    final res = await sendCommand(args);
    return Decoders.toInt(res);
  }

  Future<List<StreamMessage>> xRevRange(
    String key,
    String end,
    String start, {
    int? count,
  }) async {
    final args = ['XREVRANGE', key, end, start];
    if (count != null) args.addAll(['COUNT', count.toString()]);
    final res = await sendCommand(args);
    return _parseStreamList(res);
  }

  Future<int> xAck(String key, String group, List<String> ids) async {
    final res = await sendCommand(['XACK', key, group, ...ids]);
    return Decoders.toInt(res);
  }

  Future<dynamic> xGroup(List<dynamic> args) async {
    return sendCommand(['XGROUP', ...args]);
  }

  Future<String> xGroupCreate(
    String key,
    String group,
    String id, {
    bool mkStream = false,
    String? entriesRead,
  }) async {
    final args = <dynamic>['XGROUP', 'CREATE', key, group, id];
    if (mkStream) args.add('MKSTREAM');
    if (entriesRead != null) args.addAll(['ENTRIESREAD', entriesRead]);
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<int> xGroupCreateConsumer(
    String key,
    String group,
    String consumer,
  ) async {
    final res = await sendCommand([
      'XGROUP',
      'CREATECONSUMER',
      key,
      group,
      consumer,
    ]);
    return Decoders.toInt(res);
  }

  Future<int> xGroupDelConsumer(
    String key,
    String group,
    String consumer,
  ) async {
    final res = await sendCommand([
      'XGROUP',
      'DELCONSUMER',
      key,
      group,
      consumer,
    ]);
    return Decoders.toInt(res);
  }

  Future<int> xGroupDestroy(String key, String group) async {
    final res = await sendCommand(['XGROUP', 'DESTROY', key, group]);
    return Decoders.toInt(res);
  }

  Future<String> xGroupSetId(
    String key,
    String group,
    String id, {
    String? entriesRead,
  }) async {
    final args = <dynamic>['XGROUP', 'SETID', key, group, id];
    if (entriesRead != null) args.addAll(['ENTRIESREAD', entriesRead]);
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<List<Map<String, List<StreamMessage>>>> xReadGroup({
    required String group,
    required String consumer,
    int? count,
    int? block,
    required List<String> keys,
    required List<String> ids,
  }) async {
    final args = ['XREADGROUP', 'GROUP', group, consumer];
    if (count != null) args.addAll(['COUNT', count.toString()]);
    if (block != null) args.addAll(['BLOCK', block.toString()]);
    args.add('STREAMS');
    args.addAll(keys);
    args.addAll(ids);
    final res = await sendCommand(args);
    return _parseStreamRead(res);
  }

  Future<StreamPendingInfo> xPending(
    String key,
    String group, {
    String? start,
    String? end,
    int? count,
    String? consumer,
  }) async {
    final args = ['XPENDING', key, group];
    if (start != null && end != null && count != null) {
      args.addAll([start, end, count.toString()]);
      if (consumer != null) args.add(consumer);
    }
    final res = await sendCommand(args);
    if (res is List && res.length >= 4) {
      final consumers = <String, int>{};
      if (res[3] is List) {
        for (var item in res[3]) {
          if (item is List && item.length == 2) {
            consumers[Decoders.string(item[0])] = Decoders.toInt(item[1]);
          }
        }
      }
      return StreamPendingInfo(
        Decoders.toInt(res[0]),
        lowerId: Decoders.toStringOrNull(res[1]),
        higherId: Decoders.toStringOrNull(res[2]),
        consumers: consumers.isNotEmpty ? consumers : null,
      );
    }
    throw DaredisProtocolException('Unexpected XPENDING response: $res');
  }

  Future<List<StreamMessage>> xClaim(
    String key,
    String group,
    String consumer,
    int minIdleTime,
    List<String> ids, {
    bool? idle,
    bool? time,
    bool? retryCount,
    bool? force,
  }) async {
    final args = ['XCLAIM', key, group, consumer, minIdleTime, ...ids];
    if (idle != null && idle) args.add('IDLE');
    if (time != null && time) args.add('TIME');
    if (retryCount != null && retryCount) args.add('RETRYCOUNT');
    if (force != null && force) args.add('FORCE');
    final res = await sendCommand(args);
    return _parseStreamList(res);
  }

  Future<List<StreamMessage>> xAutoClaim(
    String key,
    String group,
    String consumer,
    int minIdleTime,
    String start, {
    int? count,
    bool justId = false,
  }) async {
    final args = ['XAUTOCLAIM', key, group, consumer, minIdleTime, start];
    if (count != null) args.addAll(['COUNT', count]);
    if (justId) args.add('JUSTID');
    final res = await sendCommand(args);
    if (res is List && res.length == 2 && res[1] is List) {
      return _parseStreamList(res[1]);
    }
    return [];
  }

  Future<dynamic> xInfo(List<dynamic> args) async {
    return sendCommand(['XINFO', ...args]);
  }

  Future<String> xSetId(
    String key,
    String lastId, {
    int? entriesAdded,
    String? maxDeletedId,
  }) async {
    final args = <dynamic>['XSETID', key, lastId];
    if (entriesAdded != null) args.addAll(['ENTRIESADDED', entriesAdded]);
    if (maxDeletedId != null) args.addAll(['MAXDELETEDID', maxDeletedId]);
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<String> xCfgSet(
    String key, {
    int? idmpDuration,
    int? idmpMaxSize,
  }) async {
    final args = <dynamic>['XCFGSET', key];
    if (idmpDuration != null) args.addAll(['IDMP-DURATION', idmpDuration]);
    if (idmpMaxSize != null) args.addAll(['IDMP-MAXSIZE', idmpMaxSize]);
    if (args.length == 2) {
      throw ArgumentError(
        'At least one of idmpDuration or idmpMaxSize must be provided.',
      );
    }
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<dynamic> xInfoStream(String key, {bool full = false, int? count}) {
    final args = <dynamic>['STREAM', key];
    if (full) {
      args.add('FULL');
      if (count != null) args.addAll(['COUNT', count]);
    }
    return xInfo(args);
  }

  Future<StreamInfo> xInfoStreamEntry(
    String key, {
    bool full = false,
    int? count,
  }) async {
    final res = await xInfoStream(key, full: full, count: count);
    return StreamInfo.fromReply(res);
  }

  Future<dynamic> xInfoGroups(String key) {
    return xInfo(['GROUPS', key]);
  }

  Future<dynamic> xInfoConsumers(String key, String group) {
    return xInfo(['CONSUMERS', key, group]);
  }

  Future<List<StreamGroupInfo>> xInfoGroupEntries(String key) async {
    final res = await xInfoGroups(key);
    if (res is List) {
      return res.map((entry) => StreamGroupInfo.fromReply(entry)).toList();
    }
    return [];
  }

  Future<List<StreamConsumerInfo>> xInfoConsumerEntries(
    String key,
    String group,
  ) async {
    final res = await xInfoConsumers(key, group);
    if (res is List) {
      return res.map((entry) => StreamConsumerInfo.fromReply(entry)).toList();
    }
    return [];
  }

  Future<List<int>> xDelEx(
    String key,
    List<String> ids, {
    StreamDeletionPolicy policy = StreamDeletionPolicy.keepRef,
  }) async {
    final args = <dynamic>['XDELEX', key];
    _appendStreamDeletionIds(args, ids, policy);
    final res = await sendCommand(args);
    return _streamReplyAsIntList(res);
  }

  Future<List<int>> xAckDel(
    String key,
    String group,
    List<String> ids, {
    StreamDeletionPolicy policy = StreamDeletionPolicy.keepRef,
  }) async {
    final args = <dynamic>['XACKDEL', key, group];
    _appendStreamDeletionIds(args, ids, policy);
    final res = await sendCommand(args);
    return _streamReplyAsIntList(res);
  }

  List<StreamMessage> _parseStreamList(dynamic res) {
    if (res is List) {
      return res.map((item) {
        if (item is List && item.length == 2) {
          final id = Decoders.string(item[0]);
          final fields = <String, String>{};
          if (item[1] is List) {
            for (var i = 0; i < (item[1] as List).length; i += 2) {
              fields[Decoders.string((item[1] as List)[i])] = Decoders.string(
                (item[1] as List)[i + 1],
              );
            }
          }
          return StreamMessage(id, fields);
        }
        throw DaredisProtocolException('Unexpected StreamMessage: $item');
      }).toList();
    }
    return [];
  }

  List<Map<String, List<StreamMessage>>> _parseStreamRead(dynamic res) {
    final result = <Map<String, List<StreamMessage>>>[];
    if (res is List) {
      for (var streamItem in res) {
        if (streamItem is List && streamItem.length == 2) {
          final key = Decoders.string(streamItem[0]);
          final messages = _parseStreamList(streamItem[1]);
          result.add({key: messages});
        }
      }
    }
    return result;
  }
}
