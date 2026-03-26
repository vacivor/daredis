import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

class _FakeTimeSeriesExecutor extends RedisCommandExecutor
    with RedisTimeSeriesCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

void main() {
  group('RedisTimeSeriesCommands', () {
    test('tsCreate and tsAlter build exact commands', () async {
      final executor = _FakeTimeSeriesExecutor()..response = 'OK';

      expect(
        await executor.tsCreate(
          'series:{1}',
          options: const TimeSeriesCreateOptions(
            retention: 60000,
            encoding: TimeSeriesEncoding.uncompressed,
            chunkSize: 4096,
            duplicatePolicy: TimeSeriesDuplicatePolicy.last,
            ignoreMaxTimeDiff: 10,
            ignoreMaxValDiff: 2,
            labels: {'sensor': 's1', 'site': 'lab'},
          ),
        ),
        'OK',
      );
      expect(executor.lastCommand, [
        'TS.CREATE',
        'series:{1}',
        'RETENTION',
        60000,
        'ENCODING',
        'UNCOMPRESSED',
        'CHUNK_SIZE',
        4096,
        'DUPLICATE_POLICY',
        'LAST',
        'IGNORE',
        10,
        2,
        'LABELS',
        'sensor',
        's1',
        'site',
        'lab',
      ]);

      expect(
        await executor.tsAlter(
          'series:{1}',
          options: const TimeSeriesAlterOptions(
            retention: 30000,
            chunkSize: 2048,
            duplicatePolicy: TimeSeriesDuplicatePolicy.max,
            labels: {'room': 'r1'},
          ),
        ),
        'OK',
      );
      expect(executor.lastCommand, [
        'TS.ALTER',
        'series:{1}',
        'RETENTION',
        30000,
        'CHUNK_SIZE',
        2048,
        'DUPLICATE_POLICY',
        'MAX',
        'LABELS',
        'room',
        'r1',
      ]);
    });

    test('tsAdd tsMAdd tsIncrBy tsDecrBy build write commands', () async {
      final executor = _FakeTimeSeriesExecutor()..response = 42;

      expect(
        await executor.tsAdd(
          'series:{1}',
          '*',
          12.5,
          options: const TimeSeriesAddOptions(
            retention: 1000,
            onDuplicate: TimeSeriesDuplicatePolicy.first,
          ),
        ),
        42,
      );
      expect(executor.lastCommand, [
        'TS.ADD',
        'series:{1}',
        '*',
        12.5,
        'RETENTION',
        1000,
        'ON_DUPLICATE',
        'FIRST',
      ]);

      executor.response = [1, 2];
      expect(
        await executor.tsMAdd([
          const TimeSeriesMAddSample(
            key: 'series:{1}',
            timestamp: 1,
            value: 10,
          ),
          const TimeSeriesMAddSample(
            key: 'series:{2}',
            timestamp: 2,
            value: 20,
          ),
        ]),
        [1, 2],
      );
      expect(executor.lastCommand, [
        'TS.MADD',
        'series:{1}',
        1,
        10,
        'series:{2}',
        2,
        20,
      ]);

      executor.response = 100;
      expect(
        await executor.tsIncrBy(
          'counter:{1}',
          2,
          options: const TimeSeriesIncrementOptions(timestamp: 123),
        ),
        100,
      );
      expect(executor.lastCommand, [
        'TS.INCRBY',
        'counter:{1}',
        2,
        'TIMESTAMP',
        123,
      ]);

      expect(
        await executor.tsDecrBy('counter:{1}', 1),
        100,
      );
      expect(executor.lastCommand, ['TS.DECRBY', 'counter:{1}', 1]);
    });

    test('tsGet tsRange and tsRevRange parse samples', () async {
      final executor = _FakeTimeSeriesExecutor()..response = [1234, '1.5'];

      final sample = await executor.tsGet('series:{1}', latest: true);
      expect(sample, isNotNull);
      expect(sample!.timestamp, 1234);
      expect(sample.value, 1.5);
      expect(executor.lastCommand, ['TS.GET', 'series:{1}', 'LATEST']);

      executor.response = [
        [1234, '1.5'],
        [1235, 2],
      ];
      final range = await executor.tsRange(
        'series:{1}',
        '-',
        '+',
        options: const TimeSeriesRangeOptions(
          latest: true,
          filterByTimestamps: [1234, 1235],
          minValue: 1,
          maxValue: 2,
          count: 100,
          aggregation: TimeSeriesAggregation(
            type: TimeSeriesAggregationType.avg,
            bucketDuration: 60000,
            align: 0,
            bucketTimestamp: TimeSeriesBucketTimestamp.end,
            empty: true,
          ),
        ),
      );
      expect(range.map((item) => item.timestamp), [1234, 1235]);
      expect(range.map((item) => item.value), [1.5, 2.0]);
      expect(executor.lastCommand, [
        'TS.RANGE',
        'series:{1}',
        '-',
        '+',
        'LATEST',
        'FILTER_BY_TS',
        1234,
        1235,
        'FILTER_BY_VALUE',
        1,
        2,
        'COUNT',
        100,
        'ALIGN',
        0,
        'AGGREGATION',
        'AVG',
        60000,
        'BUCKETTIMESTAMP',
        'END',
        'EMPTY',
      ]);

      executor.response = [
        [1235, '2.5'],
      ];
      final revRange = await executor.tsRevRange('series:{1}', '+', '-');
      expect(revRange.single.value, 2.5);
      expect(executor.lastCommand, ['TS.REVRANGE', 'series:{1}', '+', '-']);
    });

    test('tsMGet tsMRange and tsMRevRange build and decode results', () async {
      final executor = _FakeTimeSeriesExecutor()
        ..response = [
          [
            'series:{1}',
            [
              ['sensor', 's1'],
              ['room', 'r1'],
            ],
            [10, '1.5'],
          ],
        ];

      final mget = await executor.tsMGet(
        ['sensor=s1'],
        options: const TimeSeriesMGetOptions(
          latest: true,
          selectedLabels: ['sensor', 'room'],
        ),
      );
      expect(mget.single.key, 'series:{1}');
      expect(mget.single.labels, {'sensor': 's1', 'room': 'r1'});
      expect(mget.single.sample!.timestamp, 10);
      expect(executor.lastCommand, [
        'TS.MGET',
        'LATEST',
        'SELECTED_LABELS',
        'sensor',
        'room',
        'FILTER',
        'sensor=s1',
      ]);

      executor.response = [
        [
          'series:{1}',
          [
            ['sensor', 's1'],
          ],
          [
            [10, '1.5'],
            [20, '2.5'],
          ],
        ],
      ];
      final mrange = await executor.tsMRange(
        '-',
        '+',
        ['sensor=s1'],
        options: const TimeSeriesMultiRangeOptions(
          withLabels: true,
          groupBy: 'sensor',
          reducer: TimeSeriesAggregationType.max,
        ),
      );
      expect(mrange.single.key, 'series:{1}');
      expect(mrange.single.samples.map((item) => item.value), [1.5, 2.5]);
      expect(executor.lastCommand, [
        'TS.MRANGE',
        '-',
        '+',
        'WITHLABELS',
        'FILTER',
        'sensor=s1',
        'GROUPBY',
        'sensor',
        'REDUCE',
        'MAX',
      ]);

      executor.response = {
        'sensor=s1': [
          [
            ['sensor', 's1'],
          ],
          [
            [20, '2.5'],
          ],
        ],
      };
      final mrevrange = await executor.tsMRevRange(
        '+',
        '-',
        ['sensor=s1'],
      );
      expect(mrevrange.single.key, 'sensor=s1');
      expect(mrevrange.single.samples.single.timestamp, 20);
      expect(executor.lastCommand, [
        'TS.MREVRANGE',
        '+',
        '-',
        'FILTER',
        'sensor=s1',
      ]);
    });

    test('tsInfo tsQueryIndex tsCreateRule and tsDeleteRule parse and build', () async {
      final executor = _FakeTimeSeriesExecutor()
        ..response = [
          'totalSamples',
          2,
          'labels',
          [
            ['sensor', 's1'],
          ],
          'memoryUsage',
          128,
        ];

      final info = await executor.tsInfo('series:{1}', debug: true);
      expect(info['totalSamples'], 2);
      expect(info['labels'], {'sensor': 's1'});
      expect(executor.lastCommand, ['TS.INFO', 'series:{1}', 'DEBUG']);

      executor.response = ['series:{1}', 'series:{2}'];
      expect(await executor.tsQueryIndex(['sensor=s1']), ['series:{1}', 'series:{2}']);
      expect(executor.lastCommand, ['TS.QUERYINDEX', 'sensor=s1']);

      executor.response = 'OK';
      expect(
        await executor.tsCreateRule(
          'source:{1}',
          'dest:{1}',
          TimeSeriesAggregationType.avg,
          60000,
          alignTimestamp: 0,
        ),
        'OK',
      );
      expect(executor.lastCommand, [
        'TS.CREATERULE',
        'source:{1}',
        'dest:{1}',
        'AGGREGATION',
        'AVG',
        60000,
        0,
      ]);

      expect(await executor.tsDeleteRule('source:{1}', 'dest:{1}'), 'OK');
      expect(executor.lastCommand, ['TS.DELETERULE', 'source:{1}', 'dest:{1}']);
    });

    test('tsMGet and tsMRange validate incompatible options', () {
      final executor = _FakeTimeSeriesExecutor();

      expect(
        () => executor.tsMGet(
          ['sensor=s1'],
          options: const TimeSeriesMGetOptions(
            withLabels: true,
            selectedLabels: ['sensor'],
          ),
        ),
        throwsArgumentError,
      );

      expect(
        () => executor.tsMRange(
          '-',
          '+',
          ['sensor=s1'],
          options: const TimeSeriesMultiRangeOptions(groupBy: 'sensor'),
        ),
        throwsArgumentError,
      );
    });
  });
}
