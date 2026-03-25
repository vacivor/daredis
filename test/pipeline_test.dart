import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

void main() {
  group('RedisPipeline', () {
    test('execute forwards queued commands as a single batch', () async {
      final batches = <List<List<dynamic>>>[];
      final pipeline = RedisPipeline((items) async {
        batches.add([for (final item in items) item.command]);
        return [for (final item in items) item.command.first];
      });

      pipeline.add(['SET', 'key', 'value']);
      pipeline.add(['GET', 'key']);

      final results = await pipeline.execute();

      expect(batches, [
        [
          ['SET', 'key', 'value'],
          ['GET', 'key'],
        ],
      ]);
      expect(results, ['SET', 'GET']);
    });
  });
}
