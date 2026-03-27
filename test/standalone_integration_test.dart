import 'dart:convert';
import 'dart:typed_data';

import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

String _decodeText(dynamic value) {
  if (value is Uint8List) {
    return utf8.decode(value, allowMalformed: true);
  }
  return value.toString();
}

void main() {
  group('Standalone integration', () {
    late Daredis client;
    late bool available;

    setUpAll(() async {
      available = await isReachable(standaloneHost, standalonePort);
      if (!available) return;
      client = Daredis(
        options: const ConnectionOptions(
          host: standaloneHost,
          port: standalonePort,
        ),
      );
      await client.connect();
    });

    tearDownAll(() async {
      if (!available) return;
      await client.close();
    });

    test('ping set/get incr and hash commands work', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Standalone Redis is not reachable at $standaloneHost:$standalonePort',
      )) {
        return;
      }
      final stringKey = testKey('standalone:string');
      final counterKey = testKey('standalone:counter');
      final hashKey = testKey('standalone:hash');

      addTearDown(() => deleteKeys(client, [stringKey, counterKey, hashKey]));

      expect(await client.ping(), anyOf('PONG', 'OK'));
      expect(await client.set(stringKey, 'value-1'), isTrue);
      expect(await client.get(stringKey), 'value-1');
      expect(await client.incr(counterKey), 1);
      expect(await client.incr(counterKey), 2);
      expect(await client.hSet(hashKey, 'field-a', '1'), 1);
      expect(await client.hSet(hashKey, 'field-b', '2'), 1);
      expect(await client.hGetAll(hashKey), {'field-a': '1', 'field-b': '2'});
    });

    test('pipeline batches commands', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Standalone Redis is not reachable at $standaloneHost:$standalonePort',
      )) {
        return;
      }
      final key = testKey('standalone:pipeline');
      addTearDown(() => deleteKeys(client, [key]));

      expect(await client.set(key, 'ready'), isTrue);

      final pipeline = client.pipeline();
      pipeline.add(['PING']);
      pipeline.add(['ECHO', 'pipeline-ok']);
      pipeline.add(['GET', key]);

      final results = await pipeline.execute();
      expect(results[0], anyOf('PONG', 'OK'));
      expect(_decodeText(results[1]), 'pipeline-ok');
      expect(_decodeText(results[2]), 'ready');
    });

    test('pubsub receives published messages', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Standalone Redis is not reachable at $standaloneHost:$standalonePort',
      )) {
        return;
      }
      final channel = testKey('standalone:pubsub');
      final pubsub = await client.openPubSub(
        reconnectPolicy: const ReconnectPolicy(maxAttempts: 1),
      );
      addTearDown(() async => pubsub.close());

      await pubsub.subscribe([channel]);
      final messageFuture = pubsub.dataMessages.first;

      final receivers = await client.publish(channel, 'hello');
      final message = await messageFuture;

      expect(receivers, 1);
      expect(message.channel, channel);
      expect(message.payload, 'hello');
    });

    test('scan zset and stream commands work', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Standalone Redis is not reachable at $standaloneHost:$standalonePort',
      )) {
        return;
      }
      final scanKey = testKey('standalone:scan');
      final zsetKey = testKey('standalone:zset');
      final streamKey = testKey('standalone:stream');

      addTearDown(() => deleteKeys(client, [scanKey, zsetKey, streamKey]));

      expect(await client.set(scanKey, 'scan-value'), isTrue);
      final matches = await scanAllMatches(client, scanKey);
      expect(matches, contains(scanKey));

      expect(await client.zAdd(zsetKey, {'alice': 1.0, 'bob': 2.0, 'cara': 3.0}), 3);
      expect(await client.zRange(zsetKey, 0, -1), ['alice', 'bob', 'cara']);
      expect(await client.zScore(zsetKey, 'bob'), 2.0);

      final messageId = await client.xAdd(
        streamKey,
        fields: {'event': 'created', 'source': 'standalone'},
      );
      expect(messageId, isNotEmpty);
      expect(await client.xLen(streamKey), 1);
      final range = await client.xRange(streamKey, '-', '+');
      expect(range, hasLength(1));
      expect(range.first.fields, {'event': 'created', 'source': 'standalone'});
    });

    test('list set and scan helpers work', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Standalone Redis is not reachable at $standaloneHost:$standalonePort',
      )) {
        return;
      }
      final listKey = testKey('standalone:list');
      final setKey = testKey('standalone:set');
      final hashKey = testKey('standalone:hscan');

      addTearDown(() => deleteKeys(client, [listKey, setKey, hashKey]));

      expect(await client.rPush(listKey, ['a', 'b', 'c']), 3);
      expect(await client.lRange(listKey, 0, -1), ['a', 'b', 'c']);
      expect(await client.lPop(listKey), 'a');
      expect(await client.lLen(listKey), 2);

      expect(await client.sAdd(setKey, ['red', 'green', 'blue']), 3);
      expect(await client.sIsMember(setKey, 'green'), isTrue);
      expect(await client.sCard(setKey), 3);
      final sscan = await client.sScan(setKey, 0, count: 10);
      expect(sscan.items, containsAll(['red', 'green', 'blue']));

      expect(await client.hSet(hashKey, 'one', '1'), 1);
      expect(await client.hSet(hashKey, 'two', '2'), 1);
      final hscan = await client.hScan(hashKey, 0, count: 10);
      expect(
        hscan.items.map((entry) => entry.key),
        containsAll(['one', 'two']),
      );
    });

    test('multi exec and discard work', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Standalone Redis is not reachable at $standaloneHost:$standalonePort',
      )) {
        return;
      }
      final key = testKey('standalone:txn');
      final transaction = await client.openTransaction();
      addTearDown(() async => transaction.close());
      addTearDown(() => deleteKeys(client, [key]));

      expect(await transaction.multi(), 'OK');
      expect(
        _decodeText(await transaction.sendCommand(['SET', key, 'queued'])),
        'QUEUED',
      );
      expect(
        _decodeText(await transaction.sendCommand(['GET', key])),
        'QUEUED',
      );

      final results = await transaction.exec();
      expect(results, isNotNull);
      expect(results, hasLength(2));
      expect(results![0], anyOf('OK', true));
      expect(_decodeText(results[1]), 'queued');

      expect(await transaction.multi(), 'OK');
      expect(
        _decodeText(await transaction.sendCommand(['SET', key, 'discarded'])),
        'QUEUED',
      );
      expect(await transaction.discard(), 'OK');
      expect(await client.get(key), 'queued');
    });

    test('watch aborts exec after conflicting write', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Standalone Redis is not reachable at $standaloneHost:$standalonePort',
      )) {
        return;
      }
      final key = testKey('standalone:watch');
      final other = Daredis(
        options: const ConnectionOptions(
          host: standaloneHost,
          port: standalonePort,
        ),
      );
      final transaction = await client.openTransaction();

      addTearDown(() => deleteKeys(client, [key]));
      addTearDown(() async => other.close());
      addTearDown(() async => transaction.close());

      await other.connect();
      expect(await client.set(key, '1'), isTrue);

      expect(await transaction.watch([key]), 'OK');
      expect(await transaction.multi(), 'OK');
      expect(
        _decodeText(await transaction.sendCommand(['SET', key, '2'])),
        'QUEUED',
      );

      expect(await other.set(key, '99'), isTrue);

      final execResult = await transaction.exec();
      expect(execResult, isNull);
      expect(await client.get(key), '99');
      expect(await transaction.unwatch(), 'OK');
    });

    test('geo hyperloglog and scripting commands work', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Standalone Redis is not reachable at $standaloneHost:$standalonePort',
      )) {
        return;
      }
      const script = "return redis.call('GET', KEYS[1])";
      final geoKey = testKey('standalone:geo');
      final hllA = testKey('standalone:hll:a');
      final hllB = testKey('standalone:hll:b');
      final hllMerged = testKey('standalone:hll:merged');
      final scriptKey = testKey('standalone:script');

      addTearDown(() => deleteKeys(client, [geoKey, hllA, hllB, hllMerged, scriptKey]));

      expect(
        await client.geoAdd(geoKey, [
          GeoMember(13.361389, 38.115556, 'Palermo'),
          GeoMember(15.087269, 37.502669, 'Catania'),
        ]),
        2,
      );
      final distance = await client.geoDist(geoKey, 'Palermo', 'Catania', unit: 'km');
      expect(distance, isNotNull);
      expect(distance!, greaterThan(100));
      final hashes = await client.geoHash(geoKey, ['Palermo']);
      expect(hashes.single, isNotEmpty);
      final positions = await client.geoPos(geoKey, ['Palermo']);
      expect(positions.single, isNotNull);
      final nearby = await client.geoRadiusByMember(
        geoKey,
        'Palermo',
        200,
        'km',
        withDist: true,
        asc: true,
      );
      expect(nearby.map((entry) => entry.member), containsAll(['Palermo', 'Catania']));

      expect(await client.pfAdd(hllA, ['a', 'b', 'c']), 1);
      expect(await client.pfAdd(hllB, ['c', 'd']), 1);
      expect(await client.pfCount(hllA), 3);
      expect(await client.pfMerge(hllMerged, [hllA, hllB]), 'OK');
      expect(await client.pfCount(hllMerged), greaterThanOrEqualTo(4));

      expect(await client.set(scriptKey, 'script-value'), isTrue);
      final sha = await client.scriptLoad(script);
      expect(sha, isNotEmpty);
      expect(await client.scriptExists([sha]), [true]);
      expect(
        _decodeText(await client.eval(script, 1, [scriptKey], const [])),
        'script-value',
      );
      expect(
        _decodeText(await client.evalSha(sha, 1, [scriptKey], const [])),
        'script-value',
      );
      expect(
        await client.evalString(script, 1, [scriptKey], const []),
        'script-value',
      );
      expect(
        await client.evalShaString(sha, 1, [scriptKey], const []),
        'script-value',
      );
      expect(
        await client.evalInt('return 42', 0, const [], const []),
        42,
      );
      expect(
        await client.evalShaInt(
          await client.scriptLoad('return 7'),
          0,
          const [],
          const [],
        ),
        7,
      );
      expect(
        await client.evalListString(
          "return {'a','b','c'}",
          0,
          const [],
          const [],
        ),
        ['a', 'b', 'c'],
      );
      expect(
        await client.evalRoString(script, 1, [scriptKey], const []),
        'script-value',
      );
      expect(
        await client.evalShaRoString(
          await client.scriptLoad(script),
          1,
          [scriptKey],
          const [],
        ),
        'script-value',
      );
      expect(
        await client.evalRoInt('return 9', 0, const [], const []),
        9,
      );
      expect(
        await client.evalShaRoListString(
          await client.scriptLoad("return {'x','y'}"),
          0,
          const [],
          const [],
        ),
        ['x', 'y'],
      );
    });

    test('stream group helpers work', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Standalone Redis is not reachable at $standaloneHost:$standalonePort',
      )) {
        return;
      }
      final streamKey = testKey('standalone:stream-group');
      addTearDown(() => deleteKeys(client, [streamKey]));

      expect(
        await client.xGroupCreate(streamKey, 'group-a', r'$', mkStream: true),
        'OK',
      );
      expect(await client.xGroupCreateConsumer(streamKey, 'group-a', 'consumer-a'), 1);

      final groups = await client.xInfoGroups(streamKey);
      expect(groups, isNotEmpty);
      final streamInfo = await client.xInfoStreamEntry(streamKey);
      expect(streamInfo.length, greaterThanOrEqualTo(0));
      final groupEntries = await client.xInfoGroupEntries(streamKey);
      expect(groupEntries, hasLength(1));
      expect(groupEntries.first.name, 'group-a');
      expect(groupEntries.first.consumers, 1);

      expect(await client.xAdd(streamKey, fields: {'event': 'created'}), isNotEmpty);
      expect(await client.xGroupSetId(streamKey, 'group-a', '0-0'), 'OK');

      final consumers = await client.xInfoConsumers(streamKey, 'group-a');
      expect(consumers, isNotEmpty);
      final consumerEntries = await client.xInfoConsumerEntries(
        streamKey,
        'group-a',
      );
      expect(consumerEntries, hasLength(1));
      expect(consumerEntries.first.name, 'consumer-a');

      expect(await client.xGroupDelConsumer(streamKey, 'group-a', 'consumer-a'), 0);
      expect(await client.xGroupDestroy(streamKey, 'group-a'), 1);
    });

    test('server metadata commands return sane values', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Standalone Redis is not reachable at $standaloneHost:$standalonePort',
      )) {
        return;
      }

      final info = await client.info('server');
      expect(info, contains('redis_version'));
      expect(await client.clientId(), greaterThan(0));

      final dbSize = await client.dbSize();
      expect(dbSize, greaterThanOrEqualTo(0));
      final role = await client.roleInfo();
      expect(role.role, isNotEmpty);
      if (role.role == 'master') {
        expect(role.replicationOffset, isNotNull);
      }
    });

    test('server helper APIs are usable', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Standalone Redis is not reachable at $standaloneHost:$standalonePort',
      )) {
        return;
      }

      expect(await client.clientTrackingOn(), 'OK');
      final trackingInfo = await client.clientTrackingInfo();
      expect(trackingInfo.containsKey('flags'), isTrue);
      expect(await client.clientTrackingOff(), 'OK');

      final docs = await client.commandDocsFor(['GET']);
      expect(docs.containsKey('get'), isTrue);
      final docEntries = await client.commandDocEntriesFor(['GET']);
      expect(docEntries, hasLength(1));
      expect(docEntries.first.name, 'get');
      expect(docEntries.first.summary, isNotEmpty);
      expect(docEntries.first.arguments, isNotEmpty);
      expect(docEntries.first.arguments.first.name, isNotEmpty);
      expect(docEntries.first.arguments.first.type, isNotEmpty);

      final setDocs = await client.commandDocEntriesFor(['SET']);
      expect(setDocs, hasLength(1));
      expect(setDocs.first.arguments, isNotEmpty);
      expect(
        setDocs.first.arguments.any((argument) => argument.arguments.isNotEmpty),
        isA<bool>(),
      );

      final info = await client.commandInfoFor(['GET']);
      expect(info, isNotEmpty);
      expect(info.first, isA<List<dynamic>>());
      expect(_decodeText((info.first as List).first).toLowerCase(), 'get');

      final entries = await client.commandInfoEntriesFor(['GET']);
      expect(entries, hasLength(1));
      expect(entries.first.name, 'get');
      expect(entries.first.arity, greaterThan(0));
      expect(entries.first.flags, contains('readonly'));
      expect(entries.first.firstKey, 1);
      expect(entries.first.categories, contains('@read'));
      expect(entries.first.tips, isA<List<String>>());
      expect(entries.first.keySpecifications, isA<List<dynamic>>());
    });

    test('acl and function helper APIs are usable', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Standalone Redis is not reachable at $standaloneHost:$standalonePort',
      )) {
        return;
      }

      final libraryName = 'daredislib${DateTime.now().microsecondsSinceEpoch}';
      final functionCode =
          '#!lua name=$libraryName\n'
          'redis.register_function(\'echo_value\', function(keys, args)\n'
          '  return redis.call(\'GET\', keys[1])\n'
          'end)\n';

      addTearDown(() async {
        try {
          await client.sendCommand(['FUNCTION', 'DELETE', libraryName]);
        } catch (_) {}
      });

      expect(await client.aclWhoAmI(), isNotEmpty);
      expect(await client.aclGenPass(), isNotEmpty);
      expect(await client.aclLogEntries(1), isA<List<dynamic>>());
      final currentUser = await client.aclGetUser(await client.aclWhoAmI());
      expect(currentUser, isNotEmpty);
      expect(await client.aclLogReset(), 'OK');

      final loaded = await client.sendCommand([
        'FUNCTION',
        'LOAD',
        'REPLACE',
        functionCode,
      ]);
      expect(_decodeText(loaded), contains(libraryName));

      final libraries = await client.functionListLibraries();
      expect(
        libraries.any((library) => library['library_name'] == libraryName),
        isTrue,
      );

      final libraryEntries = await client.functionLibraryEntries();
      final currentLibrary = libraryEntries.firstWhere(
        (library) => library.libraryName == libraryName,
      );
      expect(currentLibrary.engine, 'LUA');
      expect(currentLibrary.functions, isNotEmpty);
      expect(currentLibrary.functions.first.name, 'echo_value');

      final stats = await client.functionStats();
      expect(stats.containsKey('running_script'), isTrue);
      final typedStats = await client.functionStatsEntry();
      expect(typedStats.raw.containsKey('running_script'), isTrue);
      expect(typedStats.engines, isNotEmpty);
      final luaStats = typedStats.engines['LUA'];
      expect(luaStats, isNotNull);
      expect(luaStats!.raw, isNotEmpty);
      expect(luaStats.librariesCount, greaterThanOrEqualTo(1));
      expect(luaStats.functionsCount, greaterThanOrEqualTo(1));
    });
  });
}
