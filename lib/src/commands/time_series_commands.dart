part of '../../daredis.dart';

enum TimeSeriesEncoding { compressed, uncompressed }

enum TimeSeriesDuplicatePolicy { block, first, last, min, max, sum }

enum TimeSeriesAggregationType {
  avg,
  sum,
  min,
  max,
  range,
  count,
  countNaN,
  countAll,
  first,
  last,
  stdP,
  stdS,
  varP,
  varS,
  twa,
}

enum TimeSeriesBucketTimestamp { start, end, mid }

class TimeSeriesSample {
  final int timestamp;
  final double value;

  const TimeSeriesSample(this.timestamp, this.value);
}

class TimeSeriesMAddSample {
  final String key;
  final dynamic timestamp;
  final num value;

  const TimeSeriesMAddSample({
    required this.key,
    required this.timestamp,
    required this.value,
  });
}

class TimeSeriesMGetResult {
  final String key;
  final Map<String, String?> labels;
  final TimeSeriesSample? sample;

  const TimeSeriesMGetResult({
    required this.key,
    required this.labels,
    required this.sample,
  });
}

class TimeSeriesRangeResult {
  final String key;
  final Map<String, String?> labels;
  final List<TimeSeriesSample> samples;

  const TimeSeriesRangeResult({
    required this.key,
    required this.labels,
    required this.samples,
  });
}

class TimeSeriesAggregation {
  final TimeSeriesAggregationType type;
  final int bucketDuration;
  final dynamic align;
  final TimeSeriesBucketTimestamp? bucketTimestamp;
  final bool empty;

  const TimeSeriesAggregation({
    required this.type,
    required this.bucketDuration,
    this.align,
    this.bucketTimestamp,
    this.empty = false,
  });
}

class TimeSeriesCreateOptions {
  final int? retention;
  final TimeSeriesEncoding? encoding;
  final int? chunkSize;
  final TimeSeriesDuplicatePolicy? duplicatePolicy;
  final int? ignoreMaxTimeDiff;
  final num? ignoreMaxValDiff;
  final Map<String, String>? labels;

  const TimeSeriesCreateOptions({
    this.retention,
    this.encoding,
    this.chunkSize,
    this.duplicatePolicy,
    this.ignoreMaxTimeDiff,
    this.ignoreMaxValDiff,
    this.labels,
  });
}

class TimeSeriesAddOptions extends TimeSeriesCreateOptions {
  final TimeSeriesDuplicatePolicy? onDuplicate;

  const TimeSeriesAddOptions({
    super.retention,
    super.encoding,
    super.chunkSize,
    super.duplicatePolicy,
    super.ignoreMaxTimeDiff,
    super.ignoreMaxValDiff,
    super.labels,
    this.onDuplicate,
  });
}

class TimeSeriesAlterOptions {
  final int? retention;
  final int? chunkSize;
  final TimeSeriesDuplicatePolicy? duplicatePolicy;
  final Map<String, String>? labels;

  const TimeSeriesAlterOptions({
    this.retention,
    this.chunkSize,
    this.duplicatePolicy,
    this.labels,
  });
}

class TimeSeriesIncrementOptions extends TimeSeriesCreateOptions {
  final dynamic timestamp;

  const TimeSeriesIncrementOptions({
    this.timestamp,
    super.retention,
    super.encoding,
    super.chunkSize,
    super.duplicatePolicy,
    super.ignoreMaxTimeDiff,
    super.ignoreMaxValDiff,
    super.labels,
  });
}

class TimeSeriesMGetOptions {
  final bool latest;
  final bool withLabels;
  final List<String>? selectedLabels;

  const TimeSeriesMGetOptions({
    this.latest = false,
    this.withLabels = false,
    this.selectedLabels,
  });
}

class TimeSeriesRangeOptions {
  final bool latest;
  final List<int>? filterByTimestamps;
  final num? minValue;
  final num? maxValue;
  final int? count;
  final TimeSeriesAggregation? aggregation;

