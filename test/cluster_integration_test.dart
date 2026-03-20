import 'package:daredis/daredis.dart';
import 'package:daredis/src/exceptions.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

void main() {
  group('Cluster integration', () {
    late DaredisCluster cluster;
    late bool available;

    setUpAll(() async {
      available = await isReachable(clusterHost, clusterPort);
      if (!available) return;
      cluster = DaredisCluster(
        options: const ClusterOptions(
          seeds: [ClusterNode(clusterHost, clusterPort)],
        ),
      );
      await cluster.connect();
    });

    tearDownAll(() async {
      if (!available) return;
      await cluster.close();
    });

    test('ping set/get incr and hash commands work', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Redis Cluster is not reachable at $clusterHost:$clusterPort',
      )) {
        return;
      }
      final tag = '{${testKey('cluster-slot')}}';
      final stringKey = 'daredis:test:cluster:string:$tag';
      final counterKey = 'daredis:test:cluster:counter:$tag';
      final hashKey = 'daredis:test:cluster:hash:$tag';

      addTearDown(() => deleteKeys(cluster, [stringKey, counterKey, hashKey]));

      expect(await cluster.ping(), anyOf('PONG', 'OK'));
      expect(await cluster.set(stringKey, 'value-1'), isTrue);
      expect(await cluster.get(stringKey), 'value-1');
      expect(await cluster.incr(counterKey), 1);
      expect(await cluster.hSet(hashKey, 'field-a', '1'), 1);
      expect(await cluster.hGet(hashKey, 'field-a'), '1');
    });

    test('pipeline executes commands in the same slot', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Redis Cluster is not reachable at $clusterHost:$clusterPort',
      )) {
        return;
      }
      final tag = '{${testKey('cluster-pipe')}}';
      final key = 'daredis:test:cluster:pipeline:$tag';
      addTearDown(() => deleteKeys(cluster, [key]));

      expect(await cluster.set(key, 'ready'), isTrue);

      final pipeline = cluster.pipeline();
      pipeline.add(['PING']);
      pipeline.add(['GET', key]);
      pipeline.add(['GET', key]);

      final results = await pipeline.execute();
      expect(results[0], anyOf('PONG', 'OK'));
      expect(results[1], 'ready');
      expect(results[2], 'ready');
    });

    test('pubsub receives published messages on the seed node', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Redis Cluster is not reachable at $clusterHost:$clusterPort',
      )) {
        return;
      }
      final channel = testKey('cluster:pubsub');
      final pubsub = await cluster.openPubSub();
      final publisher = Daredis(
        options: const ConnectionOptions(host: clusterHost, port: clusterPort),
      );
      addTearDown(() async => pubsub.close());
      addTearDown(() async => publisher.close());

      await publisher.connect();
      await pubsub.subscribe([channel]);
      final messageFuture = pubsub.dataMessages.first;

      final receivers = await publisher.sendCommand(['PUBLISH', channel, 'hello']);
      final message = await messageFuture;

      expect(receivers, 1);
      expect(message.channel, channel);
      expect(message.payload, 'hello');
    });

    test('zset and stream commands work in one slot', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Redis Cluster is not reachable at $clusterHost:$clusterPort',
      )) {
        return;
      }
      final tag = '{${testKey('cluster-data')}}';
      final zsetKey = 'daredis:test:cluster:zset:$tag';
      final streamKey = 'daredis:test:cluster:stream:$tag';

      addTearDown(() => deleteKeys(cluster, [zsetKey, streamKey]));

      expect(await cluster.zAdd(zsetKey, {'alice': 1.0, 'bob': 2.0, 'cara': 3.0}), 3);
      expect(await cluster.zRange(zsetKey, 0, -1), ['alice', 'bob', 'cara']);
      expect(await cluster.zScore(zsetKey, 'cara'), 3.0);
      final zscan = await cluster.zScan(zsetKey, 0, count: 10);
      expect(zscan.items.map((entry) => entry.key), containsAll(['alice', 'bob', 'cara']));

      final messageId = await cluster.xAdd(
        streamKey,
        fields: {'event': 'created', 'source': 'cluster'},
      );
      expect(messageId, isNotEmpty);
      expect(await cluster.xLen(streamKey), 1);
      final range = await cluster.xRange(streamKey, '-', '+');
      expect(range, hasLength(1));
      expect(range.first.fields, {'event': 'created', 'source': 'cluster'});
    });

    test('list set and hash scan work in one slot', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Redis Cluster is not reachable at $clusterHost:$clusterPort',
      )) {
        return;
      }
      final tag = '{${testKey('cluster-collections')}}';
      final listKey = 'daredis:test:cluster:list:$tag';
      final setKey = 'daredis:test:cluster:set:$tag';
      final hashKey = 'daredis:test:cluster:hash-scan:$tag';

      addTearDown(() => deleteKeys(cluster, [listKey, setKey, hashKey]));

      expect(await cluster.rPush(listKey, ['a', 'b', 'c']), 3);
      expect(await cluster.lRange(listKey, 0, -1), ['a', 'b', 'c']);
      expect(await cluster.lPop(listKey), 'a');
      expect(await cluster.lLen(listKey), 2);

      expect(await cluster.sAdd(setKey, ['red', 'green', 'blue']), 3);
      expect(await cluster.sIsMember(setKey, 'green'), isTrue);
      expect(await cluster.sCard(setKey), 3);
      final sscan = await cluster.sScan(setKey, 0, count: 10);
      expect(sscan.items, containsAll(['red', 'green', 'blue']));

      expect(await cluster.hSet(hashKey, 'one', '1'), 1);
      expect(await cluster.hSet(hashKey, 'two', '2'), 1);
      final hscan = await cluster.hScan(hashKey, 0, count: 10);
      expect(
        hscan.items.map((entry) => entry.key),
        containsAll(['one', 'two']),
      );
    });

    test('multi-key same-slot commands work', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Redis Cluster is not reachable at $clusterHost:$clusterPort',
      )) {
        return;
      }
      final tag = '{${testKey('cluster-multi')}}';
      final keyA = 'daredis:test:cluster:mget:a:$tag';
      final keyB = 'daredis:test:cluster:mget:b:$tag';
      final setA = 'daredis:test:cluster:sinter:a:$tag';
      final setB = 'daredis:test:cluster:sinter:b:$tag';
      final setDest = 'daredis:test:cluster:sinter:dest:$tag';
      final zsetA = 'daredis:test:cluster:zinter:a:$tag';
      final zsetB = 'daredis:test:cluster:zinter:b:$tag';
      final zsetDest = 'daredis:test:cluster:zinter:dest:$tag';

      addTearDown(() => deleteKeys(cluster, [
            keyA,
            keyB,
            setA,
            setB,
            setDest,
            zsetA,
            zsetB,
            zsetDest,
          ]));

      expect(await cluster.mSet({keyA: 'A', keyB: 'B'}), 'OK');
      expect(await cluster.mGet([keyA, keyB]), ['A', 'B']);

      expect(await cluster.sAdd(setA, ['red', 'green', 'blue']), 3);
      expect(await cluster.sAdd(setB, ['green', 'blue', 'yellow']), 3);
      expect(await cluster.sInter([setA, setB]), unorderedEquals(['green', 'blue']));
      expect(await cluster.sInterStore(setDest, [setA, setB]), 2);
      expect(await cluster.sMembers(setDest), unorderedEquals(['green', 'blue']));

      expect(await cluster.zAdd(zsetA, {'alice': 1.0, 'bob': 2.0, 'cara': 3.0}), 3);
      expect(await cluster.zAdd(zsetB, {'bob': 1.0, 'cara': 5.0, 'dave': 8.0}), 3);
      expect(await cluster.zInterStore(zsetDest, 2, [zsetA, zsetB]), 2);
      expect(await cluster.zRange(zsetDest, 0, -1, withScores: true), [
        'bob',
        '3',
        'cara',
        '8',
      ]);
    });

    test('cross-slot commands are rejected early', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Redis Cluster is not reachable at $clusterHost:$clusterPort',
      )) {
        return;
      }
      final keyA = 'daredis:test:cluster:cross-slot:a:{${testKey('slot-a')}}';
      final keyB = 'daredis:test:cluster:cross-slot:b:{${testKey('slot-b')}}';
      final setA = 'daredis:test:cluster:cross-slot:set-a:{${testKey('set-a')}}';
      final setB = 'daredis:test:cluster:cross-slot:set-b:{${testKey('set-b')}}';

      expect(
        () => cluster.mGet([keyA, keyB]),
        throwsA(isA<RespException>()),
      );
      expect(
        () => cluster.sInter([setA, setB]),
        throwsA(isA<RespException>()),
      );

      final pipeline = cluster.pipeline();
      pipeline.add(['MGET', keyA, keyB]);
      expect(
        () => pipeline.execute(),
        throwsA(isA<RespException>()),
      );
    });

    test('single-slot transactions can run on a pinned cluster node', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Redis Cluster is not reachable at $clusterHost:$clusterPort',
      )) {
        return;
      }
      final tag = '{${testKey('cluster-tx')}}';
      final keyA = 'daredis:test:cluster:tx:a:$tag';
      final keyB = 'daredis:test:cluster:tx:b:$tag';
      final crossSlotKey = 'daredis:test:cluster:tx:other:{${testKey('cluster-tx-other')}}';
      final tx = await cluster.openTransaction(keyA);

      addTearDown(() => deleteKeys(cluster, [keyA, keyB, crossSlotKey]));
      addTearDown(() async => tx.close());

      expect(
        () => tx.watch([keyA, keyB]),
        returnsNormally,
      );
      expect(await tx.watch([keyA, keyB]), 'OK');
      expect(await tx.multi(), 'OK');
      expect(await tx.sendCommand(['SET', keyA, '1']), 'QUEUED');
      expect(await tx.sendCommand(['SET', keyB, '2']), 'QUEUED');
      expect(
        () => tx.sendCommand(['MGET', keyA, crossSlotKey]),
        throwsA(isA<RespException>()),
      );
      final replies = await tx.exec();
      expect(replies, hasLength(2));
      expect(await cluster.mGet([keyA, keyB]), ['1', '2']);
    });

    test('cluster transaction routing key only selects the slot', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Redis Cluster is not reachable at $clusterHost:$clusterPort',
      )) {
        return;
      }
      final tag = '{${testKey('cluster-routing-key')}}';
      final routingKey = 'daredis:test:cluster:tx:routing:$tag';
      final actualKey = 'daredis:test:cluster:tx:actual:$tag';
      final tx = await cluster.openTransaction(routingKey);

      addTearDown(() => deleteKeys(cluster, [routingKey, actualKey]));
      addTearDown(() async => tx.close());

      expect(await tx.multi(), 'OK');
      expect(await tx.sendCommand(['SET', actualKey, 'value']), 'QUEUED');
      final replies = await tx.exec();

      expect(replies, hasLength(1));
      expect(await cluster.get(actualKey), 'value');
    });

    test('geo hyperloglog and scripting commands work in one slot', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Redis Cluster is not reachable at $clusterHost:$clusterPort',
      )) {
        return;
      }
      const script = "return redis.call('GET', KEYS[1])";
      final tag = '{${testKey('cluster-advanced')}}';
      final geoKey = 'daredis:test:cluster:geo:$tag';
      final hllA = 'daredis:test:cluster:hll:a:$tag';
      final hllB = 'daredis:test:cluster:hll:b:$tag';
      final hllMerged = 'daredis:test:cluster:hll:merged:$tag';
      final scriptKey = 'daredis:test:cluster:script:$tag';

      addTearDown(() => deleteKeys(cluster, [geoKey, hllA, hllB, hllMerged, scriptKey]));

      expect(
        await cluster.geoAdd(geoKey, [
          GeoMember(13.361389, 38.115556, 'Palermo'),
          GeoMember(15.087269, 37.502669, 'Catania'),
        ]),
        2,
      );
      final distance = await cluster.geoDist(geoKey, 'Palermo', 'Catania', unit: 'km');
      expect(distance, isNotNull);
      expect(distance!, greaterThan(100));
      final nearby = await cluster.geoRadiusByMember(
        geoKey,
        'Palermo',
        200,
        'km',
        withDist: true,
        asc: true,
      );
      expect(nearby.map((entry) => entry.member), containsAll(['Palermo', 'Catania']));

      expect(await cluster.pfAdd(hllA, ['a', 'b', 'c']), 1);
      expect(await cluster.pfAdd(hllB, ['c', 'd']), 1);
      expect(await cluster.pfMerge(hllMerged, [hllA, hllB]), 'OK');
      expect(await cluster.pfCount([hllA, hllB]), greaterThanOrEqualTo(4));
      expect(await cluster.pfCount(hllMerged), greaterThanOrEqualTo(4));

      expect(await cluster.set(scriptKey, 'script-value'), isTrue);
      final sha = await cluster.scriptLoad(script);
      expect(sha, isNotEmpty);
      expect(await cluster.scriptExists([sha]), [true]);
      expect(await cluster.eval(script, 1, [scriptKey], const []), 'script-value');
      expect(await cluster.evalSha(sha, 1, [scriptKey], const []), 'script-value');
      expect(
        await cluster.evalString(script, 1, [scriptKey], const []),
        'script-value',
      );
      expect(
        await cluster.evalShaString(sha, 1, [scriptKey], const []),
        'script-value',
      );
      expect(
        await cluster.evalInt('return 42', 0, const [], const []),
        42,
      );
      expect(
        await cluster.evalListString(
          "return {'a','b','c'}",
          0,
          const [],
          const [],
        ),
        ['a', 'b', 'c'],
      );
      expect(
        await cluster.evalRoString(script, 1, [scriptKey], const []),
        'script-value',
      );
      expect(
        await cluster.evalShaRoString(
          await cluster.scriptLoad(script),
          1,
          [scriptKey],
          const [],
        ),
        'script-value',
      );
      expect(
        await cluster.evalRoInt('return 9', 0, const [], const []),
        9,
      );
      expect(
        await cluster.evalShaRoListString(
          await cluster.scriptLoad("return {'x','y'}"),
          0,
          const [],
          const [],
        ),
        ['x', 'y'],
      );
    });

    test('stream group helpers work in one slot', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Redis Cluster is not reachable at $clusterHost:$clusterPort',
      )) {
        return;
      }
      final tag = '{${testKey('cluster-stream-group')}}';
      final streamKey = 'daredis:test:cluster:stream-group:$tag';
      addTearDown(() => deleteKeys(cluster, [streamKey]));

      expect(
        await cluster.xGroupCreate(streamKey, 'group-a', r'$', mkStream: true),
        'OK',
      );
      expect(await cluster.xGroupCreateConsumer(streamKey, 'group-a', 'consumer-a'), 1);

      final groups = await cluster.xInfoGroups(streamKey);
      expect(groups.toString(), contains('group-a'));
      final streamInfo = await cluster.xInfoStreamEntry(streamKey);
      expect(streamInfo.length, greaterThanOrEqualTo(0));
      final groupEntries = await cluster.xInfoGroupEntries(streamKey);
      expect(groupEntries, hasLength(1));
      expect(groupEntries.first.name, 'group-a');
      expect(groupEntries.first.consumers, 1);

      expect(await cluster.xAdd(streamKey, fields: {'event': 'created'}), isNotEmpty);
      expect(await cluster.xGroupSetId(streamKey, 'group-a', '0-0'), 'OK');

      final consumers = await cluster.xInfoConsumers(streamKey, 'group-a');
      expect(consumers.toString(), contains('consumer-a'));
      final consumerEntries = await cluster.xInfoConsumerEntries(
        streamKey,
        'group-a',
      );
      expect(consumerEntries, hasLength(1));
      expect(consumerEntries.first.name, 'consumer-a');

      expect(await cluster.xGroupDelConsumer(streamKey, 'group-a', 'consumer-a'), 0);
      expect(await cluster.xGroupDestroy(streamKey, 'group-a'), 1);
    });

    test('cluster metadata commands return sane values', timeout: integrationTestTimeout, () async {
      if (skipIfUnavailable(
        available,
        'Redis Cluster is not reachable at $clusterHost:$clusterPort',
      )) {
        return;
      }

      final info = await cluster.clusterInfo();
      expect(info.toLowerCase(), contains('cluster_state'));

      final nodeInfo = await cluster.clusterNodes();
      expect(nodeInfo, contains(clusterHost));

      final slot = await cluster.clusterKeyslot('daredis:test:slot:{meta}');
      expect(slot, inInclusiveRange(0, 16383));
      final slotRanges = await cluster.clusterSlotRanges();
      expect(slotRanges, isNotEmpty);
      expect(slotRanges.first.primary.host, isNotEmpty);
    });
  });
}
