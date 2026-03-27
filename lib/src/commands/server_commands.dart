part of '../../daredis.dart';

class RedisCommandInfoEntry {
  final String name;
  final int arity;
  final List<String> flags;
  final int firstKey;
  final int lastKey;
  final int keyStep;
  final List<String> categories;
  final List<String> tips;
  final List<dynamic> keySpecifications;
  final List<dynamic> subCommands;
  final List<dynamic> raw;

  RedisCommandInfoEntry({
    required this.name,
    required this.arity,
    required this.flags,
    required this.firstKey,
    required this.lastKey,
    required this.keyStep,
    required this.categories,
    required this.tips,
    required this.keySpecifications,
    required this.subCommands,
    required this.raw,
  });

  factory RedisCommandInfoEntry.fromReply(dynamic reply) {
    if (reply is! List || reply.length < 2) {
      throw DaredisProtocolException(
        'Unexpected COMMAND INFO entry: $reply',
      );
    }

    final flags = <String>[];
    if (reply.length > 2 && reply[2] is List) {
      flags.addAll((reply[2] as List).map(Decoders.string));
    }

    final categories = <String>[];
    if (reply.length > 6 && reply[6] is List) {
      categories.addAll((reply[6] as List).map(Decoders.string));
    }

    final tips = <String>[];
    if (reply.length > 7 && reply[7] is List) {
      tips.addAll((reply[7] as List).map(Decoders.string));
    }

    return RedisCommandInfoEntry(
      name: Decoders.string(reply[0]),
      arity: Decoders.toInt(reply[1]),
      flags: flags,
      firstKey: reply.length > 3 ? Decoders.toInt(reply[3]) : 0,
      lastKey: reply.length > 4 ? Decoders.toInt(reply[4]) : 0,
      keyStep: reply.length > 5 ? Decoders.toInt(reply[5]) : 0,
      categories: categories,
      tips: tips,
      keySpecifications: reply.length > 8 && reply[8] is List
          ? List<dynamic>.from(reply[8] as List)
          : const [],
      subCommands: reply.length > 9 && reply[9] is List
          ? List<dynamic>.from(reply[9] as List)
          : const [],
      raw: List<dynamic>.from(reply),
    );
  }
}

class RedisCommandDocArgument {
  final String name;
  final String? type;
  final String? displayText;
  final String? token;
  final bool optional;
  final bool multiple;
  final List<RedisCommandDocArgument> arguments;
  final Map<String, dynamic> raw;

  RedisCommandDocArgument({
    required this.name,
    required this.type,
    required this.displayText,
    required this.token,
    required this.optional,
    required this.multiple,
    required this.arguments,
    required this.raw,
  });

  factory RedisCommandDocArgument.fromReply(dynamic reply) {
    final map = _serverReplyAsMap(reply);
    return RedisCommandDocArgument(
      name: Decoders.toStringOrNull(map['name']) ?? '',
      type: Decoders.toStringOrNull(map['type']),
      displayText: Decoders.toStringOrNull(map['display_text']),
      token: Decoders.toStringOrNull(map['token']),
      optional: Decoders.toBoolOrNull(map['optional']) ?? false,
      multiple: Decoders.toBoolOrNull(map['multiple']) ?? false,
      arguments: map['arguments'] is List
          ? (map['arguments'] as List)
              .map((value) => RedisCommandDocArgument.fromReply(value))
              .toList(growable: false)
          : const <RedisCommandDocArgument>[],
      raw: map,
    );
  }
}

class RedisCommandDoc {
  final String name;
  final String? summary;
  final String? since;
  final String? group;
  final List<RedisCommandDocArgument> arguments;
  final Map<String, dynamic> raw;

  RedisCommandDoc({
    required this.name,
    required this.summary,
    required this.since,
    required this.group,
    required this.arguments,
    required this.raw,
  });

  factory RedisCommandDoc.fromReply(String name, dynamic reply) {
    final map = _serverReplyAsMap(reply);
    final arguments = map['arguments'] is List
        ? (map['arguments'] as List)
            .map((value) => RedisCommandDocArgument.fromReply(value))
            .toList(growable: false)
        : const <RedisCommandDocArgument>[];
    return RedisCommandDoc(
      name: name,
      summary: Decoders.toStringOrNull(map['summary']),
      since: Decoders.toStringOrNull(map['since']),
      group: Decoders.toStringOrNull(map['group']),
      arguments: arguments,
      raw: map,
    );
  }
}

class RedisFunctionDefinition {
  final String name;
  final String? description;
  final List<String> flags;
  final Map<String, dynamic> raw;

  RedisFunctionDefinition({
    required this.name,
    required this.description,
    required this.flags,
    required this.raw,
  });

  factory RedisFunctionDefinition.fromReply(dynamic reply) {
    final map = _serverReplyAsMap(reply);
    final flags = map['flags'] is List
        ? (map['flags'] as List).map(Decoders.string).toList()
        : const <String>[];
    return RedisFunctionDefinition(
      name: Decoders.toStringOrNull(map['name']) ?? '',
      description: Decoders.toStringOrNull(map['description']),
      flags: flags,
      raw: map,
    );
  }
}

class RedisFunctionLibrary {
  final String libraryName;
  final String? engine;
  final String? code;
  final List<RedisFunctionDefinition> functions;
  final Map<String, dynamic> raw;

  RedisFunctionLibrary({
    required this.libraryName,
    required this.engine,
    required this.code,
    required this.functions,
    required this.raw,
  });

  factory RedisFunctionLibrary.fromReply(dynamic reply) {
    final map = _serverReplyAsMap(reply);
    return RedisFunctionLibrary(
      libraryName: Decoders.toStringOrNull(map['library_name']) ?? '',
      engine: Decoders.toStringOrNull(map['engine']),
      code: Decoders.toStringOrNull(map['library_code']),
      functions: map['functions'] is List
          ? (map['functions'] as List)
              .map((value) => RedisFunctionDefinition.fromReply(value))
              .toList()
          : const [],
      raw: map,
    );
  }
}

