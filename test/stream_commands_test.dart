import 'dart:typed_data';

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

    test('xCfgSet builds XCFGSET with idmp options', () async {
      final executor = _FakeStreamExecutor()..response = 'OK';

      final result = await executor.xCfgSet(
        'stream:{1}',
        idmpDuration: 30,
        idmpMaxSize: 1000,
      );

      expect(result, 'OK');
      expect(
        executor.lastCommand,
        ['XCFGSET', 'stream:{1}', 'IDMP-DURATION', 30, 'IDMP-MAXSIZE', 1000],
      );
    });

    test('xCfgSet requires at least one idmp option', () {
      final executor = _FakeStreamExecutor();

      expect(
        () => executor.xCfgSet('stream:{1}'),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            'At least one of idmpDuration or idmpMaxSize must be provided.',
          ),
        ),
      );
    });

    test('xDelEx builds XDELEX with policy and ids block', () async {
      final executor = _FakeStreamExecutor()..response = [1, -1, 2];

      final result = await executor.xDelEx(
        'stream:{1}',
        ['1-0', '2-0', '3-0'],
        policy: StreamDeletionPolicy.acked,
      );

      expect(result, [1, -1, 2]);
      expect(
        executor.lastCommand,
        ['XDELEX', 'stream:{1}', 'ACKED', 'IDS', 3, '1-0', '2-0', '3-0'],
      );
    });

    test('xAckDel builds XACKDEL with policy and ids block', () async {
      final executor = _FakeStreamExecutor()..response = [1, 1];

      final result = await executor.xAckDel(
        'stream:{1}',
        'group-a',
        ['1-0', '2-0'],
        policy: StreamDeletionPolicy.delRef,
      );

      expect(result, [1, 1]);
      expect(
        executor.lastCommand,
        ['XACKDEL', 'stream:{1}', 'group-a', 'DELREF', 'IDS', 2, '1-0', '2-0'],
      );
    });

    test('bytes helpers preserve stream field payloads', () async {
      final executor = _FakeStreamExecutor()
        ..response = [
          [
            '1-0',
            [
              Uint8List.fromList([1]),
              Uint8List.fromList([2, 3]),
            ],
          ],
        ];

      final range = await executor.xRangeBytes('stream:{1}', '-', '+', count: 1);
      expect(range.single.id, '1-0');
      expect(range.single.fields.single.key, Uint8List.fromList([1]));
      expect(range.single.fields.single.value, Uint8List.fromList([2, 3]));
      expect(executor.lastCommand, ['XRANGE', 'stream:{1}', '-', '+', 'COUNT', '1']);

      executor.response = [
        [
          'stream:{1}',
          [
            [
              '2-0',
              [
                Uint8List.fromList([4]),
                Uint8List.fromList([5]),
              ],
            ],
          ],
        ],
      ];
      final read = await executor.xReadBytes(
        count: 1,
        keys: ['stream:{1}'],
        ids: ['0-0'],
      );
      expect(read.single.keys.single, 'stream:{1}');
      expect(
        read.single.values.single.single.fields.single.key,
        Uint8List.fromList([4]),
      );
      expect(
        read.single.values.single.single.fields.single.value,
        Uint8List.fromList([5]),
      );
      expect(
        executor.lastCommand,
        ['XREAD', 'COUNT', '1', 'STREAMS', 'stream:{1}', '0-0'],
      );

      executor.response = [
        '0-0',
        [
          [
            '3-0',
            [
              Uint8List.fromList([6]),
              Uint8List.fromList([7]),
            ],
          ],
        ],
      ];
      final autoClaim = await executor.xAutoClaimBytes(
        'stream:{1}',
        'group-a',
        'consumer-a',
        5000,
        '0-0',
        count: 1,
      );
      expect(autoClaim.single.id, '3-0');
      expect(
        autoClaim.single.fields.single.key,
        Uint8List.fromList([6]),
      );
      expect(
        autoClaim.single.fields.single.value,
        Uint8List.fromList([7]),
      );
      expect(
        executor.lastCommand,
        ['XAUTOCLAIM', 'stream:{1}', 'group-a', 'consumer-a', 5000, '0-0', 'COUNT', 1],
      );
    });
  });
}
