import 'dart:typed_data';

import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

class _FakeKeyExecutor extends RedisCommandExecutor with RedisKeyCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

void main() {
  group('RedisKeyCommands', () {
    test('dump builds DUMP and returns a nullable payload', () async {
      final executor = _FakeKeyExecutor()..response = 'serialized';

      final result = await executor.dump('user:{1}');

      expect(result, 'serialized');
      expect(executor.lastCommand, ['DUMP', 'user:{1}']);
    });

    test('dumpBytes preserves the serialized binary payload', () async {
      final executor = _FakeKeyExecutor()
        ..response = Uint8List.fromList([1, 0, 255, 42]);

      final result = await executor.dumpBytes('user:{1}');

      expect(result, Uint8List.fromList([1, 0, 255, 42]));
      expect(executor.lastCommand, ['DUMP', 'user:{1}']);
    });

    test('restore builds RESTORE with optional modifiers', () async {
      final executor = _FakeKeyExecutor()..response = 'OK';

      final result = await executor.restore(
        'user:{1}',
        5000,
        'serialized',
        replace: true,
        absTtl: true,
        idleTimeSeconds: 12,
        frequency: 3,
      );

      expect(result, 'OK');
      expect(executor.lastCommand, [
        'RESTORE',
        'user:{1}',
        5000,
        'serialized',
        'REPLACE',
        'ABSTTL',
        'IDLETIME',
        12,
        'FREQ',
        3,
      ]);
    });

    test('sort builds SORT and preserves nullable GET results', () async {
      final executor = _FakeKeyExecutor()
        ..response = ['2', null, '8'];

      final result = await executor.sort(
        'scores:{1}',
        byPattern: 'weight_*',
        offset: 0,
        count: 2,
        getPatterns: ['#', 'meta_*->name'],
        descending: true,
        alpha: true,
      );

      expect(result, ['2', null, '8']);
      expect(executor.lastCommand, [
        'SORT',
        'scores:{1}',
        'BY',
        'weight_*',
        'LIMIT',
        0,
        2,
        'GET',
        '#',
        'GET',
        'meta_*->name',
        'DESC',
        'ALPHA',
      ]);
    });

    test('sortStore builds SORT with STORE', () async {
      final executor = _FakeKeyExecutor()..response = 3;

      final result = await executor.sortStore(
        'scores:{1}',
        'sorted:{1}',
        descending: true,
      );

      expect(result, 3);
      expect(executor.lastCommand, [
        'SORT',
        'scores:{1}',
        'DESC',
        'STORE',
        'sorted:{1}',
      ]);
    });

    test('sortRo builds SORT_RO', () async {
      final executor = _FakeKeyExecutor()..response = ['a', 'b'];

      final result = await executor.sortRo('scores:{1}', alpha: true);

      expect(result, ['a', 'b']);
      expect(executor.lastCommand, ['SORT_RO', 'scores:{1}', 'ASC', 'ALPHA']);
    });

    test('sort requires both LIMIT offset and count', () {
      final executor = _FakeKeyExecutor();

      expect(
        () => executor.sort('scores:{1}', offset: 0),
        throwsArgumentError,
      );
    });

    test('migrate builds single-key MIGRATE with AUTH', () async {
      final executor = _FakeKeyExecutor()..response = 'OK';

      final result = await executor.migrate(
        '127.0.0.1',
        6379,
        key: 'user:{1}',
        destinationDb: 1,
        timeoutMilliseconds: 5000,
        copy: true,
        authPassword: 'secret',
      );

      expect(result, 'OK');
      expect(executor.lastCommand, [
        'MIGRATE',
        '127.0.0.1',
        6379,
        'user:{1}',
        1,
        5000,
        'COPY',
        'AUTH',
        'secret',
      ]);
    });

    test('migrate builds multi-key MIGRATE with AUTH2', () async {
      final executor = _FakeKeyExecutor()..response = 'NOKEY';

      final result = await executor.migrate(
        '127.0.0.1',
        6380,
        keys: ['user:{1}', 'profile:{1}'],
        destinationDb: 2,
        timeoutMilliseconds: 3000,
        replace: true,
        authUsername: 'default',
        authPassword: 'secret',
      );

      expect(result, 'NOKEY');
      expect(executor.lastCommand, [
        'MIGRATE',
        '127.0.0.1',
        6380,
        '',
        2,
        3000,
        'REPLACE',
        'AUTH2',
        'default',
        'secret',
        'KEYS',
        'user:{1}',
        'profile:{1}',
      ]);
    });

    test('migrate requires exactly one of key or keys', () {
      final executor = _FakeKeyExecutor();

      expect(
        () => executor.migrate(
          '127.0.0.1',
          6379,
          destinationDb: 0,
          timeoutMilliseconds: 1000,
        ),
        throwsArgumentError,
      );

      expect(
        () => executor.migrate(
          '127.0.0.1',
          6379,
          key: 'user:{1}',
          keys: ['profile:{1}'],
          destinationDb: 0,
          timeoutMilliseconds: 1000,
        ),
        throwsArgumentError,
      );
    });
  });
}
