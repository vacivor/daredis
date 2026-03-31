import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

class _FakeServerExecutor extends RedisCommandExecutor
    with RedisServerCommands, RedisServerIntrospectionCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

class _FakeAdminExecutor extends RedisCommandExecutor with RedisAdminCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

class _FakeDedicatedConnectionExecutor extends RedisCommandExecutor
    with RedisDedicatedConnectionCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

class _FakeStandaloneConnectionExecutor extends RedisCommandExecutor
    with RedisStandaloneConnectionCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

void main() {
  group('RedisServerCommands', () {
    test('auth builds AUTH with password only', () async {
      final executor = _FakeServerExecutor()..response = 'OK';

      final result = await executor.auth('secret');

      expect(result, 'OK');
      expect(executor.lastCommand, ['AUTH', 'secret']);
    });

    test('auth builds AUTH with username and password', () async {
      final executor = _FakeServerExecutor()..response = 'OK';

      final result = await executor.auth('secret', username: 'default');

      expect(result, 'OK');
      expect(executor.lastCommand, ['AUTH', 'default', 'secret']);
    });

    test('hello builds HELLO with AUTH and SETNAME', () async {
      final executor = _FakeServerExecutor()
        ..response = [
          'server',
          'redis',
          'version',
          '8.0.0',
          'proto',
          3,
        ];

      final result = await executor.hello(
        protocolVersion: 3,
        username: 'default',
        password: 'secret',
        clientName: 'daredis-test',
      );

      expect(result, {
        'server': 'redis',
        'version': '8.0.0',
        'proto': 3,
      });
      expect(executor.lastCommand, [
        'HELLO',
        3,
        'AUTH',
        'default',
        'secret',
        'SETNAME',
        'daredis-test',
      ]);
    });

    test('hello requires both username and password when using AUTH', () {
      final executor = _FakeServerExecutor();

      expect(
        () => executor.hello(username: 'default'),
        throwsArgumentError,
      );
    });

    test('slaveOf delegates to SLAVEOF syntax', () async {
      final executor = _FakeAdminExecutor()..response = 'OK';

      final result = await executor.slaveOf('127.0.0.1', 6379);

      expect(result, 'OK');
      expect(executor.lastCommand, ['REPLICAOF', '127.0.0.1', 6379]);
    });

    test('slaveOf null target maps to REPLICAOF NO ONE', () async {
      final executor = _FakeAdminExecutor()..response = 'OK';

      final result = await executor.slaveOf(null, null);

      expect(result, 'OK');
      expect(executor.lastCommand, ['REPLICAOF', 'NO', 'ONE']);
    });

    test('moduleList normalizes module maps', () async {
      final executor = _FakeServerExecutor()
        ..response = [
          ['name', 'search', 'ver', 20400, 'path', '/tmp/search.so'],
          ['name', 'json', 'ver', 10000, 'path', '/tmp/json.so'],
        ];

      final result = await executor.moduleList();

      expect(result, [
        {'name': 'search', 'ver': 20400, 'path': '/tmp/search.so'},
        {'name': 'json', 'ver': 10000, 'path': '/tmp/json.so'},
      ]);
      expect(executor.lastCommand, ['MODULE', 'LIST']);
    });

    test('aclLogEntries preserves plain even-length string lists', () async {
      final executor = _FakeServerExecutor()
        ..response = [
          ['user', 'alice', 'reason', 'auth'],
        ];

      final result = await executor.aclLogEntries();

      expect(result, [
        ['user', 'alice', 'reason', 'auth'],
      ]);
      expect(executor.lastCommand, ['ACL', 'LOG']);
    });

    test('pfDebug builds PFDEBUG with optional key and args', () async {
      final executor = _FakeAdminExecutor()..response = ['encoding', 'sparse'];

      final result = await executor.pfDebug(
        'GETREG',
        key: 'hll:{1}',
        args: [0],
      );

      expect(result, ['encoding', 'sparse']);
      expect(executor.lastCommand, ['PFDEBUG', 'GETREG', 'hll:{1}', 0]);
    });

    test('pfSelfTest builds PFSELFTEST', () async {
      final executor = _FakeAdminExecutor()..response = 'OK';

      final result = await executor.pfSelfTest();

      expect(result, 'OK');
      expect(executor.lastCommand, ['PFSELFTEST']);
    });

    test('wait helpers build dedicated connection commands', () async {
      final executor = _FakeDedicatedConnectionExecutor()..response = 2;

      final wait = await executor.waitReplicas(2, 1000);
      expect(wait, 2);
      expect(executor.lastCommand, ['WAIT', 2, 1000]);

      executor.response = [1, 3];
      final waitAof = await executor.waitAof(1, 3, 500);
      expect(waitAof.localFsyncCount, 1);
      expect(waitAof.replicaFsyncCount, 3);
      expect(executor.lastCommand, ['WAITAOF', 1, 3, 500]);

      executor.response = 'RESET';
      final reset = await executor.resetConnection();
      expect(reset, 'RESET');
      expect(executor.lastCommand, ['RESET']);
    });

    test('selectDb builds SELECT on standalone dedicated connections', () async {
      final executor = _FakeStandaloneConnectionExecutor()..response = 'OK';

      final result = await executor.selectDb(3);

      expect(result, 'OK');
      expect(executor.lastCommand, ['SELECT', 3]);
    });

    test('moduleLoad builds MODULE LOAD', () async {
      final executor = _FakeAdminExecutor()..response = 'OK';

      final result = await executor.moduleLoad('/tmp/search.so', ['MAXDOCTABLESIZE', '10']);

      expect(result, 'OK');
      expect(executor.lastCommand, [
        'MODULE',
        'LOAD',
        '/tmp/search.so',
        'MAXDOCTABLESIZE',
        '10',
      ]);
    });

    test('moduleLoadEx builds MODULE LOADEX with configs and args', () async {
      final executor = _FakeAdminExecutor()..response = 'OK';

      final result = await executor.moduleLoadEx(
        '/tmp/search.so',
        configs: {'MAXDOCTABLESIZE': '10', 'TIMEOUT': '500'},
        args: ['EXTLOAD', 'foo'],
      );

      expect(result, 'OK');
      expect(executor.lastCommand, [
        'MODULE',
        'LOADEX',
        '/tmp/search.so',
        'CONFIG',
        'MAXDOCTABLESIZE',
        '10',
        'CONFIG',
        'TIMEOUT',
        '500',
        'ARGS',
        'EXTLOAD',
        'foo',
      ]);
    });

    test('moduleUnload builds MODULE UNLOAD', () async {
      final executor = _FakeAdminExecutor()..response = 'OK';

      final result = await executor.moduleUnload('search');

      expect(result, 'OK');
      expect(executor.lastCommand, ['MODULE', 'UNLOAD', 'search']);
    });

    test('background persistence helpers build exact commands', () async {
      final executor = _FakeAdminExecutor()
        ..response = 'Background append only file rewriting started';

      expect(
        await executor.bgRewriteAof(),
        'Background append only file rewriting started',
      );
      expect(executor.lastCommand, ['BGREWRITEAOF']);

      executor.response = 'Background saving scheduled';
      expect(await executor.bgSave(schedule: true), 'Background saving scheduled');
      expect(executor.lastCommand, ['BGSAVE', 'SCHEDULE']);

      executor.response = 'OK';
      expect(await executor.save(), 'OK');
      expect(executor.lastCommand, ['SAVE']);

      executor.response = 1710000000;
      expect(await executor.lastSave(), 1710000000);
      expect(executor.lastCommand, ['LASTSAVE']);
    });

    test('failover builds target timeout and force options', () async {
      final executor = _FakeAdminExecutor()..response = 'OK';

      final result = await executor.failover(
        targetHost: '127.0.0.1',
        targetPort: 6380,
        timeoutMs: 5000,
        force: true,
      );

      expect(result, 'OK');
      expect(executor.lastCommand, [
        'FAILOVER',
        'TO',
        '127.0.0.1',
        6380,
        'FORCE',
        'TIMEOUT',
        5000,
      ]);
    });

    test('failover validates abort and force constraints', () {
      final executor = _FakeAdminExecutor();

      expect(
        () => executor.failover(targetHost: '127.0.0.1'),
        throwsArgumentError,
      );
      expect(
        () => executor.failover(force: true, timeoutMs: 1000),
        throwsArgumentError,
      );
      expect(
        () => executor.failover(abort: true, timeoutMs: 1000),
        throwsArgumentError,
      );
    });

    test('hotkeys helpers build commands and normalize GET', () async {
      final executor = _FakeAdminExecutor()..response = 'OK';

      expect(
        await executor.hotKeysStart(
          metricsCount: 2,
          metrics: {HotKeysMetric.cpu, HotKeysMetric.net},
          count: 5,
          durationSeconds: 10,
          sampleRatio: 4,
          slots: [1, 2],
        ),
        'OK',
      );
      expect(executor.lastCommand, [
        'HOTKEYS',
        'START',
        'METRICS',
        2,
        'CPU',
        'NET',
        'COUNT',
        5,
        'DURATION',
        10,
        'SAMPLE',
        4,
        'SLOTS',
        2,
        1,
        2,
      ]);

      executor.response = [
        'tracking-active',
        0,
        'by-cpu-time-us',
        ['key-1', 5, 'key-2', 3],
      ];
      expect(await executor.hotKeysGet(), {
        'tracking-active': 0,
        'by-cpu-time-us': {'key-1': 5, 'key-2': 3},
      });
      expect(executor.lastCommand, ['HOTKEYS', 'GET']);

      executor.response = 'OK';
      expect(await executor.hotKeysStop(), 'OK');
      expect(executor.lastCommand, ['HOTKEYS', 'STOP']);

      expect(await executor.hotKeysReset(), 'OK');
      expect(executor.lastCommand, ['HOTKEYS', 'RESET']);
    });

    test('hotkeys start requires at least one metric', () {
      final executor = _FakeAdminExecutor();

      expect(
        () => executor.hotKeysStart(metricsCount: 1, metrics: {}),
        throwsArgumentError,
      );
    });

    test('lolwut builds VERSION and extra arguments', () async {
      final executor = _FakeAdminExecutor()..response = 'art';

      final result = await executor.lolWut(version: 6, arguments: [40, 20]);

      expect(result, 'art');
      expect(executor.lastCommand, ['LOLWUT', 'VERSION', 6, 40, 20]);
    });

    test('publish builds PUBLISH and decodes receiver count', () async {
      final executor = _FakeServerExecutor()..response = 2;

      final result = await executor.publish('news', 'hello');

      expect(result, 2);
      expect(executor.lastCommand, ['PUBLISH', 'news', 'hello']);
    });

    test('spublish builds SPUBLISH and decodes receiver count', () async {
      final executor = _FakeServerExecutor()..response = 1;

      final result = await executor.spublish('orders:{1}', 'ready');

      expect(result, 1);
      expect(executor.lastCommand, ['SPUBLISH', 'orders:{1}', 'ready']);
    });

    test('replication helpers build exact low-level commands', () async {
      final executor = _FakeAdminExecutor()..response = 'OK';

      expect(await executor.replConfListeningPort(6380), 'OK');
      expect(executor.lastCommand, ['REPLCONF', 'listening-port', 6380]);

      expect(await executor.replConfAck(42), 'OK');
      expect(executor.lastCommand, ['REPLCONF', 'ACK', 42]);

      expect(await executor.replConfCapabilities(['eof', 'psync2']), 'OK');
      expect(executor.lastCommand, [
        'REPLCONF',
        'capa',
        'eof',
        'capa',
        'psync2',
      ]);

      executor.response = 'FULLRESYNC';
      expect(await executor.psync('replid', -1), 'FULLRESYNC');
      expect(executor.lastCommand, ['PSYNC', 'replid', -1]);

      executor.response = 'stream';
      expect(await executor.sync(), 'stream');
      expect(executor.lastCommand, ['SYNC']);
    });

    test('shutdown builds flags and validates abort exclusivity', () async {
      final executor = _FakeAdminExecutor()..response = 'OK';

      final result = await executor.shutdown(
        noSave: true,
        now: true,
        force: true,
      );

      expect(result, 'OK');
      expect(executor.lastCommand, ['SHUTDOWN', 'NOSAVE', 'NOW', 'FORCE']);

      expect(
        () => executor.shutdown(save: true, noSave: true),
        throwsArgumentError,
      );
      expect(
        () => executor.shutdown(abort: true, force: true),
        throwsArgumentError,
      );
    });

    test('swapDb builds SWAPDB', () async {
      final executor = _FakeAdminExecutor()..response = 'OK';

      final result = await executor.swapDb(0, 1);

      expect(result, 'OK');
      expect(executor.lastCommand, ['SWAPDB', 0, 1]);
    });

    test('memory malloc and purge helpers build exact commands', () async {
      final executor = _FakeServerExecutor()..response = 'jemalloc stats';

      expect(await executor.memoryMallocStats(), 'jemalloc stats');
      expect(executor.lastCommand, ['MEMORY', 'MALLOC-STATS']);

      executor.response = 'OK';
      expect(await executor.memoryPurge(), 'OK');
      expect(executor.lastCommand, ['MEMORY', 'PURGE']);
    });

    test('latency helpers build commands and decode replies', () async {
      final executor = _FakeServerExecutor()..response = 'report';
      expect(await executor.latencyDoctor(), 'report');
      expect(executor.lastCommand, ['LATENCY', 'DOCTOR']);

      executor.response = 'graph';
      expect(await executor.latencyGraph('command'), 'graph');
      expect(executor.lastCommand, ['LATENCY', 'GRAPH', 'command']);

      executor.response = 2;
      expect(await executor.latencyReset(['command', 'fork']), 2);
      expect(executor.lastCommand, ['LATENCY', 'RESET', 'command', 'fork']);
    });

    test('latencyHistogram normalizes histogram map', () async {
      final executor = _FakeServerExecutor()
        ..response = [
          'set',
          ['calls', 10, 'histogram_usec', ['1', 2, '2', 3]],
          'get',
          ['calls', 5, 'histogram_usec', ['1', 1]],
        ];

      final result = await executor.latencyHistogram(['SET', 'GET']);

      expect(result, {
        'set': {'calls': 10, 'histogram_usec': {'1': 2, '2': 3}},
        'get': {'calls': 5, 'histogram_usec': {'1': 1}},
      });
      expect(executor.lastCommand, ['LATENCY', 'HISTOGRAM', 'SET', 'GET']);
    });

    test('latencyHistory decodes timestamp-latency samples', () async {
      final executor = _FakeServerExecutor()
        ..response = [
          [1710000000, 5],
          [1710000060, 9],
        ];

      final result = await executor.latencyHistory('command');

      expect(
        result
            .map((sample) => [sample.timestamp, sample.latencyMilliseconds])
            .toList(),
        [
          [1710000000, 5],
          [1710000060, 9],
        ],
      );
      expect(executor.lastCommand, ['LATENCY', 'HISTORY', 'command']);
    });

    test('latencyLatest decodes latest event samples', () async {
      final executor = _FakeServerExecutor()
        ..response = [
          ['command', 1710000000, 5, 12],
          ['fork', 1710000100, 8, 20],
        ];

      final result = await executor.latencyLatest();

      expect(
        result
            .map(
              (event) => [
                event.event,
                event.timestamp,
                event.latestLatencyMilliseconds,
                event.maxLatencyMilliseconds,
              ],
            )
            .toList(),
        [
          ['command', 1710000000, 5, 12],
          ['fork', 1710000100, 8, 20],
        ],
      );
      expect(executor.lastCommand, ['LATENCY', 'LATEST']);
    });

    test('acl family exact helpers build precise commands', () async {
      final executor = _FakeServerExecutor()..response = ['@read', '@write'];

      expect(await executor.aclCat(), ['@read', '@write']);
      expect(executor.lastCommand, ['ACL', 'CAT']);

      executor.response = ['GET', 'MGET'];
      expect(await executor.aclCat('@read'), ['GET', 'MGET']);
      expect(executor.lastCommand, ['ACL', 'CAT', '@read']);

      executor.response = 'OK';
      expect(
        await executor.aclDryRun('alice', 'SET', ['key', 'value']),
        'OK',
      );
      expect(executor.lastCommand, [
        'ACL',
        'DRYRUN',
        'alice',
        'SET',
        'key',
        'value',
      ]);

      final admin = _FakeAdminExecutor()..response = 'OK';
      expect(await admin.aclLoad(), 'OK');
      expect(admin.lastCommand, ['ACL', 'LOAD']);

      admin.response = 'OK';
      expect(await admin.aclSave(), 'OK');
      expect(admin.lastCommand, ['ACL', 'SAVE']);
    });
  });
}
