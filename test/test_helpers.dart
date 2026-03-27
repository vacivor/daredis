import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

const standaloneHost = '10.10.1.144';
const standalonePort = 6379;
const clusterHost = '10.10.1.145';
const clusterPort = 7000;
const integrationTestTimeout = Timeout(Duration(seconds: 20));

bool skipIfUnavailable(bool available, String message) {
  if (!available) {
    markTestSkipped(message);
    return true;
  }
  return false;
}

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
  for (final key in existing) {
    await client.sendCommand(['DEL', key]);
  }
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
    final result = await client.sendCommand([
      'SCAN',
      cursor,
      'MATCH',
      pattern,
      'COUNT',
      50,
    ]);
    if (result is List && result.length == 2 && result[1] is List) {
      final nextCursor = result[0];
      cursor = nextCursor is Uint8List
          ? int.parse(String.fromCharCodes(nextCursor))
          : int.parse(nextCursor.toString());
      matches.addAll(
        (result[1] as List).map(
          (item) => item is Uint8List
              ? String.fromCharCodes(item)
              : item.toString(),
        ),
      );
    } else {
      cursor = 0;
    }
  } while (cursor != 0);

  return matches.toList(growable: false);
}