class RedisFunctionStats {
  final RedisRunningFunction? runningScript;
  final Map<String, RedisFunctionEngineStats> engines;
  final Map<String, dynamic> raw;

  RedisFunctionStats({
    required this.runningScript,
    required this.engines,
    required this.raw,
  });

  factory RedisFunctionStats.fromReply(dynamic reply) {
    final map = _serverReplyAsMap(reply);
    final runningScript = map['running_script'] is Map
        ? RedisRunningFunction.fromReply(map['running_script'])
        : null;
    final engines = map['engines'] is Map
        ? (map['engines'] as Map).map(
            (key, value) => MapEntry(
              Decoders.string(key),
              RedisFunctionEngineStats.fromReply(Decoders.string(key), value),
            ),
          )
        : <String, RedisFunctionEngineStats>{};
    return RedisFunctionStats(
      runningScript: runningScript,
      engines: engines,
      raw: map,
    );
  }
}

class RedisRunningFunction {
  final String? libraryName;
  final String? functionName;
  final String? command;
  final double? durationMs;
  final Map<String, dynamic> raw;

  RedisRunningFunction({
    required this.libraryName,
    required this.functionName,
    required this.command,
    required this.durationMs,
    required this.raw,
  });

  factory RedisRunningFunction.fromReply(dynamic reply) {
    final map = _serverReplyAsMap(reply);
    return RedisRunningFunction(
      libraryName: Decoders.toStringOrNull(map['library_name']),
      functionName: Decoders.toStringOrNull(map['name']),
      command: Decoders.toStringOrNull(map['command']),
      durationMs: Decoders.toDoubleOrNull(map['duration_ms']),
      raw: map,
    );
  }
}

class RedisFunctionEngineStats {
  final String engine;
  final int? librariesCount;
  final int? functionsCount;
  final Map<String, dynamic> raw;

  RedisFunctionEngineStats({
    required this.engine,
    required this.librariesCount,
    required this.functionsCount,
    required this.raw,
  });

  factory RedisFunctionEngineStats.fromReply(String engine, dynamic reply) {
    final map = _serverReplyAsMap(reply);
    return RedisFunctionEngineStats(
      engine: engine,
      librariesCount: Decoders.toIntOrNull(map['libraries_count']),
      functionsCount: Decoders.toIntOrNull(map['functions_count']),
      raw: map,
    );
  }
}

class RedisRoleInfo {
  final String role;
  final List<dynamic> raw;
  final String? primaryHost;
  final int? primaryPort;
  final String? replicationState;
  final int? replicationOffset;
  final List<RedisRoleReplica> replicas;
  final List<String> monitoredMasters;

  RedisRoleInfo({
    required this.role,
    required this.raw,
    required this.primaryHost,
    required this.primaryPort,
    required this.replicationState,
    required this.replicationOffset,
    required this.replicas,
    required this.monitoredMasters,
  });

  factory RedisRoleInfo.fromReply(dynamic reply) {
    if (reply is! List || reply.isEmpty) {
      throw DaredisProtocolException('Unexpected ROLE reply: $reply');
    }
    final role = Decoders.string(reply.first);
    if (role == 'master') {
      final replicas = reply.length > 2 && reply[2] is List
          ? (reply[2] as List)
              .whereType<List>()
              .map(RedisRoleReplica.fromReply)
              .toList(growable: false)
          : const <RedisRoleReplica>[];
      return RedisRoleInfo(
        role: role,
        raw: List<dynamic>.from(reply),
        primaryHost: null,
        primaryPort: null,
        replicationState: null,
        replicationOffset: reply.length > 1
            ? Decoders.toIntOrNull(reply[1])
            : null,
        replicas: replicas,
        monitoredMasters: const [],
      );
    }
    if (role == 'slave' || role == 'replica') {
      return RedisRoleInfo(
        role: role,
        raw: List<dynamic>.from(reply),
        primaryHost: reply.length > 1 ? Decoders.toStringOrNull(reply[1]) : null,
        primaryPort: reply.length > 2 ? Decoders.toIntOrNull(reply[2]) : null,
        replicationState: reply.length > 3
            ? Decoders.toStringOrNull(reply[3])
            : null,
        replicationOffset: reply.length > 4
            ? Decoders.toIntOrNull(reply[4])
            : null,
        replicas: const [],
        monitoredMasters: const [],
      );
    }
    return RedisRoleInfo(
      role: role,
      raw: List<dynamic>.from(reply),
      primaryHost: null,
      primaryPort: null,
      replicationState: null,
      replicationOffset: null,
      replicas: const [],
      monitoredMasters: reply.skip(1).map(Decoders.string).toList(),
    );
  }
}

class RedisWaitAofResult {
  final int localFsyncCount;
  final int replicaFsyncCount;

  const RedisWaitAofResult(this.localFsyncCount, this.replicaFsyncCount);
}

class RedisLatencySample {
  final int timestamp;
  final int latencyMilliseconds;

  RedisLatencySample({
    required this.timestamp,
    required this.latencyMilliseconds,
  });
}

class RedisLatencyLatestEvent {
  final String event;
  final int timestamp;
  final int latestLatencyMilliseconds;
  final int maxLatencyMilliseconds;

  RedisLatencyLatestEvent({
    required this.event,
    required this.timestamp,
    required this.latestLatencyMilliseconds,
    required this.maxLatencyMilliseconds,
  });
}

enum HotKeysMetric {
  cpu('CPU'),
  net('NET');

  final String token;

  const HotKeysMetric(this.token);
}

class RedisRoleReplica {
  final String host;
  final int port;
  final int offset;

  RedisRoleReplica({
    required this.host,
    required this.port,
    required this.offset,
  });

  factory RedisRoleReplica.fromReply(List reply) {
    if (reply.length < 3) {
      throw DaredisProtocolException('Unexpected ROLE replica reply: $reply');
    }
    return RedisRoleReplica(
      host: Decoders.string(reply[0]),
      port: Decoders.toInt(reply[1]),
      offset: Decoders.toInt(reply[2]),
    );
  }
}

