import 'dart:typed_data';

import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

class _FakeVectorSetExecutor extends RedisCommandExecutor
    with RedisVectorSetCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

void main() {
  group('RedisVectorSetCommands', () {
    test('vAddValues builds VADD VALUES with explicit options', () async {
      final executor = _FakeVectorSetExecutor()..response = 1;

      final added = await executor.vAddValues(
        'embeddings:{1}',
        'doc:1',
        [1, 2, 3],
        options: const VectorSetAddOptions(
          reduce: 3,
          cas: true,
          quantization: VectorSetQuantization.bin,
          ef: 250,
          attributes: '{"kind":"doc"}',
          m: 32,
        ),
      );

      expect(added, isTrue);
      expect(executor.lastCommand, [
        'VADD',
        'embeddings:{1}',
        'REDUCE',
        3,
        'VALUES',
        3,
        1,
        2,
        3,
        'doc:1',
        'CAS',
        'BIN',
        'EF',
        250,
        'SETATTR',
        '{"kind":"doc"}',
        'M',
        32,
      ]);
    });

    test('vAddFp32 builds VADD FP32 with raw bytes', () async {
      final executor = _FakeVectorSetExecutor()..response = true;
      final vector = Uint8List.fromList([1, 2, 3, 4]);

      final added = await executor.vAddFp32(
        'embeddings:{1}',
        'doc:2',
        vector,
      );

      expect(added, isTrue);
      expect(executor.lastCommand, ['VADD', 'embeddings:{1}', 'FP32', vector, 'doc:2']);
    });

    test('vEmb and vEmbRaw normalize vector replies', () async {
      final executor = _FakeVectorSetExecutor()..response = ['1.5', 2, '3.25'];

      final embedding = await executor.vEmb('embeddings:{1}', 'doc:1');
      expect(embedding, [1.5, 2.0, 3.25]);
      expect(executor.lastCommand, ['VEMB', 'embeddings:{1}', 'doc:1']);

      executor.response = ['q8', 'raw-bytes', '1.5', '0.25'];
      final raw = await executor.vEmbRaw('embeddings:{1}', 'doc:1');
      expect(raw, isNotNull);
      expect(raw!.quantizationType, 'q8');
      expect(raw.data, 'raw-bytes');
      expect(raw.norm, 1.5);
      expect(raw.range, 0.25);
      expect(executor.lastCommand, ['VEMB', 'embeddings:{1}', 'doc:1', 'RAW']);
    });

    test('vSimElement builds VSIM and decodes scored attribute matches', () async {
      final executor = _FakeVectorSetExecutor()
        ..response = [
          'doc:1',
          '0.99',
          '{"kind":"doc"}',
          'doc:2',
          0.75,
          null,
        ];

      final matches = await executor.vSimElement(
        'embeddings:{1}',
        'doc:0',
        options: const VectorSetSimilarityOptions(
          withScores: true,
          withAttributes: true,
          count: 2,
          epsilon: 0.2,
          ef: 128,
          filter: '@kind == "doc"',
          filterEf: 64,
          truth: true,
          noThread: true,
        ),
      );

      expect(matches.length, 2);
      expect(matches.first.element, 'doc:1');
      expect(matches.first.score, 0.99);
      expect(matches.first.attributes, '{"kind":"doc"}');
      expect(matches.last.element, 'doc:2');
      expect(matches.last.score, 0.75);
      expect(matches.last.attributes, isNull);
      expect(executor.lastCommand, [
        'VSIM',
        'embeddings:{1}',
        'ELE',
        'doc:0',
        'WITHSCORES',
        'WITHATTRIBS',
        'COUNT',
        2,
        'EPSILON',
        0.2,
        'EF',
        128,
        'FILTER',
        '@kind == "doc"',
        'FILTER-EF',
        64,
        'TRUTH',
        'NOTHREAD',
      ]);
    });

    test('vLinks and vInfo normalize nested replies', () async {
      final executor = _FakeVectorSetExecutor()
        ..response = [
          ['doc:2', '0.8', 'doc:3', 0.5],
          ['doc:4', '0.4'],
        ];

      final links = await executor.vLinks(
        'embeddings:{1}',
        'doc:1',
        withScores: true,
      );

      expect(links.length, 2);
      expect(links.first.first.element, 'doc:2');
      expect(links.first.first.score, 0.8);
      expect(links.first.last.element, 'doc:3');
      expect(links.first.last.score, 0.5);
      expect(executor.lastCommand, [
        'VLINKS',
        'embeddings:{1}',
        'doc:1',
        'WITHSCORES',
      ]);

      executor.response = [
        'quant-type',
        'q8',
        'vector-dim',
        768,
        'size',
        12,
      ];
      final info = await executor.vInfo('embeddings:{1}');
      expect(info, {
        'quant-type': 'q8',
        'vector-dim': 768,
        'size': 12,
      });
      expect(executor.lastCommand, ['VINFO', 'embeddings:{1}']);
    });

    test('scalar helpers build exact commands', () async {
      final executor = _FakeVectorSetExecutor()..response = 'doc:2';

      expect(await executor.vRandMember('embeddings:{1}'), ['doc:2']);
      expect(executor.lastCommand, ['VRANDMEMBER', 'embeddings:{1}']);

      executor.response = ['doc:1', 'doc:2'];
      expect(
        await executor.vRange('embeddings:{1}', 'a', 'z', count: 2),
        ['doc:1', 'doc:2'],
      );
      expect(executor.lastCommand, ['VRANGE', 'embeddings:{1}', 'a', 'z', 2]);

      executor.response = 1;
      expect(await executor.vSetAttr('embeddings:{1}', 'doc:1', '{"kind":"doc"}'), isTrue);
      expect(
        executor.lastCommand,
        ['VSETATTR', 'embeddings:{1}', 'doc:1', '{"kind":"doc"}'],
      );
    });
  });
}
