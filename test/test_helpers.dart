import 'dart:io';
import 'dart:math';

import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

const standaloneHost = '192.168.50.144';
const standalonePort = 6379;
const clusterHost = '192.168.50.145';
const clusterPort = 7000;
const integrationTestTimeout = Timeout(Duration(seconds: 20));

String testKey(String prefix) {
  final now = DateTime.now().microsecondsSinceEpoch;
  final suffix = Random().nextInt(1 << 32);
  return 'daredis:test:$prefix:$now:$suffix';
}

Future<void> deleteKeys(
  RedisCommandExecutor client,
  Iterable<String> keys,
) async {
  final existing = keys.where((key) => key.isNotEmpty).toList(growable: false);
  if (existing.isEmpty) return;
  await client.del(existing);
}

Future<bool> isReachable(String host, int port) async {
  Socket? socket;
  try {
    socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 1),
    );
    return true;
  } catch (_) {
    return false;
  } finally {
    await socket?.close();
  }
}

Future<List<String>> scanAllMatches(
  RedisCommandExecutor client,
  String pattern,
) async {
  final matches = <String>{};
  var cursor = 0;

  do {
    final result = await client.scan(cursor, match: pattern, count: 50);
    matches.addAll(result.items);
    cursor = result.cursor;
  } while (cursor != 0);

  return matches.toList(growable: false);
}
