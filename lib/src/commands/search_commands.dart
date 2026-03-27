part of '../../daredis.dart';

enum SearchIndexDataType { hash, json }

enum SearchSchemaFieldType { text, tag, numeric, geo, vector, geoshape }

enum SearchGeoUnit { m, km, mi, ft }

class SearchSchemaField {
  final String identifier;
  final String? attribute;
  final SearchSchemaFieldType type;
  final List<dynamic> options;

  const SearchSchemaField({
    required this.identifier,
    this.attribute,
    required this.type,
    this.options = const <dynamic>[],
  });
}

class SearchCreateOptions {
  final SearchIndexDataType? on;
  final List<String>? prefixes;
  final String? filter;
  final String? language;
  final String? languageField;
  final double? score;
  final String? scoreField;
  final String? payloadField;
  final bool maxTextFields;
  final int? temporary;
  final bool noOffsets;
  final bool noHl;
  final bool noFields;
  final bool noFreqs;
  final List<String>? stopWords;
  final bool skipInitialScan;
  final bool? indexAll;

  const SearchCreateOptions({
    this.on,
    this.prefixes,
    this.filter,
    this.language,
    this.languageField,
    this.score,
    this.scoreField,
    this.payloadField,
    this.maxTextFields = false,
    this.temporary,
    this.noOffsets = false,
    this.noHl = false,
    this.noFields = false,
    this.noFreqs = false,
    this.stopWords,
    this.skipInitialScan = false,
    this.indexAll,
  });
}

class SearchNumericFilter {
  final String field;
  final num min;
  final num max;

  const SearchNumericFilter(this.field, this.min, this.max);
}

class SearchGeoFilter {
  final String field;
  final double longitude;
  final double latitude;
  final double radius;
  final SearchGeoUnit unit;

  const SearchGeoFilter(
    this.field,
    this.longitude,
    this.latitude,
    this.radius,
    this.unit,
  );
}

class SearchReturnField {
  final String identifier;
  final String? property;

  const SearchReturnField(this.identifier, {this.property});
}

class SearchSummarizeOptions {
  final List<String>? fields;
  final int? frags;
  final int? len;
  final String? separator;

  const SearchSummarizeOptions({
    this.fields,
    this.frags,
    this.len,
    this.separator,
  });
}

class SearchHighlightOptions {
  final List<String>? fields;
  final String? openTag;
  final String? closeTag;

  const SearchHighlightOptions({
    this.fields,
    this.openTag,
    this.closeTag,
  });
}

class SearchSortBy {
  final String field;
  final bool asc;
  final bool? withCount;

  const SearchSortBy(this.field, {this.asc = true, this.withCount});
}

class SearchDocument {
  final String id;
  final double? score;
  final String? payload;
  final String? sortKey;
  final Map<String, dynamic> fields;

  const SearchDocument({
    required this.id,
    required this.score,
    required this.payload,
    required this.sortKey,
    required this.fields,
  });
}

class SearchResult {
  final int total;
  final List<SearchDocument> documents;

  const SearchResult({
    required this.total,
    required this.documents,
  });
}

class SearchAggregateResult {
  final dynamic results;
  final int? cursorId;

  const SearchAggregateResult({
    required this.results,
    this.cursorId,
  });
}

class SearchProfileResult {
  final dynamic results;
  final dynamic profile;

  const SearchProfileResult({
    required this.results,
    required this.profile,
  });
}

class SearchSpellCheckSuggestion {
  final double score;
  final String suggestion;

  const SearchSpellCheckSuggestion(this.score, this.suggestion);
}

class SearchSpellCheckTermResult {
  final String term;
  final List<SearchSpellCheckSuggestion> suggestions;

  const SearchSpellCheckTermResult({
    required this.term,
    required this.suggestions,
  });
}

class SearchSpellCheckTermsClause {
  final bool include;
  final String dictionary;
  final List<String> terms;

  const SearchSpellCheckTermsClause({
    required this.include,
    required this.dictionary,
    this.terms = const <String>[],
  });
}

