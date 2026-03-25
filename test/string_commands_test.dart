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
