import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

class _FakeSearchExecutor extends RedisCommandExecutor with RedisSearchCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

void main() {
  group('RedisSearchCommands', () {
    test('ftCreate and ftAlterAdd build index schema commands', () async {
      final executor = _FakeSearchExecutor()..response = 'OK';

      expect(
        await executor.ftCreate(
          'idx',
          const [
            SearchSchemaField(
              identifier: 'title',
              type: SearchSchemaFieldType.text,
              options: ['SORTABLE'],
            ),
            SearchSchemaField(
              identifier: r'$.price',
              attribute: 'price',
              type: SearchSchemaFieldType.numeric,
            ),
          ],
          options: const SearchCreateOptions(
            on: SearchIndexDataType.json,
            prefixes: ['doc:'],
            filter: '@price > 0',
            language: 'english',
            languageField: 'lang',
            score: 0.5,
            scoreField: 'score',
            payloadField: 'payload',
            maxTextFields: true,
            temporary: 60,
            noOffsets: true,
            noHl: true,
            noFields: true,
            noFreqs: true,
            stopWords: ['a', 'the'],
            skipInitialScan: true,
            indexAll: true,
          ),
        ),
        'OK',
      );
      expect(executor.lastCommand, [
        'FT.CREATE',
        'idx',
        'ON',
        'JSON',
        'PREFIX',
        1,
        'doc:',
        'FILTER',
        '@price > 0',
        'LANGUAGE',
        'english',
        'LANGUAGE_FIELD',
        'lang',
        'SCORE',
        0.5,
        'SCORE_FIELD',
        'score',
        'PAYLOAD_FIELD',
        'payload',
        'MAXTEXTFIELDS',
        'TEMPORARY',
        60,
        'NOOFFSETS',
        'NOHL',
        'NOFIELDS',
        'NOFREQS',
        'STOPWORDS',
        2,
        'a',
        'the',
        'SKIPINITIALSCAN',
        'INDEXALL',
        'ENABLE',
        'SCHEMA',
        'title',
        'TEXT',
        'SORTABLE',
        r'$.price',
        'AS',
        'price',
        'NUMERIC',
      ]);

      expect(
        await executor.ftAlterAdd(
          'idx',
          const [
            SearchSchemaField(
              identifier: 'tags',
              type: SearchSchemaFieldType.tag,
              options: ['SEPARATOR', '|'],
            ),
          ],
          skipInitialScan: true,
        ),
        'OK',
      );
      expect(executor.lastCommand, [
        'FT.ALTER',
        'idx',
        'SKIPINITIALSCAN',
        'SCHEMA',
        'ADD',
        'tags',
        'TAG',
        'SEPARATOR',
        '|',
      ]);
    });

    test('simple alias config dict and list helpers build exact commands', () async {
      final executor = _FakeSearchExecutor()..response = 'OK';

      expect(await executor.ftAliasAdd('alias', 'idx'), 'OK');
      expect(executor.lastCommand, ['FT.ALIASADD', 'alias', 'idx']);

      expect(await executor.ftAliasDel('alias'), 'OK');
      expect(executor.lastCommand, ['FT.ALIASDEL', 'alias']);

      expect(await executor.ftAliasUpdate('alias', 'idx2'), 'OK');
      expect(executor.lastCommand, ['FT.ALIASUPDATE', 'alias', 'idx2']);

      executor.response = [
        ['MINPREFIX', '2'],
      ];
      expect(await executor.ftConfigGet('MINPREFIX'), {'MINPREFIX': '2'});
      expect(executor.lastCommand, ['FT.CONFIG', 'GET', 'MINPREFIX']);

      executor.response = 'OK';
      expect(await executor.ftConfigSet('MINPREFIX', 2), 'OK');
      expect(executor.lastCommand, ['FT.CONFIG', 'SET', 'MINPREFIX', 2]);

      executor.response = 2;
      expect(await executor.ftDictAdd('dict', ['a', 'b']), 2);
      expect(executor.lastCommand, ['FT.DICTADD', 'dict', 'a', 'b']);

      expect(await executor.ftDictDel('dict', ['a']), 2);
      expect(executor.lastCommand, ['FT.DICTDEL', 'dict', 'a']);

      executor.response = ['a', 'b'];
      expect(await executor.ftDictDump('dict'), ['a', 'b']);
      expect(executor.lastCommand, ['FT.DICTDUMP', 'dict']);

      expect(await executor.ftList(), ['a', 'b']);
      expect(executor.lastCommand, ['FT._LIST']);
    });

    test('ftSearch builds full query options and parses documents', () async {
      final executor = _FakeSearchExecutor()
        ..response = [
          1,
          'doc:1',
          '1.2',
          'payload',
          r'$.title',
          ['title', 'Redis', 'price', '10'],
        ];

      final result = await executor.ftSearch(
        'idx',
        '@title:redis',
        options: const SearchQueryOptions(
          withScores: true,
          withPayloads: true,
          withSortKeys: true,
          numericFilters: [SearchNumericFilter('price', 1, 20)],
          geoFilters: [SearchGeoFilter('loc', 1, 2, 5, SearchGeoUnit.km)],
          inKeys: ['doc:1'],
          inFields: ['title'],
          returnFields: [
            SearchReturnField('title'),
            SearchReturnField(r'$.price', property: 'price'),
          ],
          summarize: SearchSummarizeOptions(
            fields: ['title'],
            frags: 1,
            len: 20,
            separator: '...',
          ),
          highlight: SearchHighlightOptions(
            fields: ['title'],
            openTag: '<em>',
            closeTag: '</em>',
          ),
          slop: 1,
          timeout: 100,
          inOrder: true,
          language: 'english',
          expander: 'exp',
          scorer: 'scorer',
          explainScore: true,
          payload: 'payload',
          sortBy: SearchSortBy('price', asc: false, withCount: true),
          offset: 5,
          num: 10,
          params: {'tenant': 'acme'},
          dialect: 3,
        ),
      );

      expect(result.total, 1);
      expect(result.documents.single.id, 'doc:1');
      expect(result.documents.single.score, 1.2);
      expect(result.documents.single.payload, 'payload');
      expect(result.documents.single.sortKey, r'$.title');
      expect(result.documents.single.fields, {'title': 'Redis', 'price': '10'});
      expect(executor.lastCommand, [
        'FT.SEARCH',
        'idx',
        '@title:redis',
        'WITHSCORES',
        'WITHPAYLOADS',
        'WITHSORTKEYS',
        'FILTER',
        'price',
        1,
        20,
        'GEOFILTER',
        'loc',
        1.0,
        2.0,
        5.0,
        'km',
        'INKEYS',
        1,
        'doc:1',
        'INFIELDS',
        1,
        'title',
        'RETURN',
        2,
        'title',
        r'$.price',
        'AS',
        'price',
        'SUMMARIZE',
        'FIELDS',
        1,
        'title',
        'FRAGS',
        1,
        'LEN',
        20,
        'SEPARATOR',
        '...',
        'HIGHLIGHT',
        'FIELDS',
        1,
        'title',
        'TAGS',
        '<em>',
        '</em>',
        'SLOP',
        1,
        'TIMEOUT',
        100,
        'INORDER',
        'LANGUAGE',
        'english',
        'EXPANDER',
        'exp',
        'SCORER',
        'scorer',
        'EXPLAINSCORE',
        'PAYLOAD',
        'payload',
        'SORTBY',
        'price',
        'DESC',
        'WITHCOUNT',
        'LIMIT',
        5,
        10,
        'PARAMS',
        2,
        'tenant',
        'acme',
        'DIALECT',
        3,
      ]);
    });

    test('aggregate cursor profile and spellcheck helpers parse replies', () async {
      final executor = _FakeSearchExecutor()
        ..response = [
          [
            1,
            ['category', 'db'],
          ],
          42,
        ];

      final aggregate = await executor.ftAggregate(
        'idx',
        '*',
        arguments: ['GROUPBY', 1, '@category'],
      );
      expect(aggregate.cursorId, 42);
      expect(executor.lastCommand, ['FT.AGGREGATE', 'idx', '*', 'GROUPBY', 1, '@category']);

      executor.response = [
        [
          1,
          ['name', 'redis'],
        ],
        7,
      ];
      final cursor = await executor.ftCursorRead('idx', 7, count: 10);
      expect(cursor.cursorId, 7);
      expect(executor.lastCommand, ['FT.CURSOR', 'READ', 'idx', 7, 'COUNT', 10]);

      executor.response = [
        ['results'],
        ['profile'],
      ];
      final profile = await executor.ftProfileSearch(
        'idx',
        '@title:redis',
        limited: true,
        arguments: ['LIMIT', 0, 5],
      );
      expect(profile.results, ['results']);
      expect(profile.profile, ['profile']);
      expect(executor.lastCommand, [
        'FT.PROFILE',
        'idx',
        'SEARCH',
        'LIMITED',
        'QUERY',
        '@title:redis',
        'LIMIT',
        0,
        5,
      ]);

      executor.response = [
        ['TERM', 'redis', [
          [0.8, 'redis'],
          [0.5, 'reddis'],
        ]],
      ];
      final spellcheck = await executor.ftSpellCheck(
        'idx',
        'reddis',
        distance: 1,
        terms: const [
          SearchSpellCheckTermsClause(
            include: true,
            dictionary: 'dict',
            terms: ['redis'],
          ),
        ],
        dialect: 2,
      );
      expect(spellcheck.single.term, 'redis');
      expect(spellcheck.single.suggestions.first.suggestion, 'redis');
      expect(executor.lastCommand, [
        'FT.SPELLCHECK',
        'idx',
        'reddis',
        'DISTANCE',
        1,
        'TERMS',
        'INCLUDE',
        'dict',
        'redis',
        'DIALECT',
        2,
      ]);
    });

    test('info synonym explain tagvals and dropindex helpers parse and build', () async {
      final executor = _FakeSearchExecutor()
        ..response = [
          'index_name',
          'idx',
          'num_docs',
          3,
        ];

      expect(await executor.ftInfo('idx'), {'index_name': 'idx', 'num_docs': 3});
      expect(executor.lastCommand, ['FT.INFO', 'idx']);

      executor.response = ['redis', ['1', '2'], 'database', ['2']];
      expect(await executor.ftSynDump('idx'), {
        'redis': ['1', '2'],
        'database': ['2'],
      });
      expect(executor.lastCommand, ['FT.SYNDUMP', 'idx']);

      executor.response = 'OK';
      expect(
        await executor.ftSynUpdate('idx', 'g1', ['redis', 'database'], skipInitialScan: true),
        'OK',
      );
      expect(executor.lastCommand, [
        'FT.SYNUPDATE',
        'idx',
        'g1',
        'SKIPINITIALSCAN',
        'redis',
        'database',
      ]);

      executor.response = ['tag1', 'tag2'];
      expect(await executor.ftTagVals('idx', 'category'), ['tag1', 'tag2']);
      expect(executor.lastCommand, ['FT.TAGVALS', 'idx', 'category']);

      executor.response = 'plan';
      expect(await executor.ftExplain('idx', '@title:redis', dialect: 2), 'plan');
      expect(executor.lastCommand, ['FT.EXPLAIN', 'idx', '@title:redis', 'DIALECT', 2]);

      expect(await executor.ftExplainCli('idx', '@title:redis'), 'plan');
      expect(executor.lastCommand, ['FT.EXPLAINCLI', 'idx', '@title:redis']);

      executor.response = 'OK';
      expect(await executor.ftDropIndex('idx', deleteDocuments: true), 'OK');
      expect(executor.lastCommand, ['FT.DROPINDEX', 'idx', 'DD']);
    });

    test('hybrid helper passes through custom arguments', () async {
      final executor = _FakeSearchExecutor()..response = ['raw'];

      expect(await executor.ftHybrid('idx', ['SEARCH', '*']), ['raw']);
      expect(executor.lastCommand, ['FT.HYBRID', 'idx', 'SEARCH', '*']);
    });
  });
}
