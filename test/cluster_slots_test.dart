import 'package:daredis/src/cluster_slots.dart';
import 'package:daredis/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('ClusterSlotCache', () {
    test('loads slot owners from CLUSTER SLOTS response', () {
      final cache = ClusterSlotCache();

      cache.updateFromSlotsResponse([
        [0, 8191, ['127.0.0.1', 7000]],
        [8192, 16383, ['127.0.0.1', 7001]],
      ]);

      expect(cache.nodeForSlot(0), const ClusterNodeAddress('127.0.0.1', 7000));
      expect(
        cache.nodeForSlot(16383),
        const ClusterNodeAddress('127.0.0.1', 7001),
      );
      expect(cache.uniqueNodes().toSet(), {
        const ClusterNodeAddress('127.0.0.1', 7000),
        const ClusterNodeAddress('127.0.0.1', 7001),
      });
    });

    test('nodeForKey respects hash tags', () {
      final cache = ClusterSlotCache();
      cache.updateFromSlotsResponse([
        [0, 16383, ['127.0.0.1', 7000]],
      ]);

      expect(cache.nodeForKey('orders:{42}:a'), cache.nodeForKey('payments:{42}:b'));
    });

    test('rejects malformed CLUSTER SLOTS responses', () {
      final cache = ClusterSlotCache();

      expect(
        () => cache.updateFromSlotsResponse('not-a-list'),
        throwsA(isA<RespException>()),
      );
    });
  });
}
