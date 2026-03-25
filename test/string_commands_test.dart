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
  });
}
