import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

class _FakeJsonExecutor extends RedisCommandExecutor with RedisJsonCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

void main() {
  group('RedisJsonCommands', () {
    test('jsonGet builds JSON.GET with formatting options and paths', () async {
      final executor = _FakeJsonExecutor()..response = '{"name":"redis"}';

      final result = await executor.jsonGet(
        'doc:{1}',
        indent: '  ',
        newline: '\n',
        space: ' ',
        paths: [r'$.name', r'$.version'],
      );

      expect(result, '{"name":"redis"}');
      expect(executor.lastCommand, [
        'JSON.GET',
        'doc:{1}',
        'INDENT',
        '  ',
        'NEWLINE',
        '\n',
        'SPACE',
        ' ',
        r'$.name',
        r'$.version',
      ]);
    });

    test('jsonSet validates NX and XX exclusivity', () {
      final executor = _FakeJsonExecutor();

      expect(
        () => executor.jsonSet('doc:{1}', r'$', '{"name":"redis"}', nx: true, xx: true),
        throwsArgumentError,
      );
    });

    test('jsonSet builds JSON.SET with NX and nullable reply', () async {
      final executor = _FakeJsonExecutor()..response = 'OK';

      final result = await executor.jsonSet(
        'doc:{1}',
        r'$',
        '{"name":"redis"}',
        nx: true,
      );

      expect(result, 'OK');
      expect(executor.lastCommand, [
        'JSON.SET',
        'doc:{1}',
        r'$',
        '{"name":"redis"}',
        'NX',
      ]);
    });

    test('jsonMGet builds JSON.MGET and decodes bulk-string list', () async {
      final executor = _FakeJsonExecutor()
        ..response = ['{"name":"redis"}', null];

      final result = await executor.jsonMGet(
        ['doc:{1}', 'doc:{2}'],
        path: r'$.name',
      );

      expect(result, ['{"name":"redis"}', null]);
      expect(executor.lastCommand, ['JSON.MGET', 'doc:{1}', 'doc:{2}', r'$.name']);
    });

    test('jsonMSet builds JSON.MSET triplets', () async {
      final executor = _FakeJsonExecutor()..response = 'OK';

      final result = await executor.jsonMSet([
        const JsonMSetEntry(key: 'doc:{1}', path: r'$', value: '{"name":"a"}'),
        const JsonMSetEntry(key: 'doc:{2}', path: r'$', value: '{"name":"b"}'),
      ]);

      expect(result, 'OK');
      expect(executor.lastCommand, [
        'JSON.MSET',
        'doc:{1}',
        r'$',
        '{"name":"a"}',
        'doc:{2}',
        r'$',
        '{"name":"b"}',
      ]);
    });

    test('json array helpers build exact commands and decode int replies', () async {
      final executor = _FakeJsonExecutor()..response = [3, 4];

      final appended = await executor.jsonArrAppend(
        'doc:{1}',
        ['1', '2'],
        path: r'$.items',
      );

      expect(appended, [3, 4]);
      expect(executor.lastCommand, [
        'JSON.ARRAPPEND',
        'doc:{1}',
        r'$.items',
        '1',
        '2',
      ]);

      executor.response = [2, 1];
      final trimmed = await executor.jsonArrTrim('doc:{1}', r'$.items', 0, 1);
      expect(trimmed, [2, 1]);
      expect(executor.lastCommand, ['JSON.ARRTRIM', 'doc:{1}', r'$.items', 0, 1]);
    });

    test('jsonDebugMemory builds JSON.DEBUG MEMORY', () async {
      final executor = _FakeJsonExecutor()..response = [128];

      final result = await executor.jsonDebugMemory('doc:{1}', path: r'$.items');

      expect(result, [128]);
      expect(executor.lastCommand, ['JSON.DEBUG', 'MEMORY', 'doc:{1}', r'$.items']);
    });

    test('json object and type helpers normalize replies', () async {
      final executor = _FakeJsonExecutor()
        ..response = [
          ['name', 'version'],
          null,
        ];

      final keys = await executor.jsonObjKeys('doc:{1}');
      expect(keys, [
        ['name', 'version'],
        null,
      ]);
      expect(executor.lastCommand, ['JSON.OBJKEYS', 'doc:{1}', r'$']);

      executor.response = ['object', 'array'];
      final types = await executor.jsonType('doc:{1}', path: r'$..items');
      expect(types, ['object', 'array']);
      expect(executor.lastCommand, ['JSON.TYPE', 'doc:{1}', r'$..items']);
    });

    test('json numeric and toggle helpers build exact commands', () async {
      final executor = _FakeJsonExecutor()..response = '4';

      expect(await executor.jsonNumIncrBy('doc:{1}', r'$.count', 1), '4');
      expect(executor.lastCommand, ['JSON.NUMINCRBY', 'doc:{1}', r'$.count', 1]);

      executor.response = [1, 0];
      expect(await executor.jsonToggle('doc:{1}', path: r'$..enabled'), [1, 0]);
      expect(executor.lastCommand, ['JSON.TOGGLE', 'doc:{1}', r'$..enabled']);
    });
  });
}