class SearchQueryOptions {
  final bool noContent;
  final bool verbatim;
  final bool noStopWords;
  final bool withScores;
  final bool withPayloads;
  final bool withSortKeys;
  final List<SearchNumericFilter>? numericFilters;
  final List<SearchGeoFilter>? geoFilters;
  final List<String>? inKeys;
  final List<String>? inFields;
  final List<SearchReturnField>? returnFields;
  final SearchSummarizeOptions? summarize;
  final SearchHighlightOptions? highlight;
  final int? slop;
  final int? timeout;
  final bool inOrder;
  final String? language;
  final String? expander;
  final String? scorer;
  final bool explainScore;
  final String? payload;
  final SearchSortBy? sortBy;
  final int offset;
  final int num;
  final Map<String, dynamic>? params;
  final int? dialect;

  const SearchQueryOptions({
    this.noContent = false,
    this.verbatim = false,
    this.noStopWords = false,
    this.withScores = false,
    this.withPayloads = false,
    this.withSortKeys = false,
    this.numericFilters,
    this.geoFilters,
    this.inKeys,
    this.inFields,
    this.returnFields,
    this.summarize,
    this.highlight,
    this.slop,
    this.timeout,
    this.inOrder = false,
    this.language,
    this.expander,
    this.scorer,
    this.explainScore = false,
    this.payload,
    this.sortBy,
    this.offset = 0,
    this.num = 10,
    this.params,
    this.dialect,
  });
}

String _searchSchemaTypeArg(SearchSchemaFieldType value) {
  switch (value) {
    case SearchSchemaFieldType.text:
      return 'TEXT';
    case SearchSchemaFieldType.tag:
      return 'TAG';
    case SearchSchemaFieldType.numeric:
      return 'NUMERIC';
    case SearchSchemaFieldType.geo:
      return 'GEO';
    case SearchSchemaFieldType.vector:
      return 'VECTOR';
    case SearchSchemaFieldType.geoshape:
      return 'GEOSHAPE';
  }
}

String _searchGeoUnitArg(SearchGeoUnit value) {
  switch (value) {
    case SearchGeoUnit.m:
      return 'm';
    case SearchGeoUnit.km:
      return 'km';
    case SearchGeoUnit.mi:
      return 'mi';
    case SearchGeoUnit.ft:
      return 'ft';
  }
}

String _searchOnArg(SearchIndexDataType value) {
  switch (value) {
    case SearchIndexDataType.hash:
      return 'HASH';
    case SearchIndexDataType.json:
      return 'JSON';
  }
}

void _appendSearchSchemaFields(
  List<dynamic> args,
  List<SearchSchemaField> fields,
) {
  if (fields.isEmpty) {
    throw ArgumentError.value(fields, 'fields', 'must not be empty');
  }
  args.add('SCHEMA');
  for (final field in fields) {
    args.add(field.identifier);
    if (field.attribute != null) {
      args.addAll(['AS', field.attribute]);
    }
    args.add(_searchSchemaTypeArg(field.type));
    args.addAll(field.options);
  }
}

void _appendSearchParams(
  List<dynamic> args,
  Map<String, dynamic>? params,
) {
  if (params == null || params.isEmpty) {
    return;
  }
  args.add('PARAMS');
  args.add(params.length * 2);
  params.forEach((key, value) {
    args.addAll([key, value]);
  });
}

Map<String, dynamic> _searchFlatMap(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) =>
          MapEntry(Decoders.string(key), _normalizeServerReply(nestedValue)),
    );
  }
  return _serverReplyAsMap(value);
}

