import 'dart:typed_data';

import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

class _FakeSetExecutor extends RedisCommandExecutor with RedisSetCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

void main() {
  group('RedisSetCommands', () {
    test('sMisMember builds SMISMEMBER and decodes booleans', () async {
      final executor = _FakeSetExecutor()..response = [1, 0, true];

      final result = await executor.sMisMember(
        'set:{1}',
        ['a', 'b', 'c'],
      );

      expect(result, [true, false, true]);
      expect(executor.lastCommand, ['SMISMEMBER', 'set:{1}', 'a', 'b', 'c']);
    });

    test('bytes helpers preserve raw set payloads', () async {
      final executor = _FakeSetExecutor()
        ..response = [Uint8List.fromList([1]), Uint8List.fromList([2, 3])];

      expect(
        await executor.sMembersBytes('set:{1}'),
        [Uint8List.fromList([1]), Uint8List.fromList([2, 3])],
      );
      expect(executor.lastCommand, ['SMEMBERS', 'set:{1}']);

      executor.response = Uint8List.fromList([4, 5]);
      expect(await executor.sPopBytes('set:{1}'), [Uint8List.fromList([4, 5])]);
      expect(executor.lastCommand, ['SPOP', 'set:{1}']);

      executor.response = [Uint8List.fromList([6]), Uint8List.fromList([7])];
      expect(
        await executor.sPopBytes('set:{1}', 2),
        [Uint8List.fromList([6]), Uint8List.fromList([7])],
      );
      expect(executor.lastCommand, ['SPOP', 'set:{1}', 2]);

      executor.response = [Uint8List.fromList([8]), Uint8List.fromList([9, 10])];
      expect(
        await executor.sRandMemberBytes('set:{1}', 2),
        [Uint8List.fromList([8]), Uint8List.fromList([9, 10])],
      );
      expect(executor.lastCommand, ['SRANDMEMBER', 'set:{1}', 2]);

      executor.response = [Uint8List.fromList([11]), Uint8List.fromList([12])];
      expect(
        await executor.sDiffBytes(['a:{1}', 'b:{1}']),
        [Uint8List.fromList([11]), Uint8List.fromList([12])],
      );
      expect(executor.lastCommand, ['SDIFF', 'a:{1}', 'b:{1}']);

      executor.response = [Uint8List.fromList([13])];
      expect(
        await executor.sInterBytes(['a:{1}', 'b:{1}']),
        [Uint8List.fromList([13])],
      );
      expect(executor.lastCommand, ['SINTER', 'a:{1}', 'b:{1}']);

      executor.response = [Uint8List.fromList([14]), Uint8List.fromList([15])];
      expect(
        await executor.sUnionBytes(['a:{1}', 'b:{1}']),
        [Uint8List.fromList([14]), Uint8List.fromList([15])],
      );
      expect(executor.lastCommand, ['SUNION', 'a:{1}', 'b:{1}']);

      executor.response = ['0', [Uint8List.fromList([16]), Uint8List.fromList([17, 18])]];
      final scan = await executor.sScanBytes('set:{1}', 0, count: 10);
      expect(scan.cursor, 0);
      expect(
        scan.items,
        [Uint8List.fromList([16]), Uint8List.fromList([17, 18])],
      );
      expect(executor.lastCommand, ['SSCAN', 'set:{1}', 0, 'COUNT', 10]);
    });
  });
}
