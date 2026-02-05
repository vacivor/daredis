part of '../../daredis.dart';

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

  Future<dynamic> clientTrackingInfo() =>
      sendCommand(['CLIENT', 'TRACKINGINFO']);

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

  Future<dynamic> commandDocs([List<String>? commands]) {
    return sendCommand(['COMMAND', 'DOCS', if (commands != null) ...commands]);
  }

  Future<dynamic> commandInfo([List<String>? commands]) {
    return sendCommand(['COMMAND', 'INFO', if (commands != null) ...commands]);
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

  Future<dynamic> memoryStats() => sendCommand(['MEMORY', 'STATS']);

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

  Future<String> functionDelete(String libraryName) async {
    final res = await sendCommand(['FUNCTION', 'DELETE', libraryName]);
    return Decoders.string(res);
  }

  Future<dynamic> functionList({String? libraryName, bool withCode = false}) {
    final args = ['FUNCTION', 'LIST'];
    if (libraryName != null) args.addAll(['LIBRARYNAME', libraryName]);
    if (withCode) args.add('WITHCODE');
    return sendCommand(args);
  }

  Future<dynamic> functionStats() => sendCommand(['FUNCTION', 'STATS']);

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

  Future<dynamic> aclGetUser(String username) {
    return sendCommand(['ACL', 'GETUSER', username]);
  }

  Future<String> aclSetUser(List<dynamic> args) async {
    final res = await sendCommand(['ACL', 'SETUSER', ...args]);
    return Decoders.string(res);
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
}
