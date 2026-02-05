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

extension RedisStreamCommands on RedisCommandExecutor {
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
    return res.toString();
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
            consumers[item[0].toString()] = int.parse(item[1].toString());
          }
        }
      }
      return StreamPendingInfo(
        int.parse(res[0].toString()),
        lowerId: res[1]?.toString(),
        higherId: res[2]?.toString(),
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

  Future<int> xDelEx(String key, List<String> ids) async {
    throw DaredisUnsupportedException('XDELEX is not a Redis command.');
  }

  Future<int> xAckDel(String key, String group, List<String> ids) async {
    throw DaredisUnsupportedException('XACKDEL is not a Redis command.');
  }

  List<StreamMessage> _parseStreamList(dynamic res) {
    if (res is List) {
      return res.map((item) {
        if (item is List && item.length == 2) {
          final id = item[0].toString();
          final fields = <String, String>{};
          if (item[1] is List) {
            for (var i = 0; i < (item[1] as List).length; i += 2) {
              fields[(item[1] as List)[i].toString()] = (item[1] as List)[i + 1]
                  .toString();
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
          final key = streamItem[0].toString();
          final messages = _parseStreamList(streamItem[1]);
          result.add({key: messages});
        }
      }
    }
    return result;
  }
}
