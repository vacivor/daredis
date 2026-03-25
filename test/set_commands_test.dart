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
  });
}
