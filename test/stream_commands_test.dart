import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

class _FakeStreamExecutor extends RedisCommandExecutor with RedisStreamCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

void main() {
  group('RedisStreamCommands', () {
    test('xSetId builds XSETID', () async {
      final executor = _FakeStreamExecutor()..response = 'OK';

      final result = await executor.xSetId(
        'stream:{1}',
        '0-1',
        entriesAdded: 10,
        maxDeletedId: '0-0',
      );

      expect(result, 'OK');
      expect(
        executor.lastCommand,
        ['XSETID', 'stream:{1}', '0-1', 'ENTRIESADDED', 10, 'MAXDELETEDID', '0-0'],
      );
    });
  });
}
