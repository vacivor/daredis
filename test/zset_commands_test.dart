import 'dart:typed_data';

import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

class _FakeZSetExecutor extends RedisCommandExecutor with RedisSortedSetCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

void main() {
  group('RedisSortedSetCommands', () {
    test('zRandMember builds ZRANDMEMBER and normalizes response', () async {
      final executor = _FakeZSetExecutor()..response = 'alice';

      expect(await executor.zRandMember('leaderboard:{1}'), ['alice']);
      expect(executor.lastCommand, ['ZRANDMEMBER', 'leaderboard:{1}']);

      executor.response = ['alice', 'bob'];
      expect(await executor.zRandMember('leaderboard:{1}', 2), ['alice', 'bob']);
      expect(executor.lastCommand, ['ZRANDMEMBER', 'leaderboard:{1}', 2]);
    });

    test('zInterCard builds ZINTERCARD', () async {
      final executor = _FakeZSetExecutor()..response = 2;

      final result = await executor.zInterCard(
        2,
        ['scores:{1}', 'backup:{1}'],
        limit: 10,
      );

      expect(result, 2);
      expect(
        executor.lastCommand,
        ['ZINTERCARD', 2, 'scores:{1}', 'backup:{1}', 'LIMIT', 10],
      );
    });

    test('zRangeStore builds ZRANGESTORE', () async {
      final executor = _FakeZSetExecutor()..response = 5;

      final result = await executor.zRangeStore(
        'top:{1}',
        'leaderboard:{1}',
        0,
        9,
      );

      expect(result, 5);
      expect(
        executor.lastCommand,
        ['ZRANGESTORE', 'top:{1}', 'leaderboard:{1}', 0, 9],
      );
    });

    test('zMScore decodes nullable doubles', () async {
      final executor = _FakeZSetExecutor()..response = ['1.5', null, 3];

      final result = await executor.zMScore(
        'leaderboard:{1}',
        ['alice', 'bob', 'cara'],
      );

      expect(result, [1.5, null, 3.0]);
      expect(
        executor.lastCommand,
        ['ZMSCORE', 'leaderboard:{1}', 'alice', 'bob', 'cara'],
      );
    });

    test('reverse range helpers build the correct commands', () async {
      final executor = _FakeZSetExecutor()..response = ['alice', '1', 'bob', '2'];

      expect(
        await executor.zRevRangeByScore(
          'leaderboard:{1}',
          '+inf',
          '-inf',
          withScores: true,
          offset: 0,
          count: 2,
        ),
        ['alice', '1', 'bob', '2'],
      );
      expect(
        executor.lastCommand,
        [
          'ZREVRANGEBYSCORE',
          'leaderboard:{1}',
          '+inf',
          '-inf',
          'WITHSCORES',
          'LIMIT',
          0,
          2,
        ],
      );

      executor.response = ['bob', 'alice'];
      expect(
        await executor.zRevRangeByLex(
          'leaderboard:{1}',
          '+',
          '-',
          offset: 0,
          count: 2,
        ),
        ['bob', 'alice'],
      );
      expect(
        executor.lastCommand,
        ['ZREVRANGEBYLEX', 'leaderboard:{1}', '+', '-', 'LIMIT', 0, 2],
      );
    });

    test('zMPop and bZMPop parse scored member groups', () async {
      final executor = _FakeZSetExecutor()
        ..response = [
          'leaderboard:{1}',
          [
            ['alice', '1.5'],
            ['bob', '2.0'],
          ],
        ];

      final zmpop = await executor.zMPop(
        ['leaderboard:{1}', 'backup:{1}'],
        'MAX',
        count: 2,
      );

      expect(zmpop, isNotNull);
      expect(zmpop!.key, 'leaderboard:{1}');
      expect(zmpop.entries.map((entry) => entry.member), ['alice', 'bob']);
      expect(zmpop.entries.map((entry) => entry.score), [1.5, 2.0]);
      expect(
        executor.lastCommand,
        ['ZMPOP', 2, 'leaderboard:{1}', 'backup:{1}', 'MAX', 'COUNT', 2],
      );

      executor.response = [
        'leaderboard:{1}',
        [
          ['cara', '3.0'],
        ],
      ];
      final bzmpop = await executor.bZMPop(
        5,
        ['leaderboard:{1}', 'backup:{1}'],
        'MIN',
      );

      expect(bzmpop, isNotNull);
      expect(bzmpop!.entries.single.member, 'cara');
      expect(bzmpop.entries.single.score, 3.0);
      expect(
        executor.lastCommand,
        ['BZMPOP', 5, 2, 'leaderboard:{1}', 'backup:{1}', 'MIN'],
      );
    });

    test('bZPopMin and bZPopMax parse single scored member results', () async {
      final executor = _FakeZSetExecutor()
        ..response = ['leaderboard:{1}', 'alice', '1.5'];

      final minResult = await executor.bZPopMin(
        ['leaderboard:{1}', 'backup:{1}'],
        5,
      );

      expect(minResult, isNotNull);
      expect(minResult!.key, 'leaderboard:{1}');
      expect(minResult.entries.single.member, 'alice');
      expect(minResult.entries.single.score, 1.5);
      expect(
        executor.lastCommand,
        ['BZPOPMIN', 'leaderboard:{1}', 'backup:{1}', 5],
      );

      executor.response = ['leaderboard:{1}', 'bob', '8.0'];
      final maxResult = await executor.bZPopMax(
        ['leaderboard:{1}', 'backup:{1}'],
        3,
      );

      expect(maxResult, isNotNull);
      expect(maxResult!.entries.single.member, 'bob');
      expect(maxResult.entries.single.score, 8.0);
      expect(
        executor.lastCommand,
        ['BZPOPMAX', 'leaderboard:{1}', 'backup:{1}', 3],
      );
    });

    test('bytes helpers preserve raw sorted-set payloads', () async {
      final executor = _FakeZSetExecutor()
        ..response = Uint8List.fromList([1, 2]);

      expect(
        await executor.zRandMemberBytes('leaderboard:{1}'),
        [Uint8List.fromList([1, 2])],
      );
      expect(executor.lastCommand, ['ZRANDMEMBER', 'leaderboard:{1}']);

      executor.response = [Uint8List.fromList([3]), Uint8List.fromList([4])];
      expect(
        await executor.zRangeBytes('leaderboard:{1}', 0, 1),
        [Uint8List.fromList([3]), Uint8List.fromList([4])],
      );
      expect(executor.lastCommand, ['ZRANGE', 'leaderboard:{1}', 0, 1]);

      executor.response = [Uint8List.fromList([5]), Uint8List.fromList([6])];
      expect(
        await executor.zRevRangeByScoreBytes(
          'leaderboard:{1}',
          '+inf',
          '-inf',
          withScores: true,
          offset: 0,
          count: 1,
        ),
        [Uint8List.fromList([5]), Uint8List.fromList([6])],
      );
      expect(executor.lastCommand, [
        'ZREVRANGEBYSCORE',
        'leaderboard:{1}',
        '+inf',
        '-inf',
        'WITHSCORES',
        'LIMIT',
        0,
        1,
      ]);

      executor.response = [Uint8List.fromList([7]), Uint8List.fromList([8])];
      expect(
        await executor.zPopMinBytes('leaderboard:{1}', 1),
        [Uint8List.fromList([7]), Uint8List.fromList([8])],
      );
      expect(executor.lastCommand, ['ZPOPMIN', 'leaderboard:{1}', 1]);

      executor.response = [
        'leaderboard:{1}',
        [
          [Uint8List.fromList([9]), '1.5'],
          [Uint8List.fromList([10]), '2.0'],
        ],
      ];
      final zmpop = await executor.zMPopBytes(['leaderboard:{1}'], 'MAX', count: 2);
      expect(zmpop, isNotNull);
      expect(
        zmpop!.entries.map((entry) => entry.member),
        [Uint8List.fromList([9]), Uint8List.fromList([10])],
      );
      expect(zmpop.entries.map((entry) => entry.score), [1.5, 2.0]);
      expect(executor.lastCommand, ['ZMPOP', 1, 'leaderboard:{1}', 'MAX', 'COUNT', 2]);

      executor.response = ['leaderboard:{1}', Uint8List.fromList([11]), '8.0'];
      final bzpop = await executor.bZPopMaxBytes(['leaderboard:{1}'], 3);
      expect(bzpop, isNotNull);
      expect(bzpop!.entries.single.member, Uint8List.fromList([11]));
      expect(bzpop.entries.single.score, 8.0);
      expect(executor.lastCommand, ['BZPOPMAX', 'leaderboard:{1}', 3]);

      executor.response = ['0', [Uint8List.fromList([12]), '1.0', Uint8List.fromList([13]), '2.5']];
      final scan = await executor.zScanBytes('leaderboard:{1}', 0, count: 10);
      expect(scan.cursor, 0);
      expect(
        scan.items.map((entry) => entry.key),
        [Uint8List.fromList([12]), Uint8List.fromList([13])],
      );
      expect(
        scan.items.map((entry) => entry.value),
        [1.0, 2.5],
      );
      expect(executor.lastCommand, ['ZSCAN', 'leaderboard:{1}', 0, 'COUNT', 10]);
    });
  });
}