dynamic _normalizeServerReply(dynamic value) {
  if (value is Uint8List) {
    return Decoders.string(value);
  }
  if (value is Map) {
    return value.map(
      (key, nestedValue) =>
          MapEntry(Decoders.string(key), _normalizeServerReply(nestedValue)),
    );
  }
  if (value is List && value is! Uint8List) {
    final normalized = value.map(_normalizeServerReply).toList();
    final isPairList = normalized.length.isEven &&
        normalized.asMap().entries.every(
          (entry) =>
              entry.key.isOdd ||
              entry.value is String ||
              entry.value is Uint8List,
        );
    if (isPairList) {
      final map = <String, dynamic>{};
      for (var i = 0; i < normalized.length; i += 2) {
        map[Decoders.string(normalized[i])] = normalized[i + 1];
      }
      return map;
    }
    return normalized;
  }
  return value;
}

Map<String, dynamic> _serverReplyAsMap(dynamic value) {
  final normalized = _normalizeServerReply(value);
  if (normalized is Map<String, dynamic>) {
    return normalized;
  }
  throw DaredisProtocolException(
    'Unexpected response type: ${value.runtimeType}',
  );
}

List<Map<String, dynamic>> _serverReplyAsMapList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => _serverReplyAsMap(item))
        .toList(growable: false);
  }
  throw DaredisProtocolException(
    'Unexpected response type: ${value.runtimeType}',
  );
}

