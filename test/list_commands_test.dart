import 'dart:typed_data';

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

    test('bytes helpers preserve raw list payloads', () async {
      final executor = _FakeListExecutor()
        ..response = Uint8List.fromList([1, 2, 3]);

      expect(await executor.lPopBytes('jobs:{1}'), Uint8List.fromList([1, 2, 3]));
      expect(executor.lastCommand, ['LPOP', 'jobs:{1}']);

      executor.response = [Uint8List.fromList([4]), Uint8List.fromList([5, 6])];
      expect(
        await executor.lPopCountBytes('jobs:{1}', 2),
        [Uint8List.fromList([4]), Uint8List.fromList([5, 6])],
      );
      expect(executor.lastCommand, ['LPOP', 'jobs:{1}', 2]);

      executor.response = Uint8List.fromList([7, 8]);
      expect(await executor.rPopBytes('jobs:{1}'), Uint8List.fromList([7, 8]));
      expect(executor.lastCommand, ['RPOP', 'jobs:{1}']);

      executor.response = [Uint8List.fromList([9]), Uint8List.fromList([10])];
      expect(
        await executor.rPopCountBytes('jobs:{1}', 2),
        [Uint8List.fromList([9]), Uint8List.fromList([10])],
      );
      expect(executor.lastCommand, ['RPOP', 'jobs:{1}', 2]);

      executor.response = [Uint8List.fromList([11]), Uint8List.fromList([12, 13])];
      expect(
        await executor.lRangeBytes('jobs:{1}', 0, -1),
        [Uint8List.fromList([11]), Uint8List.fromList([12, 13])],
      );
      expect(executor.lastCommand, ['LRANGE', 'jobs:{1}', 0, -1]);

      executor.response = Uint8List.fromList([14]);
      expect(await executor.lIndexBytes('jobs:{1}', 0), Uint8List.fromList([14]));
      expect(executor.lastCommand, ['LINDEX', 'jobs:{1}', 0]);

      executor.response = ['jobs:{1}', Uint8List.fromList([15, 16])];
      expect(
        await executor.bLPopBytes(['jobs:{1}'], 5),
        {'jobs:{1}': Uint8List.fromList([15, 16])},
      );
      expect(executor.lastCommand, ['BLPOP', 'jobs:{1}', 5]);

      executor.response = ['jobs:{1}', Uint8List.fromList([17])];
      expect(
        await executor.bRPopBytes(['jobs:{1}'], 5),
        {'jobs:{1}': Uint8List.fromList([17])},
      );
      expect(executor.lastCommand, ['BRPOP', 'jobs:{1}', 5]);

      executor.response = Uint8List.fromList([18, 19]);
      expect(
        await executor.rPopLPushBytes('src:{1}', 'dst:{1}'),
        Uint8List.fromList([18, 19]),
      );
      expect(executor.lastCommand, ['RPOPLPUSH', 'src:{1}', 'dst:{1}']);

      executor.response = Uint8List.fromList([20]);
      expect(
        await executor.bRPopLPushBytes('src:{1}', 'dst:{1}', 5),
        Uint8List.fromList([20]),
      );
      expect(executor.lastCommand, ['BRPOPLPUSH', 'src:{1}', 'dst:{1}', 5]);

      executor.response = Uint8List.fromList([21, 22]);
      expect(
        await executor.lMoveBytes('src:{1}', 'dst:{1}', 'LEFT', 'RIGHT'),
        Uint8List.fromList([21, 22]),
      );
      expect(executor.lastCommand, ['LMOVE', 'src:{1}', 'dst:{1}', 'LEFT', 'RIGHT']);

      executor.response = Uint8List.fromList([23]);
      expect(
        await executor.bLMoveBytes('src:{1}', 'dst:{1}', 'RIGHT', 'LEFT', 5),
        Uint8List.fromList([23]),
      );
      expect(executor.lastCommand, [
        'BLMOVE',
        'src:{1}',
        'dst:{1}',
        'RIGHT',
        'LEFT',
        5,
      ]);

      executor.response = ['jobs:{1}', [Uint8List.fromList([24]), Uint8List.fromList([25, 26])]];
      final lmpop = await executor.lMPopBytes(['jobs:{1}'], 'LEFT', count: 2);
      expect(lmpop, isNotNull);
      expect(lmpop!.key, 'jobs:{1}');
      expect(lmpop.values, [Uint8List.fromList([24]), Uint8List.fromList([25, 26])]);
      expect(executor.lastCommand, ['LMPOP', 1, 'jobs:{1}', 'LEFT', 'COUNT', 2]);

      executor.response = ['jobs:{1}', [Uint8List.fromList([27])]];
      final blmpop = await executor.bLMPopBytes(5, ['jobs:{1}'], 'RIGHT');
      expect(blmpop, isNotNull);
      expect(blmpop!.key, 'jobs:{1}');
      expect(blmpop.values, [Uint8List.fromList([27])]);
      expect(executor.lastCommand, ['BLMPOP', 5, 1, 'jobs:{1}', 'RIGHT']);
    });
  });
}
