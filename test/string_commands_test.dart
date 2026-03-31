import 'dart:typed_data';

import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

class _FakeStringExecutor extends RedisCommandExecutor with RedisStringCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

void main() {
  group('RedisStringCommands', () {
    test('digest and delex build exact string commands', () async {
      final executor = _FakeStringExecutor()..response = 'abc123';

      expect(await executor.digest('key:{1}'), 'abc123');
      expect(executor.lastCommand, ['DIGEST', 'key:{1}']);

      executor.response = 1;
      expect(await executor.delex('key:{1}', ifEq: 'value'), isTrue);
      expect(executor.lastCommand, ['DELEX', 'key:{1}', 'IFEQ', 'value']);

      expect(
        () => executor.delex('key:{1}', ifEq: 'a', ifNe: 'b'),
        throwsArgumentError,
      );
    });

    test('mSetEx builds a Redis MSETEX command', () async {
      final executor = _FakeStringExecutor()..response = 2;

      final result = await executor.mSetEx(
        {'session:{1}': 'a', 'profile:{1}': 'b'},
        ex: 60,
        nx: true,
      );

      expect(result, 2);
      expect(executor.lastCommand, [
        'MSETEX',
        2,
        'session:{1}',
        'a',
        'profile:{1}',
        'b',
        'EX',
        60,
        'NX',
      ]);
    });

    test('bitPos requires start when end is provided', () {
      final executor = _FakeStringExecutor();

      expect(
        () => executor.bitPos('bits:{1}', 1, end: 8),
        throwsArgumentError,
      );
    });

    test('bytes helpers preserve binary payloads', () async {
      final executor = _FakeStringExecutor()
        ..response = Uint8List.fromList([0, 255, 1, 2]);

      expect(await executor.getBytes('blob:{1}'), Uint8List.fromList([0, 255, 1, 2]));
      expect(executor.lastCommand, ['GET', 'blob:{1}']);

      executor.response = [
        Uint8List.fromList([1, 2]),
        null,
        Uint8List.fromList([3, 4]),
      ];
      expect(await executor.mGetBytes(['a:{1}', 'b:{1}', 'c:{1}']), [
        Uint8List.fromList([1, 2]),
        null,
        Uint8List.fromList([3, 4]),
      ]);
      expect(executor.lastCommand, ['MGET', 'a:{1}', 'b:{1}', 'c:{1}']);

      executor.response = Uint8List.fromList([9, 8, 7]);
      expect(await executor.getDelBytes('blob:{1}'), Uint8List.fromList([9, 8, 7]));
      expect(executor.lastCommand, ['GETDEL', 'blob:{1}']);

      executor.response = Uint8List.fromList([6, 5, 4]);
      expect(await executor.getExBytes('blob:{1}', ex: 10), Uint8List.fromList([6, 5, 4]));
      expect(executor.lastCommand, ['GETEX', 'blob:{1}', 'EX', 10]);

      executor.response = Uint8List.fromList([3, 2, 1]);
      expect(await executor.getSetBytes('blob:{1}', 'next'), Uint8List.fromList([3, 2, 1]));
      expect(executor.lastCommand, ['GETSET', 'blob:{1}', 'next']);
    });
  });
}