/// Dangerous administrative Redis commands that are intentionally not exposed
/// on the default `Daredis` and `DaredisCluster` client surfaces.
mixin RedisAdminCommands on RedisCommandExecutor {
  Future<dynamic> pfDebug(
    String subcommand, {
    String? key,
    List<dynamic> args = const [],
  }) {
    final command = <dynamic>['PFDEBUG', subcommand];
    if (key != null) {
      command.add(key);
    }
    command.addAll(args);
    return sendCommand(command);
  }

  Future<String> pfSelfTest() async {
    final res = await sendCommand(['PFSELFTEST']);
    return Decoders.string(res);
  }

  Future<String> configSet(String parameter, String value) async {
    final res = await sendCommand(['CONFIG', 'SET', parameter, value]);
    return Decoders.string(res);
  }

  Future<dynamic> debug(String subcommand, [String? argument]) {
    final args = ['DEBUG', subcommand];
    if (argument != null) args.add(argument);
    return sendCommand(args);
  }

  Future<String> replicaOf(String? host, int? port) async {
    final args = <dynamic>['REPLICAOF'];
    if (host == null || port == null) {
      args.addAll(['NO', 'ONE']);
    } else {
      args.addAll([host, port]);
    }
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<String> slaveOf(String? host, int? port) {
    return replicaOf(host, port);
  }

  Future<String> flushDb({bool? async}) async {
    final res = await sendCommand(['FLUSHDB', if (async == true) 'ASYNC']);
    return Decoders.string(res);
  }

  Future<String> flushAll({bool? async}) async {
    final res = await sendCommand(['FLUSHALL', if (async == true) 'ASYNC']);
    return Decoders.string(res);
  }

  Future<String> bgRewriteAof() async {
    final res = await sendCommand(['BGREWRITEAOF']);
    return Decoders.string(res);
  }

  Future<String> bgSave({bool schedule = false}) async {
    final res = await sendCommand(['BGSAVE', if (schedule) 'SCHEDULE']);
    return Decoders.string(res);
  }

  Future<String> failover({
    String? targetHost,
    int? targetPort,
    bool force = false,
    bool abort = false,
    int? timeoutMs,
  }) async {
    if ((targetHost == null) != (targetPort == null)) {
      throw ArgumentError(
        'FAILOVER TO requires both targetHost and targetPort',
      );
    }
    if (force && (targetHost == null || targetPort == null || timeoutMs == null)) {
      throw ArgumentError(
        'FAILOVER FORCE requires targetHost, targetPort, and timeoutMs',
      );
    }
    if (abort &&
        (targetHost != null || targetPort != null || force || timeoutMs != null)) {
      throw ArgumentError('FAILOVER ABORT cannot be combined with other options');
    }

    final args = <dynamic>['FAILOVER'];
    if (targetHost != null && targetPort != null) {
      args.addAll(['TO', targetHost, targetPort]);
      if (force) {
        args.add('FORCE');
      }
    }
    if (abort) {
      args.add('ABORT');
    }
    if (timeoutMs != null) {
      args.addAll(['TIMEOUT', timeoutMs]);
    }
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<dynamic> hotKeys(List<dynamic> args) {
    return sendCommand(['HOTKEYS', ...args]);
  }

  Future<String> hotKeysStart({
    required int metricsCount,
    required Set<HotKeysMetric> metrics,
    int? count,
    int? durationSeconds,
    int? sampleRatio,
    List<int>? slots,
  }) async {
    if (metrics.isEmpty) {
      throw ArgumentError('HOTKEYS START requires at least one metric');
    }
    final args = <dynamic>['START', 'METRICS', metricsCount];
    for (final metric in metrics) {
      args.add(metric.token);
    }
    if (count != null) {
      args.addAll(['COUNT', count]);
    }
    if (durationSeconds != null) {
      args.addAll(['DURATION', durationSeconds]);
    }
    if (sampleRatio != null) {
      args.addAll(['SAMPLE', sampleRatio]);
    }
    if (slots != null) {
      args.addAll(['SLOTS', slots.length, ...slots]);
    }
    final res = await hotKeys(args);
    return Decoders.string(res);
  }

  Future<Map<String, dynamic>?> hotKeysGet() async {
    final res = await hotKeys(['GET']);
    if (res == null) {
      return null;
    }
    return _serverReplyAsMap(res);
  }

  Future<String> hotKeysStop() async {
    final res = await hotKeys(['STOP']);
    return Decoders.string(res);
  }

  Future<String> hotKeysReset() async {
    final res = await hotKeys(['RESET']);
    return Decoders.string(res);
  }

  Future<int> lastSave() async {
    final res = await sendCommand(['LASTSAVE']);
    return Decoders.toInt(res);
  }

  Future<String> lolWut({
    int? version,
    List<int> arguments = const [],
  }) async {
    final args = <dynamic>['LOLWUT'];
    if (version != null) {
      args.addAll(['VERSION', version]);
    }
    args.addAll(arguments);
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<String> configRewrite() async {
    final res = await sendCommand(['CONFIG', 'REWRITE']);
    return Decoders.string(res);
  }

  Future<String> configResetStat() async {
    final res = await sendCommand(['CONFIG', 'RESETSTAT']);
    return Decoders.string(res);
  }

  Future<int> commandCount() async {
    final res = await sendCommand(['COMMAND', 'COUNT']);
    return Decoders.toInt(res);
  }

  Future<Map<String, dynamic>> commandDocs([List<String>? commands]) async {
    final res = await sendCommand([
      'COMMAND',
      'DOCS',
      if (commands != null) ...commands,
    ]);
    return _serverReplyAsMap(res);
  }

  Future<Map<String, dynamic>> commandDocsFor(List<String> commands) {
    return commandDocs(commands);
  }

  Future<List<RedisCommandDoc>> commandDocEntriesFor(
    List<String> commands,
  ) async {
    final docs = await commandDocs(commands);
    return docs.entries
        .map((entry) => RedisCommandDoc.fromReply(entry.key, entry.value))
        .toList(growable: false);
  }

  Future<List<dynamic>> commandInfo([List<String>? commands]) async {
    final res = await sendCommand([
      'COMMAND',
      'INFO',
      if (commands != null) ...commands,
    ]);
    if (res is List) {
      return List<dynamic>.from(res);
    }
    return [];
  }

  Future<List<dynamic>> commandInfoFor(List<String> commands) {
    return commandInfo(commands);
  }

  Future<List<RedisCommandInfoEntry>> commandInfoEntriesFor(
    List<String> commands,
  ) async {
    final entries = await commandInfo(commands);
    return entries
        .map((entry) => RedisCommandInfoEntry.fromReply(entry))
        .toList();
  }

  Future<List<dynamic>> commandList() async {
    final res = await sendCommand(['COMMAND']);
    if (res is List) return res;
    return [];
  }

  Future<List<dynamic>> slowlogGet([int? count]) async {
    final args = <dynamic>['SLOWLOG', 'GET'];
    if (count != null) args.add(count);
    final res = await sendCommand(args);
    if (res is List) return res;
    return [];
  }

  Future<int> slowlogLen() async {
    final res = await sendCommand(['SLOWLOG', 'LEN']);
    return Decoders.toInt(res);
  }

  Future<String> slowlogReset() async {
    final res = await sendCommand(['SLOWLOG', 'RESET']);
    return Decoders.string(res);
  }

  Future<String> memoryDoctor() async {
    final res = await sendCommand(['MEMORY', 'DOCTOR']);
    return Decoders.string(res);
  }

  Future<String> memoryMallocStats() async {
    final res = await sendCommand(['MEMORY', 'MALLOC-STATS']);
    return Decoders.string(res);
  }

  Future<String> memoryPurge() async {
    final res = await sendCommand(['MEMORY', 'PURGE']);
    return Decoders.string(res);
  }

  Future<Map<String, dynamic>> memoryStats() async {
    final res = await sendCommand(['MEMORY', 'STATS']);
    return _serverReplyAsMap(res);
  }

  Future<String> latencyDoctor() async {
    final res = await sendCommand(['LATENCY', 'DOCTOR']);
    return Decoders.string(res);
  }

  Future<String> latencyGraph(String event) async {
    final res = await sendCommand(['LATENCY', 'GRAPH', event]);
    return Decoders.string(res);
  }

  Future<Map<String, dynamic>> latencyHistogram([List<String>? commands]) async {
    final res = await sendCommand([
      'LATENCY',
      'HISTOGRAM',
      if (commands != null) ...commands,
    ]);
    return _serverReplyAsMap(res);
  }

  Future<List<RedisLatencySample>> latencyHistory(String event) async {
    final res = await sendCommand(['LATENCY', 'HISTORY', event]);
    if (res is! List) return const [];
    return res.whereType<List>().map((entry) {
      return RedisLatencySample(
        timestamp: Decoders.toInt(entry[0]),
        latencyMilliseconds: Decoders.toInt(entry[1]),
      );
    }).toList(growable: false);
  }

  Future<List<RedisLatencyLatestEvent>> latencyLatest() async {
    final res = await sendCommand(['LATENCY', 'LATEST']);
    if (res is! List) return const [];
    return res.whereType<List>().map((entry) {
      return RedisLatencyLatestEvent(
        event: Decoders.string(entry[0]),
        timestamp: Decoders.toInt(entry[1]),
        latestLatencyMilliseconds: Decoders.toInt(entry[2]),
        maxLatencyMilliseconds: Decoders.toInt(entry[3]),
      );
    }).toList(growable: false);
  }

  Future<int> latencyReset([List<String>? events]) async {
    final res = await sendCommand([
      'LATENCY',
      'RESET',
      if (events != null) ...events,
    ]);
    return Decoders.toInt(res);
  }

  Future<List<Map<String, dynamic>>> moduleList() async {
    final res = await sendCommand(['MODULE', 'LIST']);
    return _serverReplyAsMapList(res);
  }

  Future<String> moduleLoad(String path, [List<String>? args]) async {
    final res = await sendCommand([
      'MODULE',
      'LOAD',
      path,
      if (args != null) ...args,
    ]);
    return Decoders.string(res);
  }

  Future<String> moduleLoadEx(
    String path, {
    Map<String, String>? configs,
    List<String>? args,
  }) async {
    final command = <dynamic>['MODULE', 'LOADEX', path];
    if (configs != null) {
      configs.forEach((name, value) {
        command.addAll(['CONFIG', name, value]);
      });
    }
    if (args != null && args.isNotEmpty) {
      command.addAll(['ARGS', ...args]);
    }
    final res = await sendCommand(command);
    return Decoders.string(res);
  }

  Future<String> moduleUnload(String name) async {
    final res = await sendCommand(['MODULE', 'UNLOAD', name]);
    return Decoders.string(res);
  }

  Future<dynamic> functionLoad(String code, {bool replace = false}) {
    final args = ['FUNCTION', 'LOAD'];
    if (replace) args.add('REPLACE');
    args.add(code);
    return sendCommand(args);
  }

  Future<dynamic> functionLoadReplace(String code) {
    return functionLoad(code, replace: true);
  }

  Future<String> functionDelete(String libraryName) async {
    final res = await sendCommand(['FUNCTION', 'DELETE', libraryName]);
    return Decoders.string(res);
  }

  Future<String> functionFlush({bool async = false}) async {
    final res = await sendCommand(['FUNCTION', 'FLUSH', if (async) 'ASYNC']);
    return Decoders.string(res);
  }

  Future<dynamic> replConf(List<dynamic> args) {
    return sendCommand(['REPLCONF', ...args]);
  }

  Future<dynamic> replConfListeningPort(int port) {
    return replConf(['listening-port', port]);
  }

  Future<dynamic> replConfAck(int offset) {
    return replConf(['ACK', offset]);
  }

  Future<dynamic> replConfCapabilities(List<String> capabilities) {
    final args = <dynamic>[];
    for (final capability in capabilities) {
      args.addAll(['capa', capability]);
    }
    return replConf(args);
  }

  Future<dynamic> psync(String replicationId, int offset) {
    return sendCommand(['PSYNC', replicationId, offset]);
  }

  Future<dynamic> sync() {
    return sendCommand(['SYNC']);
  }

  Future<String> save() async {
    final res = await sendCommand(['SAVE']);
    return Decoders.string(res);
  }

  Future<String?> shutdown({
    bool save = false,
    bool noSave = false,
    bool now = false,
    bool force = false,
    bool abort = false,
  }) async {
    if (save && noSave) {
      throw ArgumentError('SHUTDOWN cannot combine save and noSave');
    }
    if (abort && (save || noSave || now || force)) {
      throw ArgumentError('SHUTDOWN ABORT cannot be combined with other flags');
    }
    final args = <dynamic>['SHUTDOWN'];
    if (save) {
      args.add('SAVE');
    } else if (noSave) {
      args.add('NOSAVE');
    }
    if (now) {
      args.add('NOW');
    }
    if (force) {
      args.add('FORCE');
    }
    if (abort) {
      args.add('ABORT');
    }
    final res = await sendCommand(args);
    return Decoders.toStringOrNull(res);
  }

  Future<String> swapDb(int index1, int index2) async {
    final res = await sendCommand(['SWAPDB', index1, index2]);
    return Decoders.string(res);
  }

  Future<String> aclSetUser(List<dynamic> args) async {
    final res = await sendCommand(['ACL', 'SETUSER', ...args]);
    return Decoders.string(res);
  }

  Future<String> aclSetUserRules(String username, List<dynamic> rules) async {
    return aclSetUser([username, ...rules]);
  }

  Future<int> aclDelUser(List<String> users) async {
    final res = await sendCommand(['ACL', 'DELUSER', ...users]);
    return Decoders.toInt(res);
  }

  Future<String> aclLoad() async {
    final res = await sendCommand(['ACL', 'LOAD']);
    return Decoders.string(res);
  }

  Future<String> aclSave() async {
    final res = await sendCommand(['ACL', 'SAVE']);
    return Decoders.string(res);
  }
}

/// Safe read-mostly server helpers exposed on the default client APIs.
mixin RedisServerIntrospectionCommands on RedisCommandExecutor {
  Future<int> commandCount() async {
    final res = await sendCommand(['COMMAND', 'COUNT']);
    return Decoders.toInt(res);
  }

  Future<Map<String, dynamic>> commandDocs([List<String>? commands]) async {
    final res = await sendCommand([
      'COMMAND',
      'DOCS',
      if (commands != null) ...commands,
    ]);
    return _serverReplyAsMap(res);
  }

  Future<Map<String, dynamic>> commandDocsFor(List<String> commands) {
    return commandDocs(commands);
  }

  Future<List<RedisCommandDoc>> commandDocEntriesFor(
    List<String> commands,
  ) async {
    final docs = await commandDocs(commands);
    return docs.entries
        .map((entry) => RedisCommandDoc.fromReply(entry.key, entry.value))
        .toList(growable: false);
  }

  Future<List<dynamic>> commandInfo([List<String>? commands]) async {
    final res = await sendCommand([
      'COMMAND',
      'INFO',
      if (commands != null) ...commands,
    ]);
    if (res is List) {
      return List<dynamic>.from(res);
    }
    return [];
  }

  Future<List<dynamic>> commandInfoFor(List<String> commands) {
    return commandInfo(commands);
  }

  Future<List<RedisCommandInfoEntry>> commandInfoEntriesFor(
    List<String> commands,
  ) async {
    final entries = await commandInfo(commands);
    return entries
        .map((entry) => RedisCommandInfoEntry.fromReply(entry))
        .toList();
  }

  Future<List<dynamic>> commandList() async {
    final res = await sendCommand(['COMMAND']);
    if (res is List) return res;
    return [];
  }

  Future<List<dynamic>> slowlogGet([int? count]) async {
    final args = <dynamic>['SLOWLOG', 'GET'];
    if (count != null) args.add(count);
    final res = await sendCommand(args);
    if (res is List) return res;
    return [];
  }

  Future<int> slowlogLen() async {
    final res = await sendCommand(['SLOWLOG', 'LEN']);
    return Decoders.toInt(res);
  }

  Future<String> slowlogReset() async {
    final res = await sendCommand(['SLOWLOG', 'RESET']);
    return Decoders.string(res);
  }

  Future<String> memoryDoctor() async {
    final res = await sendCommand(['MEMORY', 'DOCTOR']);
    return Decoders.string(res);
  }

  Future<String> memoryMallocStats() async {
    final res = await sendCommand(['MEMORY', 'MALLOC-STATS']);
    return Decoders.string(res);
  }

  Future<String> memoryPurge() async {
    final res = await sendCommand(['MEMORY', 'PURGE']);
    return Decoders.string(res);
  }

  Future<Map<String, dynamic>> memoryStats() async {
    final res = await sendCommand(['MEMORY', 'STATS']);
    return _serverReplyAsMap(res);
  }

  Future<String> latencyDoctor() async {
    final res = await sendCommand(['LATENCY', 'DOCTOR']);
    return Decoders.string(res);
  }

  Future<String> latencyGraph(String event) async {
    final res = await sendCommand(['LATENCY', 'GRAPH', event]);
    return Decoders.string(res);
  }

  Future<Map<String, dynamic>> latencyHistogram([List<String>? commands]) async {
    final res = await sendCommand([
      'LATENCY',
      'HISTOGRAM',
      if (commands != null) ...commands,
    ]);
    return _serverReplyAsMap(res);
  }

  Future<List<RedisLatencySample>> latencyHistory(String event) async {
    final res = await sendCommand(['LATENCY', 'HISTORY', event]);
    if (res is! List) return const [];
    return res.whereType<List>().map((entry) {
      return RedisLatencySample(
        timestamp: Decoders.toInt(entry[0]),
        latencyMilliseconds: Decoders.toInt(entry[1]),
      );
    }).toList(growable: false);
  }

  Future<List<RedisLatencyLatestEvent>> latencyLatest() async {
    final res = await sendCommand(['LATENCY', 'LATEST']);
    if (res is! List) return const [];
    return res.whereType<List>().map((entry) {
      return RedisLatencyLatestEvent(
        event: Decoders.string(entry[0]),
        timestamp: Decoders.toInt(entry[1]),
        latestLatencyMilliseconds: Decoders.toInt(entry[2]),
        maxLatencyMilliseconds: Decoders.toInt(entry[3]),
      );
    }).toList(growable: false);
  }

  Future<int> latencyReset([List<String>? events]) async {
    final res = await sendCommand([
      'LATENCY',
      'RESET',
      if (events != null) ...events,
    ]);
    return Decoders.toInt(res);
  }

  Future<List<Map<String, dynamic>>> moduleList() async {
    final res = await sendCommand(['MODULE', 'LIST']);
    return _serverReplyAsMapList(res);
  }

  Future<List<Map<String, dynamic>>> functionList({
    String? libraryName,
    bool withCode = false,
  }) async {
    final args = ['FUNCTION', 'LIST'];
    if (libraryName != null) args.addAll(['LIBRARYNAME', libraryName]);
    if (withCode) args.add('WITHCODE');
    final res = await sendCommand(args);
    return _serverReplyAsMapList(res);
  }

  Future<List<Map<String, dynamic>>> functionListLibraries({
    bool withCode = false,
  }) {
    return functionList(withCode: withCode);
  }

  Future<List<RedisFunctionLibrary>> functionLibraryEntries({
    String? libraryName,
    bool withCode = false,
  }) async {
    final libraries = await functionList(
      libraryName: libraryName,
      withCode: withCode,
    );
    return libraries
        .map((library) => RedisFunctionLibrary.fromReply(library))
        .toList();
  }

  Future<Map<String, dynamic>> functionStats() async {
    final res = await sendCommand(['FUNCTION', 'STATS']);
    return _serverReplyAsMap(res);
  }

  Future<RedisFunctionStats> functionStatsEntry() async {
    final res = await sendCommand(['FUNCTION', 'STATS']);
    return RedisFunctionStats.fromReply(res);
  }

  Future<List<String>> aclList() async {
    final res = await sendCommand(['ACL', 'LIST']);
    if (res is List) return res.map(Decoders.string).toList();
    final text = Decoders.toStringOrNull(res);
    if (text != null) return text.split('\n');
    return [];
  }

  Future<List<String>> aclUsers() async {
    final res = await sendCommand(['ACL', 'USERS']);
    if (res is List) return res.map(Decoders.string).toList();
    return [];
  }

  Future<List<String>> aclCat([String? category]) async {
    final args = <dynamic>['ACL', 'CAT'];
    if (category != null) args.add(category);
    final res = await sendCommand(args);
    if (res is List) return res.map(Decoders.string).toList();
    return [];
  }

  Future<String> aclDryRun(
    String username,
    String command, [
    List<String> args = const [],
  ]) async {
    final res = await sendCommand(['ACL', 'DRYRUN', username, command, ...args]);
    return Decoders.string(res);
  }

  Future<Map<String, dynamic>> aclGetUser(String username) async {
    final res = await sendCommand(['ACL', 'GETUSER', username]);
    return _serverReplyAsMap(res);
  }

  Future<String> aclWhoAmI() async {
    final res = await sendCommand(['ACL', 'WHOAMI']);
    return Decoders.string(res);
  }

  Future<String> aclGenPass([int? bits]) async {
    final args = <dynamic>['ACL', 'GENPASS'];
    if (bits != null) args.add(bits);
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<dynamic> aclLog([int? count]) {
    final args = <dynamic>['ACL', 'LOG'];
    if (count != null) args.add(count);
    return sendCommand(args);
  }

  Future<List<dynamic>> aclLogEntries([int? count]) async {
    final res = await aclLog(count);
    if (res is List) {
      return res.map(_normalizeServerReply).toList();
    }
    return [];
  }

  Future<String> aclLogReset() async {
    final res = await sendCommand(['ACL', 'LOG', 'RESET']);
    return Decoders.string(res);
  }
}

mixin RedisDedicatedConnectionCommands on RedisCommandExecutor {
  Future<int> waitReplicas(int numReplicas, int timeoutMs) async {
    final res = await sendCommand(['WAIT', numReplicas, timeoutMs]);
    return Decoders.toInt(res);
  }

  Future<RedisWaitAofResult> waitAof(
    int numLocal,
    int numReplicas,
    int timeoutMs,
  ) async {
    final res = await sendCommand(['WAITAOF', numLocal, numReplicas, timeoutMs]);
    if (res is List && res.length == 2) {
      return RedisWaitAofResult(
        Decoders.toInt(res[0]),
        Decoders.toInt(res[1]),
      );
    }
    throw DaredisProtocolException('Unexpected WAITAOF response: $res');
  }

  Future<String> resetConnection() async {
    final res = await sendCommand(['RESET']);
    return Decoders.string(res);
  }
}

mixin RedisStandaloneConnectionCommands on RedisCommandExecutor {
  Future<String> selectDb(int database) async {
    final res = await sendCommand(['SELECT', database]);
    return Decoders.string(res);
  }
}

mixin RedisServerCommands on RedisCommandExecutor {
  Future<String> auth(String password, {String? username}) async {
    final args = <dynamic>['AUTH'];
    if (username != null) args.add(username);
    args.add(password);
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<Map<String, dynamic>> hello({
    int protocolVersion = 3,
    String? username,
    String? password,
    String? clientName,
  }) async {
    if ((username == null) != (password == null)) {
      throw ArgumentError('HELLO AUTH requires both username and password');
    }

    final args = <dynamic>['HELLO', protocolVersion];
    if (username != null && password != null) {
      args.addAll(['AUTH', username, password]);
    }
    if (clientName != null) {
      args.addAll(['SETNAME', clientName]);
    }
    final res = await sendCommand(args);
    return _serverReplyAsMap(res);
  }

  Future<String> ping([String? message]) async {
    final args = ['PING'];
    if (message != null) args.add(message);
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<String> echo(String message) async {
    final res = await sendCommand(['ECHO', message]);
    return Decoders.string(res);
  }

  Future<String> info([String? section]) async {
    final args = ['INFO'];
    if (section != null) args.add(section);
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<Map<String, String>> configGet(String parameter) async {
    final res = await sendCommand(['CONFIG', 'GET', parameter]);
    if (res is Map) {
      return res.map(
        (key, value) => MapEntry(Decoders.string(key), Decoders.string(value)),
      );
    }
    if (res is List && res.length % 2 == 0) {
      final map = <String, String>{};
      for (var i = 0; i < res.length; i += 2) {
        map[Decoders.string(res[i])] = Decoders.string(res[i + 1]);
      }
      return map;
    }
    return {};
  }

  Future<String> clientList() async {
    final res = await sendCommand(['CLIENT', 'LIST']);
    return Decoders.string(res);
  }

  Future<int> clientId() async {
    final res = await sendCommand(['CLIENT', 'ID']);
    return Decoders.toInt(res);
  }

  Future<String> clientSetName(String name) async {
    final res = await sendCommand(['CLIENT', 'SETNAME', name]);
    return Decoders.string(res);
  }

  Future<String?> clientGetName() async {
    final res = await sendCommand(['CLIENT', 'GETNAME']);
    return Decoders.toStringOrNull(res);
  }

  Future<String> clientKillByAddr(String addr) async {
    final res = await sendCommand(['CLIENT', 'KILL', addr]);
    return Decoders.string(res);
  }

  Future<dynamic> clientTracking({
    bool enable = true,
    int? redirect,
    List<String>? prefixes,
    bool bcast = false,
    bool optIn = false,
    bool optOut = false,
    bool noLoop = false,
  }) {
    final args = <dynamic>['CLIENT', 'TRACKING', enable ? 'ON' : 'OFF'];
    if (redirect != null) args.addAll(['REDIRECT', redirect]);
    if (prefixes != null) {
      for (final prefix in prefixes) {
        args.addAll(['PREFIX', prefix]);
      }
    }
    if (bcast) args.add('BCAST');
    if (optIn) args.add('OPTIN');
    if (optOut) args.add('OPTOUT');
    if (noLoop) args.add('NOLOOP');
    return sendCommand(args);
  }

  Future<String> clientTrackingOn({
    int? redirect,
    List<String>? prefixes,
    bool bcast = false,
    bool optIn = false,
    bool optOut = false,
    bool noLoop = false,
  }) async {
    final res = await clientTracking(
      enable: true,
      redirect: redirect,
      prefixes: prefixes,
      bcast: bcast,
      optIn: optIn,
      optOut: optOut,
      noLoop: noLoop,
    );
    return Decoders.string(res);
  }

  Future<String> clientTrackingOff() async {
    final res = await clientTracking(enable: false);
    return Decoders.string(res);
  }

  Future<Map<String, dynamic>> clientTrackingInfo() async {
    final res = await sendCommand(['CLIENT', 'TRACKINGINFO']);
    return _serverReplyAsMap(res);
  }

  Future<String> clientUnpause() async {
    final res = await sendCommand(['CLIENT', 'UNPAUSE']);
    return Decoders.string(res);
  }

  Future<String> clientPause(int timeoutMs, {bool write = false}) async {
    final args = <dynamic>[
      'CLIENT',
      'PAUSE',
      timeoutMs,
      write ? 'WRITE' : 'ALL',
    ];
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<List<int>> time() async {
    final res = await sendCommand(['TIME']);
    if (res is List && res.length == 2) {
      return [Decoders.toInt(res[0]), Decoders.toInt(res[1])];
    }
    return [];
  }

  Future<int> dbSize() async {
    final res = await sendCommand(['DBSIZE']);
    return Decoders.toInt(res);
  }

  Future<dynamic> role() => sendCommand(['ROLE']);

  Future<RedisRoleInfo> roleInfo() async {
    final res = await role();
    return RedisRoleInfo.fromReply(res);
  }

  Future<List<String>> pubSubChannels([String? pattern]) async {
    final args = ['PUBSUB', 'CHANNELS'];
    if (pattern != null) args.add(pattern);
    final res = await sendCommand(args);
    if (res is List) return res.map(Decoders.string).toList();
    return [];
  }

  Future<Map<String, int>> pubSubNumSub(List<String> channels) async {
    final res = await sendCommand(['PUBSUB', 'NUMSUB', ...channels]);
    if (res is List && res.length % 2 == 0) {
      final map = <String, int>{};
      for (var i = 0; i < res.length; i += 2) {
        map[Decoders.string(res[i])] = Decoders.toInt(res[i + 1]);
      }
      return map;
    }
    return {};
  }

  Future<int> pubSubNumPat() async {
    final res = await sendCommand(['PUBSUB', 'NUMPAT']);
    return Decoders.toInt(res);
  }

  Future<int> publish(String channel, dynamic message) async {
    final res = await sendCommand(['PUBLISH', channel, message]);
    return Decoders.toInt(res);
  }

  Future<List<String>> pubSubShardChannels([String? pattern]) async {
    final args = ['PUBSUB', 'SHARDCHANNELS'];
    if (pattern != null) args.add(pattern);
    final res = await sendCommand(args);
    if (res is List) return res.map(Decoders.string).toList();
    return [];
  }

  Future<Map<String, int>> pubSubShardNumSub(List<String> channels) async {
    final res = await sendCommand(['PUBSUB', 'SHARDNUMSUB', ...channels]);
    if (res is List && res.length % 2 == 0) {
      final map = <String, int>{};
      for (var i = 0; i < res.length; i += 2) {
        map[Decoders.string(res[i])] = Decoders.toInt(res[i + 1]);
      }
      return map;
    }
    return {};
  }

  Future<int> spublish(String shardChannel, dynamic message) async {
    final res = await sendCommand(['SPUBLISH', shardChannel, message]);
    return Decoders.toInt(res);
  }

  Future<List<Map<String, dynamic>>> functionList({
    String? libraryName,
    bool withCode = false,
  }) async {
    final args = ['FUNCTION', 'LIST'];
    if (libraryName != null) args.addAll(['LIBRARYNAME', libraryName]);
    if (withCode) args.add('WITHCODE');
    final res = await sendCommand(args);
    return _serverReplyAsMapList(res);
  }

  Future<List<Map<String, dynamic>>> functionListLibraries({
    bool withCode = false,
  }) {
    return functionList(withCode: withCode);
  }

  Future<List<RedisFunctionLibrary>> functionLibraryEntries({
    String? libraryName,
    bool withCode = false,
  }) async {
    final libraries = await functionList(
      libraryName: libraryName,
      withCode: withCode,
    );
    return libraries
        .map((library) => RedisFunctionLibrary.fromReply(library))
        .toList();
  }

  Future<Map<String, dynamic>> functionStats() async {
    final res = await sendCommand(['FUNCTION', 'STATS']);
    return _serverReplyAsMap(res);
  }

  Future<RedisFunctionStats> functionStatsEntry() async {
    final res = await sendCommand(['FUNCTION', 'STATS']);
    return RedisFunctionStats.fromReply(res);
  }

  Future<List<String>> aclList() async {
    final res = await sendCommand(['ACL', 'LIST']);
    if (res is List) return res.map(Decoders.string).toList();
    final text = Decoders.toStringOrNull(res);
    if (text != null) return text.split('\n');
    return [];
  }

  Future<List<String>> aclUsers() async {
    final res = await sendCommand(['ACL', 'USERS']);
    if (res is List) return res.map(Decoders.string).toList();
    return [];
  }

  Future<List<String>> aclCat([String? category]) async {
    final args = <dynamic>['ACL', 'CAT'];
    if (category != null) args.add(category);
    final res = await sendCommand(args);
    if (res is List) return res.map(Decoders.string).toList();
    return [];
  }

  Future<String> aclDryRun(
    String username,
    String command, [
    List<String> args = const [],
  ]) async {
    final res = await sendCommand(['ACL', 'DRYRUN', username, command, ...args]);
    return Decoders.string(res);
  }

  Future<Map<String, dynamic>> aclGetUser(String username) async {
    final res = await sendCommand(['ACL', 'GETUSER', username]);
    return _serverReplyAsMap(res);
  }

  Future<String> aclWhoAmI() async {
    final res = await sendCommand(['ACL', 'WHOAMI']);
    return Decoders.string(res);
  }

  Future<String> aclGenPass([int? bits]) async {
    final args = <dynamic>['ACL', 'GENPASS'];
    if (bits != null) args.add(bits);
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<dynamic> aclLog([int? count]) {
    final args = <dynamic>['ACL', 'LOG'];
    if (count != null) args.add(count);
    return sendCommand(args);
  }

  Future<List<dynamic>> aclLogEntries([int? count]) async {
    final res = await aclLog(count);
    if (res is List) {
      return res.map(_normalizeServerReply).toList();
    }
    return [];
  }

  Future<String> aclLogReset() async {
    final res = await sendCommand(['ACL', 'LOG', 'RESET']);
    return Decoders.string(res);
  }
}

mixin RedisTransactionCommands on RedisTransactionSession {
  Future<String> watch(List<String> keys) async {
    final res = await sendCommand(['WATCH', ...keys]);
    return Decoders.string(res);
  }

  Future<String> unwatch() async {
    final res = await sendCommand(['UNWATCH']);
    return Decoders.string(res);
  }

  Future<String> multi() async {
    final res = await sendCommand(['MULTI']);
    return Decoders.string(res);
  }

  Future<List<dynamic>?> exec() async {
    final res = await sendCommand(['EXEC']);
    if (res == null) return null;
    if (res is List) return res;
    throw DaredisProtocolException(
      'Unexpected EXEC response type: ${res.runtimeType}',
    );
  }

  Future<String> discard() async {
    final res = await sendCommand(['DISCARD']);
    return Decoders.string(res);
  }
}