SearchResult _parseSearchResult(dynamic value, SearchQueryOptions options) {
  if (value is Map) {
    final total = Decoders.toInt(
      value['total_results'] ?? value['total'] ?? 0,
    );
    final results = value['results'];
    if (results is List) {
      final documents = results.map((entry) {
        final map = _searchFlatMap(entry);
        final id = Decoders.toStringOrNull(map['id']) ??
            Decoders.toStringOrNull(map['keyid']) ??
            Decoders.toStringOrNull(map['__key']) ??
            '';
        final fields = map['extra_attributes'] is Map
            ? Map<String, dynamic>.from(map['extra_attributes'] as Map)
            : map['fields'] is Map
                ? Map<String, dynamic>.from(map['fields'] as Map)
                : <String, dynamic>{};
        return SearchDocument(
          id: id,
          score: Decoders.toDoubleOrNull(map['score'] ?? map['__score']),
          payload: Decoders.toStringOrNull(map['payload']),
          sortKey: Decoders.toStringOrNull(map['sortkey']),
          fields: fields,
        );
      }).toList(growable: false);
      return SearchResult(total: total, documents: documents);
    }
    return const SearchResult(total: 0, documents: <SearchDocument>[]);
  }

  if (value is! List || value.isEmpty) {
    return const SearchResult(total: 0, documents: <SearchDocument>[]);
  }

  final total = Decoders.toInt(value[0]);
  final documents = <SearchDocument>[];
  var index = 1;
  while (index < value.length) {
    final id = Decoders.string(value[index++]);
    double? score;
    String? payload;
    String? sortKey;
    Map<String, dynamic> fields = const <String, dynamic>{};

    if (options.withScores && index < value.length) {
      score = Decoders.toDoubleOrNull(value[index++]);
    }
    if (options.withPayloads && index < value.length) {
      payload = Decoders.toStringOrNull(value[index++]);
    }
    if (options.withSortKeys && index < value.length) {
      sortKey = Decoders.toStringOrNull(value[index++]);
    }
    if (!options.noContent && index < value.length) {
      fields = _searchFlatMap(value[index++]);
    }

    documents.add(
      SearchDocument(
        id: id,
        score: score,
        payload: payload,
        sortKey: sortKey,
        fields: fields,
      ),
    );
  }

  return SearchResult(total: total, documents: documents);
}

SearchAggregateResult _parseSearchAggregateResult(dynamic value) {
  if (value is List &&
      value.length == 2 &&
      value[0] is List &&
      Decoders.toIntOrNull(value[1]) != null) {
    return SearchAggregateResult(
      results: _normalizeServerReply(value[0]),
      cursorId: Decoders.toInt(value[1]),
    );
  }
  return SearchAggregateResult(results: _normalizeServerReply(value));
}

List<SearchSpellCheckTermResult> _parseSpellCheckResults(dynamic value) {
  if (value is! List) {
    return const <SearchSpellCheckTermResult>[];
  }
  final results = <SearchSpellCheckTermResult>[];
  for (final item in value) {
    if (item is! List || item.length < 3) {
      continue;
    }
    final suggestions = <SearchSpellCheckSuggestion>[];
    if (item[2] is List) {
      for (final suggestion in item[2] as List) {
        if (suggestion is List && suggestion.length >= 2) {
          suggestions.add(
            SearchSpellCheckSuggestion(
              Decoders.toDouble(suggestion[0]),
              Decoders.string(suggestion[1]),
            ),
          );
        }
      }
    }
    results.add(
      SearchSpellCheckTermResult(
        term: Decoders.string(item[1]),
        suggestions: suggestions,
      ),
    );
  }
  return results;
}

Map<String, List<String>> _parseSynDump(dynamic value) {
  if (value is! List) {
    return const <String, List<String>>{};
  }
  final result = <String, List<String>>{};
  for (var i = 0; i + 1 < value.length; i += 2) {
    final groups = value[i + 1] is List
        ? (value[i + 1] as List)
            .map(Decoders.string)
            .toList(growable: false)
        : const <String>[];
    result[Decoders.string(value[i])] = groups;
  }
  return result;
}

