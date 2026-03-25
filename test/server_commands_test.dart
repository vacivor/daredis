import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

class _FakeServerExecutor extends RedisCommandExecutor with RedisServerCommands {
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
      final executor = _FakeServerExecutor()..response = 'OK';

      final result = await executor.slaveOf('127.0.0.1', 6379);

      expect(result, 'OK');
      expect(executor.lastCommand, ['REPLICAOF', '127.0.0.1', 6379]);
    });

    test('slaveOf null target maps to REPLICAOF NO ONE', () async {
      final executor = _FakeServerExecutor()..response = 'OK';

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

    test('moduleLoad builds MODULE LOAD', () async {
      final executor = _FakeServerExecutor()..response = 'OK';

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
      final executor = _FakeServerExecutor()..response = 'OK';

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
      final executor = _FakeServerExecutor()..response = 'OK';

      final result = await executor.moduleUnload('search');

      expect(result, 'OK');
      expect(executor.lastCommand, ['MODULE', 'UNLOAD', 'search']);
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

      expect(await executor.aclLoad(), 'OK');
      expect(executor.lastCommand, ['ACL', 'LOAD']);

      expect(await executor.aclSave(), 'OK');
      expect(executor.lastCommand, ['ACL', 'SAVE']);
    });
  });
}