  const TimeSeriesRangeOptions({
    this.latest = false,
    this.filterByTimestamps,
    this.minValue,
    this.maxValue,
    this.count,
    this.aggregation,
  });
}

class TimeSeriesMultiRangeOptions extends TimeSeriesRangeOptions {
  final bool withLabels;
  final List<String>? selectedLabels;
  final String? groupBy;
  final TimeSeriesAggregationType? reducer;

  const TimeSeriesMultiRangeOptions({
    super.latest,
    super.filterByTimestamps,
    super.minValue,
    super.maxValue,
    super.count,
    super.aggregation,
    this.withLabels = false,
    this.selectedLabels,
    this.groupBy,
    this.reducer,
  });
}

String _timeSeriesEncodingArg(TimeSeriesEncoding value) {
  switch (value) {
    case TimeSeriesEncoding.compressed:
      return 'COMPRESSED';
    case TimeSeriesEncoding.uncompressed:
      return 'UNCOMPRESSED';
  }
}

String _timeSeriesDuplicatePolicyArg(TimeSeriesDuplicatePolicy value) {
  switch (value) {
    case TimeSeriesDuplicatePolicy.block:
      return 'BLOCK';
    case TimeSeriesDuplicatePolicy.first:
      return 'FIRST';
    case TimeSeriesDuplicatePolicy.last:
      return 'LAST';
    case TimeSeriesDuplicatePolicy.min:
      return 'MIN';
    case TimeSeriesDuplicatePolicy.max:
      return 'MAX';
    case TimeSeriesDuplicatePolicy.sum:
      return 'SUM';
  }
}

String _timeSeriesAggregationArg(TimeSeriesAggregationType value) {
  switch (value) {
    case TimeSeriesAggregationType.avg:
      return 'AVG';
    case TimeSeriesAggregationType.sum:
      return 'SUM';
    case TimeSeriesAggregationType.min:
      return 'MIN';
    case TimeSeriesAggregationType.max:
      return 'MAX';
    case TimeSeriesAggregationType.range:
      return 'RANGE';
    case TimeSeriesAggregationType.count:
      return 'COUNT';
    case TimeSeriesAggregationType.countNaN:
      return 'COUNTNAN';
    case TimeSeriesAggregationType.countAll:
      return 'COUNTALL';
    case TimeSeriesAggregationType.first:
      return 'FIRST';
    case TimeSeriesAggregationType.last:
      return 'LAST';
    case TimeSeriesAggregationType.stdP:
      return 'STD.P';
    case TimeSeriesAggregationType.stdS:
      return 'STD.S';
    case TimeSeriesAggregationType.varP:
      return 'VAR.P';
    case TimeSeriesAggregationType.varS:
      return 'VAR.S';
    case TimeSeriesAggregationType.twa:
      return 'TWA';
  }
}

String _timeSeriesBucketTimestampArg(TimeSeriesBucketTimestamp value) {
  switch (value) {
    case TimeSeriesBucketTimestamp.start:
      return 'START';
    case TimeSeriesBucketTimestamp.end:
      return 'END';
    case TimeSeriesBucketTimestamp.mid:
      return 'MID';
  }
}

void _appendTimeSeriesLabels(
  List<dynamic> args,
  Map<String, String>? labels,
) {
  if (labels == null || labels.isEmpty) {
    return;
  }
  args.add('LABELS');
  labels.forEach((key, value) {
    args.addAll([key, value]);
  });
}

void _appendTimeSeriesCreateOptions(
  List<dynamic> args,
  TimeSeriesCreateOptions options,
) {
  if (options.retention != null) {
    args.addAll(['RETENTION', options.retention]);
  }
  if (options.encoding != null) {
    args.addAll(['ENCODING', _timeSeriesEncodingArg(options.encoding!)]);
  }
  if (options.chunkSize != null) {
    args.addAll(['CHUNK_SIZE', options.chunkSize]);
  }
  if (options.duplicatePolicy != null) {
    args.addAll([
      'DUPLICATE_POLICY',
      _timeSeriesDuplicatePolicyArg(options.duplicatePolicy!),
    ]);
  }
  if (options.ignoreMaxTimeDiff != null || options.ignoreMaxValDiff != null) {
    if (options.ignoreMaxTimeDiff == null || options.ignoreMaxValDiff == null) {
      throw ArgumentError(
        'IGNORE requires both ignoreMaxTimeDiff and ignoreMaxValDiff',
      );
    }
    args.addAll([
      'IGNORE',
      options.ignoreMaxTimeDiff,
      options.ignoreMaxValDiff,
    ]);
  }
  _appendTimeSeriesLabels(args, options.labels);
}