void _appendSearchQueryOptions(
  List<dynamic> args,
  SearchQueryOptions options,
) {
  if (options.noContent) args.add('NOCONTENT');
  if (options.verbatim) args.add('VERBATIM');
  if (options.noStopWords) args.add('NOSTOPWORDS');
  if (options.withScores) args.add('WITHSCORES');
  if (options.withPayloads) args.add('WITHPAYLOADS');
  if (options.withSortKeys) args.add('WITHSORTKEYS');
  if (options.numericFilters != null) {
    for (final filter in options.numericFilters!) {
      args.addAll(['FILTER', filter.field, filter.min, filter.max]);
    }
  }
  if (options.geoFilters != null) {
    for (final filter in options.geoFilters!) {
      args.addAll([
        'GEOFILTER',
        filter.field,
        filter.longitude,
        filter.latitude,
        filter.radius,
        _searchGeoUnitArg(filter.unit),
      ]);
    }
  }
  if (options.inKeys != null && options.inKeys!.isNotEmpty) {
    args.addAll(['INKEYS', options.inKeys!.length, ...options.inKeys!]);
  }
  if (options.inFields != null && options.inFields!.isNotEmpty) {
    args.addAll(['INFIELDS', options.inFields!.length, ...options.inFields!]);
  }
  if (options.returnFields != null && options.returnFields!.isNotEmpty) {
    final identifiers = options.returnFields!
        .map((field) => field.identifier)
        .toList(growable: false);
    args.addAll(['RETURN', identifiers.length]);
    for (final field in options.returnFields!) {
      args.add(field.identifier);
      if (field.property != null) {
        args.addAll(['AS', field.property]);
      }
    }
  }
  final summarize = options.summarize;
  if (summarize != null) {
    args.add('SUMMARIZE');
    if (summarize.fields != null && summarize.fields!.isNotEmpty) {
      args.addAll(['FIELDS', summarize.fields!.length, ...summarize.fields!]);
    }
    if (summarize.frags != null) {
      args.addAll(['FRAGS', summarize.frags]);
    }
    if (summarize.len != null) {
      args.addAll(['LEN', summarize.len]);
    }
    if (summarize.separator != null) {
      args.addAll(['SEPARATOR', summarize.separator]);
    }
  }
  final highlight = options.highlight;
  if (highlight != null) {
    args.add('HIGHLIGHT');
    if (highlight.fields != null && highlight.fields!.isNotEmpty) {
      args.addAll(['FIELDS', highlight.fields!.length, ...highlight.fields!]);
    }
    if (highlight.openTag != null || highlight.closeTag != null) {
      args.addAll(['TAGS', highlight.openTag ?? '<b>', highlight.closeTag ?? '</b>']);
    }
  }
  if (options.slop != null) args.addAll(['SLOP', options.slop]);
  if (options.timeout != null) args.addAll(['TIMEOUT', options.timeout]);
  if (options.inOrder) args.add('INORDER');
  if (options.language != null) args.addAll(['LANGUAGE', options.language]);
  if (options.expander != null) args.addAll(['EXPANDER', options.expander]);
  if (options.scorer != null) args.addAll(['SCORER', options.scorer]);
  if (options.explainScore) args.add('EXPLAINSCORE');
  if (options.payload != null) args.addAll(['PAYLOAD', options.payload]);
  if (options.sortBy != null) {
    args.addAll(['SORTBY', options.sortBy!.field, options.sortBy!.asc ? 'ASC' : 'DESC']);
    if (options.sortBy!.withCount != null) {
      args.add(options.sortBy!.withCount! ? 'WITHCOUNT' : 'WITHOUTCOUNT');
    }
  }
  args.addAll(['LIMIT', options.offset, options.num]);
  _appendSearchParams(args, options.params);
  if (options.dialect != null) {
    args.addAll(['DIALECT', options.dialect]);
  }
}

