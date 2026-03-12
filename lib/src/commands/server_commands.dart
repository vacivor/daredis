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
      flags.addAll((reply[2] as List).map((value) => value.toString()));
    }

    final categories = <String>[];
    if (reply.length > 6 && reply[6] is List) {
      categories.addAll((reply[6] as List).map((value) => value.toString()));
    }

    final tips = <String>[];
    if (reply.length > 7 && reply[7] is List) {
      tips.addAll((reply[7] as List).map((value) => value.toString()));
    }

    return RedisCommandInfoEntry(
      name: reply[0].toString(),
      arity: int.parse(reply[1].toString()),
      flags: flags,
      firstKey: reply.length > 3 ? int.parse(reply[3].toString()) : 0,
      lastKey: reply.length > 4 ? int.parse(reply[4].toString()) : 0,
      keyStep: reply.length > 5 ? int.parse(reply[5].toString()) : 0,
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
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString(),
      displayText: map['display_text']?.toString(),
      token: map['token']?.toString(),
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
      summary: map['summary']?.toString(),
      since: map['since']?.toString(),
      group: map['group']?.toString(),
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
        ? (map['flags'] as List).map((value) => value.toString()).toList()
        : const <String>[];
    return RedisFunctionDefinition(
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString(),
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
      libraryName: map['library_name']?.toString() ?? '',
      engine: map['engine']?.toString(),
      code: map['library_code']?.toString(),
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
              key.toString(),
              RedisFunctionEngineStats.fromReply(key.toString(), value),
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
      libraryName: map['library_name']?.toString(),
      functionName: map['name']?.toString(),
      command: map['command']?.toString(),
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
    final role = reply.first.toString();
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
            ? int.tryParse(reply[1].toString())
            : null,
        replicas: replicas,
        monitoredMasters: const [],
      );
    }
    if (role == 'slave' || role == 'replica') {
      return RedisRoleInfo(
        role: role,
        raw: List<dynamic>.from(reply),
        primaryHost: reply.length > 1 ? reply[1].toString() : null,
        primaryPort: reply.length > 2 ? int.tryParse(reply[2].toString()) : null,
        replicationState: reply.length > 3 ? reply[3].toString() : null,
        replicationOffset: reply.length > 4
            ? int.tryParse(reply[4].toString())
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
      monitoredMasters: reply.skip(1).map((value) => value.toString()).toList(),
    );
  }
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
      host: reply[0].toString(),
      port: int.parse(reply[1].toString()),
      offset: int.parse(reply[2].toString()),
    );
  }
}

dynamic _normalizeServerReply(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) =>
          MapEntry(key.toString(), _normalizeServerReply(nestedValue)),
    );
  }
  if (value is List) {
    final normalized = value.map(_normalizeServerReply).toList();
    final isPairList = normalized.length.isEven &&
        normalized
            .asMap()
            .entries
            .every((entry) => entry.key.isOdd || entry.value is! List);
    if (isPairList) {
      final map = <String, dynamic>{};
      for (var i = 0; i < normalized.length; i += 2) {
        map[normalized[i].toString()] = normalized[i + 1];
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
  final normalized = _normalizeServerReply(value);
  if (normalized is List) {
    return normalized.map((item) {
      if (item is Map<String, dynamic>) {
        return item;
      }
      throw DaredisProtocolException(
        'Unexpected list item type: ${item.runtimeType}',
      );
    }).toList();
  }
  throw DaredisProtocolException(
    'Unexpected response type: ${value.runtimeType}',
  );
}

extension RedisServerCommands on RedisCommandExecutor {
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

  Future<String> configSet(String parameter, String value) async {
    final res = await sendCommand(['CONFIG', 'SET', parameter, value]);
    return Decoders.string(res);
  }

  Future<Map<String, String>> configGet(String parameter) async {
    final res = await sendCommand(['CONFIG', 'GET', parameter]);
    if (res is Map) {
      return res.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }
    if (res is List && res.length % 2 == 0) {
      final map = <String, String>{};
      for (var i = 0; i < res.length; i += 2) {
        map[res[i].toString()] = res[i + 1].toString();
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
      return [int.parse(res[0].toString()), int.parse(res[1].toString())];
    }
    return [];
  }

  Future<dynamic> debug(String subcommand, [String? argument]) {
    final args = ['DEBUG', subcommand];
    if (argument != null) args.add(argument);
    return sendCommand(args);
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

  Future<String> flushDb({bool? async}) async {
    final res = await sendCommand(['FLUSHDB', if (async == true) 'ASYNC']);
    return Decoders.string(res);
  }

  Future<String> flushAll({bool? async}) async {
    final res = await sendCommand(['FLUSHALL', if (async == true) 'ASYNC']);
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

  Future<Map<String, dynamic>> memoryStats() async {
    final res = await sendCommand(['MEMORY', 'STATS']);
    return _serverReplyAsMap(res);
  }

  Future<List<String>> pubSubChannels([String? pattern]) async {
    final args = ['PUBSUB', 'CHANNELS'];
    if (pattern != null) args.add(pattern);
    final res = await sendCommand(args);
    if (res is List) return res.map((e) => e.toString()).toList();
    return [];
  }

  Future<Map<String, int>> pubSubNumSub(List<String> channels) async {
    final res = await sendCommand(['PUBSUB', 'NUMSUB', ...channels]);
    if (res is List && res.length % 2 == 0) {
      final map = <String, int>{};
      for (var i = 0; i < res.length; i += 2) {
        map[res[i].toString()] = int.parse(res[i + 1].toString());
      }
      return map;
    }
    return {};
  }

  Future<int> pubSubNumPat() async {
    final res = await sendCommand(['PUBSUB', 'NUMPAT']);
    return Decoders.toInt(res);
  }

  Future<List<String>> pubSubShardChannels([String? pattern]) async {
    final args = ['PUBSUB', 'SHARDCHANNELS'];
    if (pattern != null) args.add(pattern);
    final res = await sendCommand(args);
    if (res is List) return res.map((e) => e.toString()).toList();
    return [];
  }

  Future<Map<String, int>> pubSubShardNumSub(List<String> channels) async {
    final res = await sendCommand(['PUBSUB', 'SHARDNUMSUB', ...channels]);
    if (res is List && res.length % 2 == 0) {
      final map = <String, int>{};
      for (var i = 0; i < res.length; i += 2) {
        map[res[i].toString()] = int.parse(res[i + 1].toString());
      }
      return map;
    }
    return {};
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

  Future<String> functionFlush({bool async = false}) async {
    final res = await sendCommand(['FUNCTION', 'FLUSH', if (async) 'ASYNC']);
    return Decoders.string(res);
  }

  Future<List<String>> aclList() async {
    final res = await sendCommand(['ACL', 'LIST']);
    if (res is List) return res.map((e) => e.toString()).toList();
    if (res is String) return res.split('\n');
    return [];
  }

  Future<List<String>> aclUsers() async {
    final res = await sendCommand(['ACL', 'USERS']);
    if (res is List) return res.map((e) => e.toString()).toList();
    return [];
  }

  Future<Map<String, dynamic>> aclGetUser(String username) async {
    final res = await sendCommand(['ACL', 'GETUSER', username]);
    return _serverReplyAsMap(res);
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
