import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

class _FakeClusterClient extends RedisClusterClient with RedisClusterCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  bool get isClosed => false;

  @override
  bool get isConnected => true;

  @override
  Future<void> close() async {}

  @override
  Future<void> connect() async {}

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

void main() {
  group('RedisClusterCommands', () {
    test('asking builds ASKING', () async {
      final client = _FakeClusterClient()..response = 'OK';

      final result = await client.asking();

      expect(result, 'OK');
      expect(client.lastCommand, ['ASKING']);
    });

    test('restoreAsking builds RESTORE-ASKING with modifiers', () async {
      final client = _FakeClusterClient()..response = 'OK';

      final result = await client.restoreAsking(
        'user:{1}',
        5000,
        'serialized',
        replace: true,
        absTtl: true,
        idleTimeSeconds: 12,
        frequency: 3,
      );

      expect(result, 'OK');
      expect(client.lastCommand, [
        'RESTORE-ASKING',
        'user:{1}',
        5000,
        'serialized',
        'REPLACE',
        'ABSTTL',
        'IDLETIME',
        12,
        'FREQ',
        3,
      ]);
    });

    test('cluster range helpers build exact commands', () async {
      final client = _FakeClusterClient()..response = 'OK';

      expect(
        await client.clusterAddSlotsRange([
          const ClusterSlotAssignmentRange(0, 100),
          const ClusterSlotAssignmentRange(200, 300),
        ]),
        'OK',
      );
      expect(client.lastCommand, [
        'CLUSTER',
        'ADDSLOTSRANGE',
        0,
        100,
        200,
        300,
      ]);

      expect(
        await client.clusterDelSlotsRange([
          const ClusterSlotAssignmentRange(5, 10),
        ]),
        'OK',
      );
      expect(client.lastCommand, ['CLUSTER', 'DELSLOTSRANGE', 5, 10]);
    });

    test('cluster simple admin helpers build exact commands', () async {
      final client = _FakeClusterClient()..response = 'BUMPED';

      expect(await client.clusterBumpEpoch(), 'BUMPED');
      expect(client.lastCommand, ['CLUSTER', 'BUMPEPOCH']);

      client.response = 2;
      expect(await client.clusterCountFailureReports('node-1'), 2);
      expect(client.lastCommand, ['CLUSTER', 'COUNT-FAILURE-REPORTS', 'node-1']);

      client.response = 'OK';
      expect(await client.clusterFlushSlots(), 'OK');
      expect(client.lastCommand, ['CLUSTER', 'FLUSHSLOTS']);

      expect(await client.clusterSaveConfig(), 'OK');
      expect(client.lastCommand, ['CLUSTER', 'SAVECONFIG']);

      client.response = 'shard-1';
      expect(await client.clusterMyShardId(), 'shard-1');
      expect(client.lastCommand, ['CLUSTER', 'MYSHARDID']);
    });

    test('cluster topology readers decode replicas, slaves, links and shards', () async {
      final client = _FakeClusterClient()
        ..response = [
          'id-1 127.0.0.1:7001@17001 slave id-0 0 0 1 connected',
          'id-2 127.0.0.1:7002@17002 slave id-0 0 0 2 connected',
        ];

      expect(
        await client.clusterReplicas('id-0'),
        [
          'id-1 127.0.0.1:7001@17001 slave id-0 0 0 1 connected',
          'id-2 127.0.0.1:7002@17002 slave id-0 0 0 2 connected',
        ],
      );
      expect(client.lastCommand, ['CLUSTER', 'REPLICAS', 'id-0']);

      expect(
        await client.clusterSlaves('id-0'),
        [
          'id-1 127.0.0.1:7001@17001 slave id-0 0 0 1 connected',
          'id-2 127.0.0.1:7002@17002 slave id-0 0 0 2 connected',
        ],
      );
      expect(client.lastCommand, ['CLUSTER', 'SLAVES', 'id-0']);

      client.response = [
        ['direction', 'to', 'node', 'id-1', 'create-time', 123],
      ];
      expect(
        await client.clusterLinks(),
        [
          {'direction': 'to', 'node': 'id-1', 'create-time': 123},
        ],
      );
      expect(client.lastCommand, ['CLUSTER', 'LINKS']);

      client.response = [
        [
          'slots',
          [
            [0, 8191],
          ],
          'nodes',
          [
            ['id', 'id-0', 'endpoint', '127.0.0.1', 'port', 7000],
          ],
        ],
      ];
      expect(
        await client.clusterShards(),
        [
          {
            'slots': [
              [0, 8191],
            ],
            'nodes': [
              {'id': 'id-0', 'endpoint': '127.0.0.1', 'port': 7000},
            ],
          },
        ],
      );
      expect(client.lastCommand, ['CLUSTER', 'SHARDS']);
    });

    test('cluster migration helpers build exact command branches', () async {
      final client = _FakeClusterClient()..response = 'OK';

      expect(
        await client.clusterMigrationImport([
          const ClusterSlotAssignmentRange(0, 100),
          const ClusterSlotAssignmentRange(200, 300),
        ]),
        'OK',
      );
      expect(client.lastCommand, [
        'CLUSTER',
        'MIGRATION',
        'IMPORT',
        0,
        100,
        200,
        300,
      ]);

      expect(
        await client.clusterMigrationCancel(taskId: 'task-1'),
        'OK',
      );
      expect(client.lastCommand, ['CLUSTER', 'MIGRATION', 'CANCEL', 'ID', 'task-1']);

      expect(await client.clusterMigrationCancel(all: true), 'OK');
      expect(client.lastCommand, ['CLUSTER', 'MIGRATION', 'CANCEL', 'ALL']);

      client.response = [
        ['id', 'task-1', 'state', 'running'],
      ];
      expect(
        await client.clusterMigrationStatus(taskId: 'task-1'),
        [
          ['id', 'task-1', 'state', 'running'],
        ],
      );
      expect(client.lastCommand, ['CLUSTER', 'MIGRATION', 'STATUS', 'ID', 'task-1']);

      expect(await client.clusterMigrationStatus(all: true), [
        ['id', 'task-1', 'state', 'running'],
      ]);
      expect(client.lastCommand, ['CLUSTER', 'MIGRATION', 'STATUS', 'ALL']);
    });

    test('cluster slot stats helpers build exact command branches', () async {
      final client = _FakeClusterClient()
        ..response = [
          ['slot', 1, 'cpu-usec', 12],
        ];

      expect(
        await client.clusterSlotStatsSlotsRange(0, 100),
        [
          {'slot': 1, 'cpu-usec': 12},
        ],
      );
      expect(client.lastCommand, ['CLUSTER', 'SLOT-STATS', 'SLOTSRANGE', 0, 100]);

      expect(
        await client.clusterSlotStatsOrderBy(
          'cpu-usec',
          limit: 10,
          order: ClusterSlotStatsOrder.desc,
        ),
        [
          {'slot': 1, 'cpu-usec': 12},
        ],
      );
      expect(client.lastCommand, [
        'CLUSTER',
        'SLOT-STATS',
        'ORDERBY',
        'cpu-usec',
        'LIMIT',
        10,
        'DESC',
      ]);
    });

    test('cluster failover and config helpers build exact commands', () async {
      final client = _FakeClusterClient()..response = 'OK';

      expect(await client.clusterFailover(), 'OK');
      expect(client.lastCommand, ['CLUSTER', 'FAILOVER']);

      expect(
        await client.clusterFailover(mode: ClusterFailoverMode.force),
        'OK',
      );
      expect(client.lastCommand, ['CLUSTER', 'FAILOVER', 'FORCE']);

      expect(
        await client.clusterFailover(mode: ClusterFailoverMode.takeover),
        'OK',
      );
      expect(client.lastCommand, ['CLUSTER', 'FAILOVER', 'TAKEOVER']);

      expect(await client.clusterSetConfigEpoch(42), 'OK');
      expect(client.lastCommand, ['CLUSTER', 'SET-CONFIG-EPOCH', 42]);
    });

    test('cluster setslot helpers build exact commands', () async {
      final client = _FakeClusterClient()..response = 'OK';

      expect(await client.clusterSetSlotStable(7), 'OK');
      expect(client.lastCommand, ['CLUSTER', 'SETSLOT', 7, 'STABLE']);

      expect(await client.clusterSetSlotImporting(7, 'node-a'), 'OK');
      expect(client.lastCommand, [
        'CLUSTER',
        'SETSLOT',
        7,
        'IMPORTING',
        'node-a',
      ]);

      expect(await client.clusterSetSlotMigrating(7, 'node-b'), 'OK');
      expect(client.lastCommand, [
        'CLUSTER',
        'SETSLOT',
        7,
        'MIGRATING',
        'node-b',
      ]);

      expect(await client.clusterSetSlotNode(7, 'node-c'), 'OK');
      expect(client.lastCommand, ['CLUSTER', 'SETSLOT', 7, 'NODE', 'node-c']);
    });
  });
}