mixin RedisSearchCommands on RedisCommandExecutor {
  Future<String> ftAliasAdd(String alias, String index) async {
    final res = await sendCommand(['FT.ALIASADD', alias, index]);
    return Decoders.string(res);
  }

  Future<String> ftAliasDel(String alias) async {
    final res = await sendCommand(['FT.ALIASDEL', alias]);
    return Decoders.string(res);
  }

  Future<String> ftAliasUpdate(String alias, String index) async {
    final res = await sendCommand(['FT.ALIASUPDATE', alias, index]);
    return Decoders.string(res);
  }

  Future<String> ftAlterAdd(
    String index,
    List<SearchSchemaField> fields, {
    bool skipInitialScan = false,
  }) async {
    final args = <dynamic>['FT.ALTER', index];
    if (skipInitialScan) {
      args.add('SKIPINITIALSCAN');
    }
    args.addAll(['SCHEMA', 'ADD']);
    for (final field in fields) {
      args.add(field.identifier);
      if (field.attribute != null) {
        args.addAll(['AS', field.attribute]);
      }
      args.add(_searchSchemaTypeArg(field.type));
      args.addAll(field.options);
    }
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<Map<String, dynamic>> ftConfigGet(String option) async {
    final res = await sendCommand(['FT.CONFIG', 'GET', option]);
    if (res is Map) {
      return res.map(
        (key, value) => MapEntry(Decoders.string(key), _normalizeServerReply(value)),
      );
    }
    if (res is! List) {
      return const <String, dynamic>{};
    }
    final config = <String, dynamic>{};
    for (final entry in res) {
      if (entry is List && entry.length >= 2) {
        config[Decoders.string(entry[0])] = _normalizeServerReply(entry[1]);
      }
    }
    return config;
  }

  Future<String> ftConfigSet(String option, dynamic value) async {
    final res = await sendCommand(['FT.CONFIG', 'SET', option, value]);
    return Decoders.string(res);
  }

  Future<String> ftCreate(
    String index,
    List<SearchSchemaField> fields, {
    SearchCreateOptions options = const SearchCreateOptions(),
  }) async {
    final args = <dynamic>['FT.CREATE', index];
    if (options.on != null) {
      args.addAll(['ON', _searchOnArg(options.on!)]);
    }
    if (options.prefixes != null && options.prefixes!.isNotEmpty) {
      args.addAll(['PREFIX', options.prefixes!.length, ...options.prefixes!]);
    }
    if (options.filter != null) {
      args.addAll(['FILTER', options.filter]);
    }
    if (options.language != null) {
      args.addAll(['LANGUAGE', options.language]);
    }
    if (options.languageField != null) {
      args.addAll(['LANGUAGE_FIELD', options.languageField]);
    }
    if (options.score != null) {
      args.addAll(['SCORE', options.score]);
    }
    if (options.scoreField != null) {
      args.addAll(['SCORE_FIELD', options.scoreField]);
    }
    if (options.payloadField != null) {
      args.addAll(['PAYLOAD_FIELD', options.payloadField]);
    }
    if (options.maxTextFields) args.add('MAXTEXTFIELDS');
    if (options.temporary != null) args.addAll(['TEMPORARY', options.temporary]);
    if (options.noOffsets) args.add('NOOFFSETS');
    if (options.noHl) args.add('NOHL');
    if (options.noFields) args.add('NOFIELDS');
    if (options.noFreqs) args.add('NOFREQS');
    if (options.stopWords != null) {
      args.addAll(['STOPWORDS', options.stopWords!.length, ...options.stopWords!]);
    }
    if (options.skipInitialScan) args.add('SKIPINITIALSCAN');
    if (options.indexAll != null) {
      args.addAll(['INDEXALL', options.indexAll! ? 'ENABLE' : 'DISABLE']);
    }
    _appendSearchSchemaFields(args, fields);
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<String> ftCursorDel(String index, int cursorId) async {
    final res = await sendCommand(['FT.CURSOR', 'DEL', index, cursorId]);
    return Decoders.string(res);
  }

  Future<SearchAggregateResult> ftCursorRead(
    String index,
    int cursorId, {
    int? count,
  }) async {
    final args = <dynamic>['FT.CURSOR', 'READ', index, cursorId];
    if (count != null) {
      args.addAll(['COUNT', count]);
    }
    final res = await sendCommand(args);
    return _parseSearchAggregateResult(res);
  }

  Future<int> ftDictAdd(String dictionary, List<String> terms) async {
    if (terms.isEmpty) {
      throw ArgumentError.value(terms, 'terms', 'must not be empty');
    }
    final res = await sendCommand(['FT.DICTADD', dictionary, ...terms]);
    return Decoders.toInt(res);
  }

  Future<int> ftDictDel(String dictionary, List<String> terms) async {
    if (terms.isEmpty) {
      throw ArgumentError.value(terms, 'terms', 'must not be empty');
    }
    final res = await sendCommand(['FT.DICTDEL', dictionary, ...terms]);
    return Decoders.toInt(res);
  }

  Future<List<String>> ftDictDump(String dictionary) async {
    final res = await sendCommand(['FT.DICTDUMP', dictionary]);
    return Decoders.toStringList(res);
  }

  Future<String> ftDropIndex(String index, {bool deleteDocuments = false}) async {
    final args = <dynamic>['FT.DROPINDEX', index];
    if (deleteDocuments) {
      args.add('DD');
    }
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<String> ftExplain(String index, String query, {int? dialect}) async {
    final args = <dynamic>['FT.EXPLAIN', index, query];
    if (dialect != null) {
      args.addAll(['DIALECT', dialect]);
    }
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<String> ftExplainCli(String index, String query, {int? dialect}) async {
    final args = <dynamic>['FT.EXPLAINCLI', index, query];
    if (dialect != null) {
      args.addAll(['DIALECT', dialect]);
    }
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<dynamic> ftHybrid(String index, List<dynamic> arguments) {
    return sendCommand(['FT.HYBRID', index, ...arguments]);
  }

  Future<Map<String, dynamic>> ftInfo(String index) async {
    final res = await sendCommand(['FT.INFO', index]);
    return _searchFlatMap(res);
  }

  Future<SearchProfileResult> ftProfileSearch(
    String index,
    String query, {
    bool limited = false,
    List<dynamic> arguments = const <dynamic>[],
  }) async {
    final args = <dynamic>['FT.PROFILE', index, 'SEARCH'];
    if (limited) {
      args.add('LIMITED');
    }
    args.addAll(['QUERY', query, ...arguments]);
    final res = await sendCommand(args);
    if (res is Map) {
      return SearchProfileResult(
        results: _normalizeServerReply(res['Results']),
        profile: _normalizeServerReply(res['Profile']),
      );
    }
    if (res is List && res.length >= 2) {
      return SearchProfileResult(
        results: _normalizeServerReply(res[0]),
        profile: _normalizeServerReply(res[1]),
      );
    }
    return SearchProfileResult(results: _normalizeServerReply(res), profile: null);
  }

  Future<SearchProfileResult> ftProfileAggregate(
    String index,
    String query, {
    bool limited = false,
    List<dynamic> arguments = const <dynamic>[],
  }) async {
    final args = <dynamic>['FT.PROFILE', index, 'AGGREGATE'];
    if (limited) {
      args.add('LIMITED');
    }
    args.addAll(['QUERY', query, ...arguments]);
    final res = await sendCommand(args);
    if (res is Map) {
      return SearchProfileResult(
        results: _normalizeServerReply(res['Results']),
        profile: _normalizeServerReply(res['Profile']),
      );
    }
    if (res is List && res.length >= 2) {
      return SearchProfileResult(
        results: _normalizeServerReply(res[0]),
        profile: _normalizeServerReply(res[1]),
      );
    }
    return SearchProfileResult(results: _normalizeServerReply(res), profile: null);
  }

  Future<SearchResult> ftSearch(
    String index,
    String query, {
    SearchQueryOptions options = const SearchQueryOptions(),
  }) async {
    final args = <dynamic>['FT.SEARCH', index, query];
    _appendSearchQueryOptions(args, options);
    final res = await sendCommand(args);
    return _parseSearchResult(res, options);
  }

  Future<SearchAggregateResult> ftAggregate(
    String index,
    String query, {
    List<dynamic> arguments = const <dynamic>[],
  }) async {
    final res = await sendCommand(['FT.AGGREGATE', index, query, ...arguments]);
    return _parseSearchAggregateResult(res);
  }

  Future<List<SearchSpellCheckTermResult>> ftSpellCheck(
    String index,
    String query, {
    int? distance,
    List<SearchSpellCheckTermsClause> terms = const <SearchSpellCheckTermsClause>[],
    int? dialect,
  }) async {
    final args = <dynamic>['FT.SPELLCHECK', index, query];
    if (distance != null) {
      args.addAll(['DISTANCE', distance]);
    }
    for (final clause in terms) {
      args.addAll([
        'TERMS',
        clause.include ? 'INCLUDE' : 'EXCLUDE',
        clause.dictionary,
        ...clause.terms,
      ]);
    }
    if (dialect != null) {
      args.addAll(['DIALECT', dialect]);
    }
    final res = await sendCommand(args);
    return _parseSpellCheckResults(res);
  }

  Future<Map<String, List<String>>> ftSynDump(String index) async {
    final res = await sendCommand(['FT.SYNDUMP', index]);
    return _parseSynDump(res);
  }

  Future<String> ftSynUpdate(
    String index,
    String synonymGroupId,
    List<String> terms, {
    bool skipInitialScan = false,
  }) async {
    if (terms.isEmpty) {
      throw ArgumentError.value(terms, 'terms', 'must not be empty');
    }
    final args = <dynamic>['FT.SYNUPDATE', index, synonymGroupId];
    if (skipInitialScan) {
      args.add('SKIPINITIALSCAN');
    }
    args.addAll(terms);
    final res = await sendCommand(args);
    return Decoders.string(res);
  }

  Future<List<String>> ftTagVals(String index, String fieldName) async {
    final res = await sendCommand(['FT.TAGVALS', index, fieldName]);
    return Decoders.toStringList(res);
  }

  Future<List<String>> ftList() async {
    final res = await sendCommand(['FT._LIST']);
    return Decoders.toStringList(res);
  }
}