void _appendTimeSeriesRangeOptions(
  List<dynamic> args,
  TimeSeriesRangeOptions options,
) {
  if (options.latest) {
    args.add('LATEST');
  }
  if (options.filterByTimestamps != null &&
      options.filterByTimestamps!.isNotEmpty) {
    args.addAll(['FILTER_BY_TS', ...options.filterByTimestamps!]);
  }
  if (options.minValue != null || options.maxValue != null) {
    if (options.minValue == null || options.maxValue == null) {
      throw ArgumentError(
        'FILTER_BY_VALUE requires both minValue and maxValue',
      );
    }
    args.addAll(['FILTER_BY_VALUE', options.minValue, options.maxValue]);
  }
  if (options.count != null) {
    args.addAll(['COUNT', options.count]);
  }
  final aggregation = options.aggregation;
  if (aggregation != null) {
    if (aggregation.align != null) {
      args.addAll(['ALIGN', aggregation.align]);
    }
    args.addAll([
      'AGGREGATION',
      _timeSeriesAggregationArg(aggregation.type),
      aggregation.bucketDuration,
    ]);
    if (aggregation.bucketTimestamp != null) {
      args.addAll([
        'BUCKETTIMESTAMP',
        _timeSeriesBucketTimestampArg(aggregation.bucketTimestamp!),
      ]);
    }
    if (aggregation.empty) {
      args.add('EMPTY');
    }
  }
}

void _appendTimeSeriesLabelSelection(
  List<dynamic> args, {
  required bool withLabels,
  required List<String>? selectedLabels,
}) {
  if (withLabels && selectedLabels != null && selectedLabels.isNotEmpty) {
    throw ArgumentError('WITHLABELS cannot be combined with SELECTED_LABELS');
  }
  if (withLabels) {
    args.add('WITHLABELS');
  } else if (selectedLabels != null && selectedLabels.isNotEmpty) {
    args.addAll(['SELECTED_LABELS', ...selectedLabels]);
  }
}

Map<String, String?> _timeSeriesLabels(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        Decoders.string(key),
        nestedValue == null ? null : Decoders.string(nestedValue),
      ),
    );
  }
  final labels = <String, String?>{};
  if (value is List) {
    for (final entry in value) {
      if (entry is List && entry.isNotEmpty) {
        final key = Decoders.string(entry[0]);
        final nestedValue = entry.length > 1 ? entry[1] : null;
        labels[key] = nestedValue == null ? null : Decoders.string(nestedValue);
      }
    }
  }
  return labels;
}

TimeSeriesSample? _timeSeriesSample(dynamic value) {
  if (value is! List || value.length < 2) {
    return null;
  }
  return TimeSeriesSample(
    Decoders.toInt(value[0]),
    Decoders.toDouble(value[1]),
  );
}

List<TimeSeriesSample> _timeSeriesSamples(dynamic value) {
  if (value is! List) {
    return const <TimeSeriesSample>[];
  }
  return value
      .map(_timeSeriesSample)
      .whereType<TimeSeriesSample>()
      .toList(growable: false);
}

Map<String, dynamic> _timeSeriesFlatMap(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(Decoders.string(key), nestedValue),
    );
  }
  if (value is! List || value.length.isOdd) {
    throw DaredisProtocolException(
      'Unexpected time series response type: ${value.runtimeType}',
    );
  }
  final map = <String, dynamic>{};
  for (var i = 0; i < value.length; i += 2) {
    map[Decoders.string(value[i])] = value[i + 1];
  }
  return map;
}

