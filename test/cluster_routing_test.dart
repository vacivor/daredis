import 'dart:convert';

import 'package:daredis/src/cluster_command_spec.dart';
import 'package:daredis/src/cluster_command_policy.dart';
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
          'MSETEX',
          2,
          'session:{1}',
          'a',
          'profile:{1}',
          'b',
          'EX',
          60,
        ]),
        ['session:{1}', 'profile:{1}'],
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

    test('extracts keys from blocking multi-key pop commands', () {
      expect(
        ClusterCommandSpec.extractKeys([
          'BZPOPMIN',
          'scores:{1}',
          'scores:{1}:backup',
          0,
        ]),
        ['scores:{1}', 'scores:{1}:backup'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'BZMPOP',
          0,
          2,
          'scores:{1}',
          'scores:{1}:backup',
          'MIN',
        ]),
        ['scores:{1}', 'scores:{1}:backup'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'BLMPOP',
          0,
          2,
          'jobs:{1}',
          'jobs:{1}:backup',
          'LEFT',
          'COUNT',
          2,
        ]),
        ['jobs:{1}', 'jobs:{1}:backup'],
      );
    });

    test('extracts keys from newer numkeys zset and list commands', () {
      expect(
        ClusterCommandSpec.extractKeys([
          'LMPOP',
          2,
          'jobs:{7}',
          'jobs:{7}:backup',
          'LEFT',
        ]),
        ['jobs:{7}', 'jobs:{7}:backup'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'ZMPOP',
          2,
          'leaderboard:{7}',
          'leaderboard:{7}:backup',
          'MAX',
        ]),
        ['leaderboard:{7}', 'leaderboard:{7}:backup'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'ZINTERCARD',
          2,
          'set:{7}',
          'other:{7}',
        ]),
        ['set:{7}', 'other:{7}'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'PFDEBUG',
          'GETREG',
          'hll:{7}',
          0,
        ]),
        ['hll:{7}'],
      );

      expect(ClusterCommandSpec.extractKeys(['PFSELFTEST']), isEmpty);
      expect(ClusterCommandSpec.extractKeys(['WAIT', 1, 1000]), isEmpty);
      expect(ClusterCommandSpec.extractKeys(['WAITAOF', 1, 1, 1000]), isEmpty);
      expect(ClusterCommandSpec.extractKeys(['QUIT']), isEmpty);
      expect(ClusterCommandSpec.extractKeys(['RESET']), isEmpty);
    });

    test('extracts source and store keys from sort commands', () {
      expect(
        ClusterCommandSpec.extractKeys([
          'SORT',
          'jobs:{1}',
          'ALPHA',
          'STORE',
          'jobs:{1}:sorted',
        ]),
        ['jobs:{1}', 'jobs:{1}:sorted'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'SORT_RO',
          'jobs:{1}',
          'ALPHA',
        ]),
        ['jobs:{1}'],
      );
    });

    test('extracts keys from memory and object subcommands only when needed', () {
      expect(
        ClusterCommandSpec.extractKeys(['MEMORY', 'USAGE', 'cache:{1}']),
        ['cache:{1}'],
      );
      expect(ClusterCommandSpec.extractKeys(['MEMORY', 'DOCTOR']), isEmpty);

      expect(
        ClusterCommandSpec.extractKeys(['OBJECT', 'ENCODING', 'cache:{1}']),
        ['cache:{1}'],
      );
      expect(ClusterCommandSpec.extractKeys(['OBJECT', 'HELP']), isEmpty);
    });

    test('extracts keys from RedisJSON commands', () {
      expect(
        ClusterCommandSpec.extractKeys([
          'JSON.GET',
          'doc:{1}',
          r'$.name',
        ]),
        ['doc:{1}'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'JSON.MGET',
          'doc:{1}',
          'doc:{1}:backup',
          r'$.name',
        ]),
        ['doc:{1}', 'doc:{1}:backup'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'JSON.MSET',
          'doc:{1}',
          r'$',
          '{"name":"a"}',
          'doc:{1}:backup',
          r'$',
          '{"name":"b"}',
        ]),
        ['doc:{1}', 'doc:{1}:backup'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'JSON.DEBUG',
          'MEMORY',
          'doc:{1}',
          r'$',
        ]),
        ['doc:{1}'],
      );
    });

    test('extracts keys from vector set commands', () {
      expect(
        ClusterCommandSpec.extractKeys([
          'VADD',
          'embeddings:{1}',
          'VALUES',
          3,
          1,
          2,
          3,
          'doc:1',
        ]),
        ['embeddings:{1}'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'VSIM',
          'embeddings:{1}',
          'ELE',
          'doc:1',
          'COUNT',
          3,
        ]),
        ['embeddings:{1}'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'VGETATTR',
          'embeddings:{1}',
          'doc:1',
        ]),
        ['embeddings:{1}'],
      );
    });

    test('extracts keys from time series commands', () {
      expect(
        ClusterCommandSpec.extractKeys([
          'TS.ADD',
          'series:{1}',
          '*',
          1,
        ]),
        ['series:{1}'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'TS.CREATERULE',
          'source:{1}',
          'dest:{1}',
          'AGGREGATION',
          'AVG',
          60000,
        ]),
        ['source:{1}', 'dest:{1}'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'TS.MADD',
          'series:{1}',
          1,
          10,
          'series:{2}',
          2,
          20,
        ]),
        ['series:{1}', 'series:{2}'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'TS.MRANGE',
          '-',
          '+',
          'FILTER',
          'sensor=s1',
        ]),
        isEmpty,
      );
    });

    test('search commands are treated as known no-key commands', () {
      expect(ClusterCommandSpec.extractKeys(['FT.SEARCH', 'idx', '*']), isEmpty);
      expect(ClusterCommandPolicy.hasKnownSpec(['FT.SEARCH', 'idx', '*']), isTrue);
      expect(ClusterCommandSpec.extractKeys(['FT.CREATE', 'idx', 'SCHEMA', 'title', 'TEXT']), isEmpty);
    });

    test('extracts keys from topk commands', () {
      expect(
        ClusterCommandSpec.extractKeys(['TOPK.RESERVE', 'topk:{1}', 5, 2000, 7, 0.925]),
        ['topk:{1}'],
      );
      expect(
        ClusterCommandSpec.extractKeys(['TOPK.ADD', 'topk:{1}', 'foo', 'bar']),
        ['topk:{1}'],
      );
      expect(
        ClusterCommandSpec.extractKeys(['TOPK.LIST', 'topk:{1}', 'WITHCOUNT']),
        ['topk:{1}'],
      );
    });

    test('extracts direct and KEYS-style migrate keys', () {
      expect(
        ClusterCommandSpec.extractKeys([
          'MIGRATE',
          '127.0.0.1',
          6379,
          'user:{1}',
          0,
          5000,
        ]),
        ['user:{1}'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'MIGRATE',
          '127.0.0.1',
          6379,
          '',
          0,
          5000,
          'KEYS',
          'user:{1}',
          'profile:{1}',
        ]),
        ['user:{1}', 'profile:{1}'],
      );
    });

    test('does not guess keys for unknown commands', () {
      expect(
        ClusterCommandSpec.extractKeys([
          'SOMEFUTURECOMMAND',
          'library.fn',
          1,
          'user:{1}',
        ]),
        isEmpty,
      );
    });

    test('reports whether a command has a known cluster spec', () {
      expect(ClusterCommandPolicy.hasKnownSpec(['GET', 'user:{1}']), isTrue);
      expect(
        ClusterCommandPolicy.hasKnownSpec(['SOMEFUTURECOMMAND', 'user:{1}']),
        isFalse,
      );
    });

    test('extracts keys from function calls and zrangestore', () {
      expect(
        ClusterCommandSpec.extractKeys([
          'FCALL',
          'library.fn',
          2,
          'user:{1}',
          'profile:{1}',
          'arg1',
        ]),
        ['user:{1}', 'profile:{1}'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'FCALL_RO',
          'library.read_only',
          1,
          'user:{1}',
        ]),
        ['user:{1}'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'ZRANGESTORE',
          'leaderboard:{1}:top',
          'leaderboard:{1}',
          0,
          9,
        ]),
        ['leaderboard:{1}:top', 'leaderboard:{1}'],
      );
    });

    test('extracts keys from additional single-key and internal commands', () {
      expect(
        ClusterCommandSpec.extractKeys([
          'LINSERT',
          'jobs:{1}',
          'BEFORE',
          'pivot',
          'value',
        ]),
        ['jobs:{1}'],
      );

      expect(
        ClusterCommandSpec.extractKeys(['LPOS', 'jobs:{1}', 'value']),
        ['jobs:{1}'],
      );

      expect(
        ClusterCommandSpec.extractKeys(['ZRANDMEMBER', 'leaderboard:{1}', 2]),
        ['leaderboard:{1}'],
      );

      expect(
        ClusterCommandSpec.extractKeys(['XSETID', 'stream:{1}', '0-0']),
        ['stream:{1}'],
      );

      expect(
        ClusterCommandSpec.extractKeys([
          'RESTORE-ASKING',
          'cache:{1}',
          0,
          'payload',
        ]),
        ['cache:{1}'],
      );

      expect(ClusterCommandSpec.extractKeys(['ASKING']), isEmpty);
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
