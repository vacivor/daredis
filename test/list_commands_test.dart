import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

class _FakeListExecutor extends RedisCommandExecutor with RedisListCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

void main() {
  group('RedisListCommands', () {
    test('lPushX builds LPUSHX', () async {
      final executor = _FakeListExecutor()..response = 2;

      final result = await executor.lPushX('jobs:{1}', ['a', 'b']);

      expect(result, 2);
      expect(executor.lastCommand, ['LPUSHX', 'jobs:{1}', 'a', 'b']);
    });

    test('rPushX builds RPUSHX', () async {
      final executor = _FakeListExecutor()..response = 2;

      final result = await executor.rPushX('jobs:{1}', ['a', 'b']);

      expect(result, 2);
      expect(executor.lastCommand, ['RPUSHX', 'jobs:{1}', 'a', 'b']);
    });

    test('lPos wraps single and multiple results consistently', () async {
      final executor = _FakeListExecutor()..response = 3;

      expect(
        await executor.lPos('jobs:{1}', 'needle', rank: 2, maxLen: 10),
        [3],
      );
      expect(
        executor.lastCommand,
        ['LPOS', 'jobs:{1}', 'needle', 'RANK', 2, 'MAXLEN', 10],
      );

      executor.response = [1, 4];
      expect(await executor.lPos('jobs:{1}', 'needle', count: 2), [1, 4]);
      expect(
        executor.lastCommand,
        ['LPOS', 'jobs:{1}', 'needle', 'COUNT', 2],
      );
    });

    test('bRPopLPush builds BRPOPLPUSH', () async {
      final executor = _FakeListExecutor()..response = 'value';

      final result = await executor.bRPopLPush('src:{1}', 'dst:{1}', 5);

      expect(result, 'value');
      expect(executor.lastCommand, ['BRPOPLPUSH', 'src:{1}', 'dst:{1}', 5]);
    });

    test('lMPop and bLMPop build commands and parse keyed results', () async {
      final executor = _FakeListExecutor()
        ..response = ['jobs:{1}', ['a', 'b']];

      final lmpop = await executor.lMPop(
        ['jobs:{1}', 'backup:{1}'],
        'LEFT',
        count: 2,
      );

      expect(lmpop, isNotNull);
      expect(lmpop!.key, 'jobs:{1}');
      expect(lmpop.values, ['a', 'b']);
      expect(
        executor.lastCommand,
        ['LMPOP', 2, 'jobs:{1}', 'backup:{1}', 'LEFT', 'COUNT', 2],
      );

      executor.response = ['jobs:{1}', ['c']];
      final blmpop = await executor.bLMPop(
        5,
        ['jobs:{1}', 'backup:{1}'],
        'RIGHT',
      );

      expect(blmpop, isNotNull);
      expect(blmpop!.key, 'jobs:{1}');
      expect(blmpop.values, ['c']);
      expect(
        executor.lastCommand,
        ['BLMPOP', 5, 2, 'jobs:{1}', 'backup:{1}', 'RIGHT'],
      );
    });
  });
}