Map<String, dynamic> _timeSeriesInfo(dynamic value) {
  final map = _timeSeriesFlatMap(value);
  if (map.containsKey('labels')) {
    map['labels'] = _timeSeriesLabels(map['labels']);
  }
  return map;
}

TimeSeriesMGetResult _timeSeriesMGetEntry(String key, dynamic value) {
  if (value is List && value.length >= 2) {
    return TimeSeriesMGetResult(
      key: key,
      labels: _timeSeriesLabels(value[0]),
      sample: _timeSeriesSample(value[1]),
    );
  }
  if (value is Map) {
    final labels = value['labels'] ?? value['Labels'] ?? value['labelsValues'];
    final sample = value['value'] ?? value['sample'];
    return TimeSeriesMGetResult(
      key: key,
      labels: _timeSeriesLabels(labels),
      sample: _timeSeriesSample(sample),
    );
  }
  return TimeSeriesMGetResult(
    key: key,
    labels: const <String, String?>{},
    sample: null,
  );
}

List<TimeSeriesMGetResult> _timeSeriesMGetResults(dynamic value) {
  if (value is Map) {
    return value.entries
        .map((entry) => _timeSeriesMGetEntry(Decoders.string(entry.key), entry.value))
        .toList(growable: false);
  }
  if (value is! List) {
    return const <TimeSeriesMGetResult>[];
  }
  return value
      .whereType<List>()
      .map((entry) => TimeSeriesMGetResult(
            key: Decoders.string(entry[0]),
            labels: entry.length > 1
                ? _timeSeriesLabels(entry[1])
                : const <String, String?>{},
            sample: entry.length > 2 ? _timeSeriesSample(entry[2]) : null,
          ))
      .toList(growable: false);
}

TimeSeriesRangeResult _timeSeriesRangeEntry(String key, dynamic value) {
  if (value is List && value.length >= 2) {
    return TimeSeriesRangeResult(
      key: key,
      labels: _timeSeriesLabels(value[0]),
      samples: _timeSeriesSamples(value[1]),
    );
  }
  if (value is Map) {
    final labels = value['labels'] ?? value['Labels'];
    final samples = value['values'] ?? value['samples'];
    return TimeSeriesRangeResult(
      key: key,
      labels: _timeSeriesLabels(labels),
      samples: _timeSeriesSamples(samples),
    );
  }
  return TimeSeriesRangeResult(
    key: key,
    labels: const <String, String?>{},
    samples: const <TimeSeriesSample>[],
  );
}

List<TimeSeriesRangeResult> _timeSeriesRangeResults(dynamic value) {
  if (value is Map) {
    return value.entries
        .map(
          (entry) => _timeSeriesRangeEntry(Decoders.string(entry.key), entry.value),
        )
        .toList(growable: false);
  }
  if (value is! List) {
    return const <TimeSeriesRangeResult>[];
  }
  return value
      .whereType<List>()
      .map((entry) => TimeSeriesRangeResult(
            key: Decoders.string(entry[0]),
            labels: entry.length > 1
                ? _timeSeriesLabels(entry[1])
                : const <String, String?>{},
            samples: entry.length > 2
                ? _timeSeriesSamples(entry[2])
                : const <TimeSeriesSample>[],
          ))
      .toList(growable: false);
}

