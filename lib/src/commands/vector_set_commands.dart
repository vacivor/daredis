part of '../../daredis.dart';

enum VectorSetQuantization { noQuant, q8, bin }

class VectorSetAddOptions {
  final int? reduce;
  final bool cas;
  final VectorSetQuantization? quantization;
  final int? ef;
  final String? attributes;
  final int? m;

  const VectorSetAddOptions({
    this.reduce,
    this.cas = false,
    this.quantization,
    this.ef,
    this.attributes,
    this.m,
  });
}

class VectorSetSimilarityOptions {
  final bool withScores;
  final bool withAttributes;
  final int? count;
  final double? epsilon;
  final int? ef;
  final String? filter;
  final int? filterEf;
  final bool truth;
  final bool noThread;

  const VectorSetSimilarityOptions({
    this.withScores = false,
    this.withAttributes = false,
    this.count,
    this.epsilon,
    this.ef,
    this.filter,
    this.filterEf,
    this.truth = false,
    this.noThread = false,
  });
}

class VectorSetSimilarityMatch {
  final String element;
  final double? score;
  final String? attributes;

  const VectorSetSimilarityMatch(
    this.element, {
    this.score,
    this.attributes,
  });
}

class VectorSetGraphLink {
  final String element;
  final double? score;

  const VectorSetGraphLink(this.element, {this.score});
}

class VectorSetRawEmbedding {
  final String quantizationType;
  final Uint8List data;
  final double norm;
  final double? range;

  const VectorSetRawEmbedding({
    required this.quantizationType,
    required this.data,
    required this.norm,
    required this.range,
  });
}

String _vectorQuantizationArg(VectorSetQuantization value) {
  switch (value) {
    case VectorSetQuantization.noQuant:
      return 'NOQUANT';
    case VectorSetQuantization.q8:
      return 'Q8';
    case VectorSetQuantization.bin:
      return 'BIN';
  }
}

void _appendVectorSetAddReduce(
  List<dynamic> args,
  VectorSetAddOptions options,
) {
  if (options.reduce != null) {
    args.addAll(['REDUCE', options.reduce]);
  }
}

void _appendVectorSetAddTuningOptions(
  List<dynamic> args,
  VectorSetAddOptions options,
) {
  if (options.cas) {
    args.add('CAS');
  }
  if (options.quantization != null) {
    args.add(_vectorQuantizationArg(options.quantization!));
  }
  if (options.ef != null) {
    args.addAll(['EF', options.ef]);
  }
  if (options.attributes != null) {
    args.addAll(['SETATTR', options.attributes]);
  }
  if (options.m != null) {
    args.addAll(['M', options.m]);
  }
}

void _appendVectorSetSimilarityOptions(
  List<dynamic> args,
  VectorSetSimilarityOptions options,
) {
  if (options.withScores) {
    args.add('WITHSCORES');
  }
  if (options.withAttributes) {
    args.add('WITHATTRIBS');
  }
  if (options.count != null) {
    args.addAll(['COUNT', options.count]);
  }
  if (options.epsilon != null) {
    args.addAll(['EPSILON', options.epsilon]);
  }
  if (options.ef != null) {
    args.addAll(['EF', options.ef]);
  }
  if (options.filter != null) {
    args.addAll(['FILTER', options.filter]);
  }
  if (options.filterEf != null) {
    args.addAll(['FILTER-EF', options.filterEf]);
  }
  if (options.truth) {
    args.add('TRUTH');
  }
  if (options.noThread) {
    args.add('NOTHREAD');
  }
}

