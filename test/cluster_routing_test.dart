import 'dart:convert';

import 'package:daredis/src/cluster_command_spec.dart';
import 'package:daredis/src/cluster_slots.dart';
import 'package:daredis/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('Cluster routing', () {
    test('extracts keys from key-value and numkeys commands', () {
      expect(
        ClusterCommandSpec.extractKeys(['MSET', 'a', '1', 'b', '2']),
        ['a', 'b'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'ZINTERSTORE',
          'dest',
          2,
          'set:{1}',
          'other:{1}',
        ]),
        ['dest', 'set:{1}', 'other:{1}'],
      );
    });

    test('extracts stream keys after STREAMS keyword', () {
      final keys = ClusterCommandSpec.extractKeys([
        'XREADGROUP',
        'GROUP',
        'g1',
        'c1',
        'COUNT',
        2,
        'STREAMS',
        'orders:{42}',
        'payments:{42}',
        '>',
        '>',
      ]);

      expect(keys, ['orders:{42}', 'payments:{42}']);
    });

    test('hash tags route related keys to the same slot', () {
      final slotCache = ClusterSlotCache();

      final slotA = slotCache.slotForKey('orders:{42}:a');
      final slotB = slotCache.slotForKey('payments:{42}:b');
      final slotC = slotCache.slotForKey('orders:{7}:a');

      expect(slotA, slotB);
      expect(slotA, isNot(slotC));
    });

    test('validateSameSlot allows tagged keys and rejects cross-slot keys', () {
      final slotCache = ClusterSlotCache();

      expect(
        () => ClusterCommandSpec.validateSameSlot([
          'orders:{42}',
          'payments:{42}',
        ], slotCache),
        returnsNormally,
      );

      expect(
        () => ClusterCommandSpec.validateSameSlot([
          'orders:{42}',
          'payments:{7}',
        ], slotCache),
        throwsA(isA<RespException>()),
      );
    });

    test('validateSameSlot allows a single key without special handling', () {
      final slotCache = ClusterSlotCache();

      expect(
        () => ClusterCommandSpec.validateSameSlot(['orders:{42}'], slotCache),
        returnsNormally,
      );
    });

    test('decodes binary keys into strings', () {
      final bytes = utf8.encode('user:{9}');
      expect(keyToString(bytes), 'user:{9}');
    });
  });
}