mixin RedisTimeSeriesCommands on RedisCommandExecutor {
  Future<String> tsCreate(
    String key, {
    TimeSeriesCreateOptions options = const TimeSeriesCreateOptions(),
  }) async {
    final args = <dynamic>['TS.CREATE', key];
    _appendTimeSeriesCreateOptions(args, options);
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<String> tsAlter(
    String key, {
    TimeSeriesAlterOptions options = const TimeSeriesAlterOptions(),
  }) async {
    final args = <dynamic>['TS.ALTER', key];
    if (options.retention != null) {
      args.addAll(['RETENTION', options.retention]);
    }
    if (options.chunkSize != null) {
      args.addAll(['CHUNK_SIZE', options.chunkSize]);
    }
    if (options.duplicatePolicy != null) {
      args.addAll([
        'DUPLICATE_POLICY',
        _timeSeriesDuplicatePolicyArg(options.duplicatePolicy!),
      ]);
    }
    _appendTimeSeriesLabels(args, options.labels);
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<int> tsAdd(
    String key,
    dynamic timestamp,
    num value, {
    TimeSeriesAddOptions options = const TimeSeriesAddOptions(),
  }) async {
    final args = <dynamic>['TS.ADD', key, timestamp, value];
    _appendTimeSeriesCreateOptions(args, options);
    if (options.onDuplicate != null) {
      args.addAll([
        'ON_DUPLICATE',
        _timeSeriesDuplicatePolicyArg(options.onDuplicate!),
      ]);
    }
    final res = await sendCommand(args);
    return Decoders.toInt(res);
  }

  Future<List<int>> tsMAdd(List<TimeSeriesMAddSample> samples) async {
    if (samples.isEmpty) {
      throw ArgumentError.value(samples, 'samples', 'must not be empty');
    }
    final args = <dynamic>['TS.MADD'];
    for (final sample in samples) {
      args.addAll([sample.key, sample.timestamp, sample.value]);
    }
    final res = await sendCommand(args);
    if (res is! List) {
      return const <int>[];
    }
    return res.map(Decoders.toInt).toList(growable: false);
  }

  Future<int> tsIncrBy(
    String key,
    num addend, {
    TimeSeriesIncrementOptions options = const TimeSeriesIncrementOptions(),
  }) async {
    final args = <dynamic>['TS.INCRBY', key, addend];
    if (options.timestamp != null) {
      args.addAll(['TIMESTAMP', options.timestamp]);
    }
    _appendTimeSeriesCreateOptions(args, options);
    final res = await sendCommand(args);
    return Decoders.toInt(res);
  }

  Future<int> tsDecrBy(
    String key,
    num decrement, {
    TimeSeriesIncrementOptions options = const TimeSeriesIncrementOptions(),
  }) async {
    final args = <dynamic>['TS.DECRBY', key, decrement];
    if (options.timestamp != null) {
      args.addAll(['TIMESTAMP', options.timestamp]);
    }
    _appendTimeSeriesCreateOptions(args, options);
    final res = await sendCommand(args);
    return Decoders.toInt(res);
  }

  Future<int> tsDel(String key, dynamic fromTimestamp, dynamic toTimestamp) async {
    final res = await sendCommand(['TS.DEL', key, fromTimestamp, toTimestamp]);
    return Decoders.toInt(res);
  }

  Future<String> tsCreateRule(
    String sourceKey,
    String destKey,
    TimeSeriesAggregationType aggregation,
    int bucketDuration, {
    int? alignTimestamp,
  }) async {
    final args = <dynamic>[
      'TS.CREATERULE',
      sourceKey,
      destKey,
      'AGGREGATION',
      _timeSeriesAggregationArg(aggregation),
      bucketDuration,
    ];
    if (alignTimestamp != null) {
      args.add(alignTimestamp);
    }
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<String> tsDeleteRule(String sourceKey, String destKey) async {
    final res = await sendCommand(['TS.DELETERULE', sourceKey, destKey]);
    return Decoders.string(res);
  }

  Future<TimeSeriesSample?> tsGet(String key, {bool latest = false}) async {
    final args = <dynamic>['TS.GET', key];
    if (latest) {
      args.add('LATEST');
    }
    final res = await sendCommand(args);
    return _timeSeriesSample(res);
  }

  Future<Map<String, dynamic>> tsInfo(String key, {bool debug = false}) async {
    final args = <dynamic>['TS.INFO', key];
    if (debug) {
      args.add('DEBUG');
    }
    final res = await sendCommand(args);
    return _timeSeriesInfo(res);
  }

  Future<List<TimeSeriesSample>> tsRange(
    String key,
    dynamic fromTimestamp,
    dynamic toTimestamp, {
    TimeSeriesRangeOptions options = const TimeSeriesRangeOptions(),
  }) async {
    final args = <dynamic>['TS.RANGE', key, fromTimestamp, toTimestamp];
    _appendTimeSeriesRangeOptions(args, options);
    final res = await sendCommand(args);
    return _timeSeriesSamples(res);
  }

  Future<List<TimeSeriesSample>> tsRevRange(
    String key,
    dynamic fromTimestamp,
    dynamic toTimestamp, {
    TimeSeriesRangeOptions options = const TimeSeriesRangeOptions(),
  }) async {
    final args = <dynamic>['TS.REVRANGE', key, fromTimestamp, toTimestamp];
    _appendTimeSeriesRangeOptions(args, options);
    final res = await sendCommand(args);
    return _timeSeriesSamples(res);
  }

  Future<List<TimeSeriesMGetResult>> tsMGet(
    List<String> filters, {
    TimeSeriesMGetOptions options = const TimeSeriesMGetOptions(),
  }) async {
    if (filters.isEmpty) {
      throw ArgumentError.value(filters, 'filters', 'must not be empty');
    }
    final args = <dynamic>['TS.MGET'];
    if (options.latest) {
      args.add('LATEST');
    }
    _appendTimeSeriesLabelSelection(
      args,
      withLabels: options.withLabels,
      selectedLabels: options.selectedLabels,
    );
    args.addAll(['FILTER', ...filters]);
    final res = await sendCommand(args);
    return _timeSeriesMGetResults(res);
  }

  Future<List<TimeSeriesRangeResult>> tsMRange(
    dynamic fromTimestamp,
    dynamic toTimestamp,
    List<String> filters, {
    TimeSeriesMultiRangeOptions options =
        const TimeSeriesMultiRangeOptions(),
  }) async {
    if (filters.isEmpty) {
      throw ArgumentError.value(filters, 'filters', 'must not be empty');
    }
    if ((options.groupBy == null) != (options.reducer == null)) {
      throw ArgumentError('GROUPBY requires both groupBy and reducer');
    }
    final args = <dynamic>['TS.MRANGE', fromTimestamp, toTimestamp];
    _appendTimeSeriesRangeOptions(args, options);
    _appendTimeSeriesLabelSelection(
      args,
      withLabels: options.withLabels,
      selectedLabels: options.selectedLabels,
    );
    args.addAll(['FILTER', ...filters]);
    if (options.groupBy != null && options.reducer != null) {
      args.addAll([
        'GROUPBY',
        options.groupBy,
        'REDUCE',
        _timeSeriesAggregationArg(options.reducer!),
      ]);
    }
    final res = await sendCommand(args);
    return _timeSeriesRangeResults(res);
  }

  Future<List<TimeSeriesRangeResult>> tsMRevRange(
    dynamic fromTimestamp,
    dynamic toTimestamp,
    List<String> filters, {
    TimeSeriesMultiRangeOptions options =
        const TimeSeriesMultiRangeOptions(),
  }) async {
    if (filters.isEmpty) {
      throw ArgumentError.value(filters, 'filters', 'must not be empty');
    }
    if ((options.groupBy == null) != (options.reducer == null)) {
      throw ArgumentError('GROUPBY requires both groupBy and reducer');
    }
    final args = <dynamic>['TS.MREVRANGE', fromTimestamp, toTimestamp];
    _appendTimeSeriesRangeOptions(args, options);
    _appendTimeSeriesLabelSelection(
      args,
      withLabels: options.withLabels,
      selectedLabels: options.selectedLabels,
    );
    args.addAll(['FILTER', ...filters]);
    if (options.groupBy != null && options.reducer != null) {
      args.addAll([
        'GROUPBY',
        options.groupBy,
        'REDUCE',
        _timeSeriesAggregationArg(options.reducer!),
      ]);
    }
    final res = await sendCommand(args);
    return _timeSeriesRangeResults(res);
  }

  Future<List<String>> tsQueryIndex(List<String> filters) async {
    if (filters.isEmpty) {
      throw ArgumentError.value(filters, 'filters', 'must not be empty');
    }
    final res = await sendCommand(['TS.QUERYINDEX', ...filters]);
    return Decoders.toStringList(res);
  }
}