List<VectorSetSimilarityMatch> _vectorSimilarityMatches(
  dynamic value, {
  required bool withScores,
  required bool withAttributes,
}) {
  if (value is Map) {
    return value.entries.map((entry) {
      final nested = entry.value;
      if (nested is Map) {
        return VectorSetSimilarityMatch(
          Decoders.string(entry.key),
          score: Decoders.toDoubleOrNull(nested['score']),
          attributes: Decoders.toStringOrNull(
            nested['attributes'] ?? nested['attribs'],
          ),
        );
      }
      return VectorSetSimilarityMatch(
        Decoders.string(entry.key),
        score: withScores ? Decoders.toDoubleOrNull(nested) : null,
        attributes: withAttributes && !withScores
            ? Decoders.toStringOrNull(nested)
            : null,
      );
    }).toList(growable: false);
  }

  if (value is! List) {
    return const <VectorSetSimilarityMatch>[];
  }

  final results = <VectorSetSimilarityMatch>[];
  final step = switch ((withScores, withAttributes)) {
    (true, true) => 3,
    (true, false) => 2,
    (false, true) => 2,
    (false, false) => 1,
  };

  for (var i = 0; i < value.length; i += step) {
    if (i >= value.length) {
      break;
    }
    final element = Decoders.string(value[i]);
    double? score;
    String? attributes;
    if (withScores && i + 1 < value.length) {
      score = Decoders.toDoubleOrNull(value[i + 1]);
    }
    if (withAttributes) {
      final attrIndex = i + (withScores ? 2 : 1);
      if (attrIndex < value.length) {
        attributes = Decoders.toStringOrNull(value[attrIndex]);
      }
    }
    results.add(
      VectorSetSimilarityMatch(
        element,
        score: score,
        attributes: attributes,
      ),
    );
  }
  return results;
}

List<List<VectorSetGraphLink>> _vectorGraphLinks(
  dynamic value, {
  required bool withScores,
}) {
  if (value is! List) {
    return const <List<VectorSetGraphLink>>[];
  }

  return value.map((layer) {
    if (layer is! List) {
      return const <VectorSetGraphLink>[];
    }
    if (!withScores) {
      return layer
          .map((item) => VectorSetGraphLink(Decoders.string(item)))
          .toList(growable: false);
    }
    final links = <VectorSetGraphLink>[];
    for (var i = 0; i + 1 < layer.length; i += 2) {
      links.add(
        VectorSetGraphLink(
          Decoders.string(layer[i]),
          score: Decoders.toDoubleOrNull(layer[i + 1]),
        ),
      );
    }
    return links;
  }).toList(growable: false);
}

