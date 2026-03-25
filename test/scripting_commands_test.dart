import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

class _FakeScriptingExecutor extends RedisCommandExecutor
    with RedisScriptingCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

void main() {
  group('RedisScriptingCommands', () {
    test('fCall builds FCALL and decodes a string reply', () async {
      final executor = _FakeScriptingExecutor()..response = 'ok';

      final result = await executor.fCallString('lib.echo', ['key:{1}'], ['arg']);

      expect(result, 'ok');
      expect(executor.lastCommand, ['FCALL', 'lib.echo', 1, 'key:{1}', 'arg']);
    });

    test('fCallRo builds FCALL_RO and decodes a list reply', () async {
      final executor = _FakeScriptingExecutor()
        ..response = ['a', 'b', 'c'];

      final result = await executor.fCallRoListString(
        'lib.read_only',
        ['key:{1}', 'other:{1}'],
        [1, 2],
      );

      expect(result, ['a', 'b', 'c']);
      expect(executor.lastCommand, [
        'FCALL_RO',
        'lib.read_only',
        2,
        'key:{1}',
        'other:{1}',
        1,
        2,
      ]);
    });
  });
}
