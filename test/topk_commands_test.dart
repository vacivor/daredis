import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

class _FakeTopKExecutor extends RedisCommandExecutor with RedisTopKCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

void main() {
  group('RedisTopKCommands', () {
    test('topKReserve validates optional parameters and builds exact command', () async {
      final executor = _FakeTopKExecutor()..response = 'OK';

      expect(
        await executor.topKReserve(
          'topk:{1}',
          5,
          width: 2000,
          depth: 7,
          decay: 0.925,
        ),
        'OK',
      );
      expect(executor.lastCommand, ['TOPK.RESERVE', 'topk:{1}', 5, 2000, 7, 0.925]);

      expect(
        () => executor.topKReserve('topk:{1}', 5, width: 2000),
        throwsArgumentError,
      );
    });

    test('topKAdd topKIncrBy topKQuery and topKCount normalize replies', () async {
      final executor = _FakeTopKExecutor()..response = [null, 'foo'];

      expect(await executor.topKAdd('topk:{1}', ['foo', 'bar']), [null, 'foo']);
      expect(executor.lastCommand, ['TOPK.ADD', 'topk:{1}', 'foo', 'bar']);

      executor.response = ['bar', null];
      expect(
        await executor.topKIncrBy(
          'topk:{1}',
          const [TopKIncrement('foo', 2), TopKIncrement('bar', 3)],
        ),
        ['bar', null],
      );
      expect(executor.lastCommand, ['TOPK.INCRBY', 'topk:{1}', 'foo', 2, 'bar', 3]);

      executor.response = [1, 0];
      expect(await executor.topKQuery('topk:{1}', ['foo', 'baz']), [true, false]);
      expect(executor.lastCommand, ['TOPK.QUERY', 'topk:{1}', 'foo', 'baz']);

      executor.response = [10, 3];
      expect(await executor.topKCount('topk:{1}', ['foo', 'baz']), [10, 3]);
      expect(executor.lastCommand, ['TOPK.COUNT', 'topk:{1}', 'foo', 'baz']);
    });

    test('topKList and topKInfo parse structured replies', () async {
      final executor = _FakeTopKExecutor()..response = ['foo', 'bar'];

      final list = await executor.topKList('topk:{1}');
      expect(list.map((entry) => entry.item), ['foo', 'bar']);
      expect(list.every((entry) => entry.count == null), isTrue);
      expect(executor.lastCommand, ['TOPK.LIST', 'topk:{1}']);

      executor.response = ['foo', 10, 'bar', 3];
      final withCount = await executor.topKList('topk:{1}', withCount: true);
      expect(withCount.map((entry) => entry.item), ['foo', 'bar']);
      expect(withCount.map((entry) => entry.count), [10, 3]);
      expect(executor.lastCommand, ['TOPK.LIST', 'topk:{1}', 'WITHCOUNT']);

      executor.response = ['k', 5, 'width', 2000, 'depth', 7, 'decay', 0.925];
      final info = await executor.topKInfo('topk:{1}');
      expect(info.k, 5);
      expect(info.width, 2000);
      expect(info.depth, 7);
      expect(info.decay, 0.925);
      expect(executor.lastCommand, ['TOPK.INFO', 'topk:{1}']);
    });
  });
}