mixin RedisVectorSetCommands on RedisCommandExecutor {
  Future<bool> vAddValues(
    String key,
    String element,
    List<num> vector, {
    VectorSetAddOptions options = const VectorSetAddOptions(),
  }) async {
    if (vector.isEmpty) {
      throw ArgumentError.value(vector, 'vector', 'must not be empty');
    }
    final args = <dynamic>['VADD', key];
    _appendVectorSetAddReduce(args, options);
    args.addAll(['VALUES', vector.length, ...vector, element]);
    _appendVectorSetAddTuningOptions(args, options);
    final res = await sendCommand(args);
    return Decoders.toBool(res);
  }

  Future<bool> vAddFp32(
    String key,
    String element,
    Uint8List vector, {
    VectorSetAddOptions options = const VectorSetAddOptions(),
  }) async {
    if (vector.isEmpty) {
      throw ArgumentError.value(vector, 'vector', 'must not be empty');
    }
    final args = <dynamic>['VADD', key];
    _appendVectorSetAddReduce(args, options);
    args.addAll(['FP32', vector, element]);
    _appendVectorSetAddTuningOptions(args, options);
    final res = await sendCommand(args);
    return Decoders.toBool(res);
  }

  Future<int> vCard(String key) async {
    final res = await sendCommand(['VCARD', key]);
    return Decoders.toInt(res);
  }

  Future<int> vDim(String key) async {
    final res = await sendCommand(['VDIM', key]);
    return Decoders.toInt(res);
  }

  Future<List<double>> vEmb(String key, String element) async {
    final res = await sendCommand(['VEMB', key, element]);
    if (res is! List) {
      return const <double>[];
    }
    return res.map(Decoders.toDouble).toList(growable: false);
  }

  /// Returns the `RAW` VEMB payload.
  ///
  Future<VectorSetRawEmbedding?> vEmbRaw(String key, String element) async {
    final res = await sendCommand(['VEMB', key, element, 'RAW']);
    if (res is! List || res.length < 3) {
      return null;
    }
    return VectorSetRawEmbedding(
      quantizationType: Decoders.string(res[0]),
      data: Decoders.bytes(res[1]),
      norm: Decoders.toDouble(res[2]),
      range: res.length > 3 ? Decoders.toDoubleOrNull(res[3]) : null,
    );
  }

  Future<String?> vGetAttr(String key, String element) async {
    final res = await sendCommand(['VGETATTR', key, element]);
    return Decoders.toStringOrNull(res);
  }

  Future<Map<String, dynamic>?> vInfo(String key) async {
    final res = await sendCommand(['VINFO', key]);
    if (res == null) {
      return null;
    }
    return _serverReplyAsMap(res);
  }

  Future<bool> vIsMember(String key, String element) async {
    final res = await sendCommand(['VISMEMBER', key, element]);
    return Decoders.toBool(res);
  }

  Future<List<List<VectorSetGraphLink>>> vLinks(
    String key,
    String element, {
    bool withScores = false,
  }) async {
    final args = <dynamic>['VLINKS', key, element];
    if (withScores) {
      args.add('WITHSCORES');
    }
    final res = await sendCommand(args);
    return _vectorGraphLinks(res, withScores: withScores);
  }

  Future<List<String>> vRandMember(String key, [int? count]) async {
    final args = <dynamic>['VRANDMEMBER', key];
    if (count != null) {
      args.add(count);
    }
    final res = await sendCommand(args);
    if (res is List) {
      return res.map(Decoders.string).toList(growable: false);
    }
    if (res == null) {
      return const <String>[];
    }
    return <String>[Decoders.string(res)];
  }

  Future<List<String>> vRange(
    String key,
    String start,
    String end, {
    int? count,
  }) async {
    final args = <dynamic>['VRANGE', key, start, end];
    if (count != null) {
      args.add(count);
    }
    final res = await sendCommand(args);
    return Decoders.toStringList(res);
  }

  Future<bool> vRem(String key, String element) async {
    final res = await sendCommand(['VREM', key, element]);
    return Decoders.toBool(res);
  }

  Future<bool> vSetAttr(String key, String element, String attributes) async {
    final res = await sendCommand(['VSETATTR', key, element, attributes]);
    return Decoders.toBool(res);
  }

  Future<List<VectorSetSimilarityMatch>> vSimElement(
    String key,
    String element, {
    VectorSetSimilarityOptions options = const VectorSetSimilarityOptions(),
  }) async {
    final args = <dynamic>['VSIM', key, 'ELE', element];
    _appendVectorSetSimilarityOptions(args, options);
    final res = await sendCommand(args);
    return _vectorSimilarityMatches(
      res,
      withScores: options.withScores,
      withAttributes: options.withAttributes,
    );
  }

  Future<List<VectorSetSimilarityMatch>> vSimValues(
    String key,
    List<num> vector, {
    VectorSetSimilarityOptions options = const VectorSetSimilarityOptions(),
  }) async {
    if (vector.isEmpty) {
      throw ArgumentError.value(vector, 'vector', 'must not be empty');
    }
    final args = <dynamic>['VSIM', key, 'VALUES', vector.length, ...vector];
    _appendVectorSetSimilarityOptions(args, options);
    final res = await sendCommand(args);
    return _vectorSimilarityMatches(
      res,
      withScores: options.withScores,
      withAttributes: options.withAttributes,
    );
  }

  Future<List<VectorSetSimilarityMatch>> vSimFp32(
    String key,
    Uint8List vector, {
    VectorSetSimilarityOptions options = const VectorSetSimilarityOptions(),
  }) async {
    if (vector.isEmpty) {
      throw ArgumentError.value(vector, 'vector', 'must not be empty');
    }
    final args = <dynamic>['VSIM', key, 'FP32', vector];
    _appendVectorSetSimilarityOptions(args, options);
    final res = await sendCommand(args);
    return _vectorSimilarityMatches(
      res,
      withScores: options.withScores,
      withAttributes: options.withAttributes,
    );
  }
}
