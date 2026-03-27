import 'dart:typed_data';

import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

class _FakeHashExecutor extends RedisCommandExecutor with RedisHashCommands {
  List<dynamic>? lastCommand;
  dynamic response;

  @override
  Future<dynamic> sendCommand(List<dynamic> command, {Duration? timeout}) async {
    lastCommand = List<dynamic>.from(command);
    return response;
  }
}

void main() {
  group('RedisHashCommands', () {
    test('hash field expiration helpers build exact commands', () async {
      final executor = _FakeHashExecutor()..response = [1, -1];

      expect(
        await executor.hExpire(
          'hash:{1}',
          60,
          ['field1', 'field2'],
          condition: HashFieldExpireCondition.nx,
        ),
        [1, -1],
      );
      expect(executor.lastCommand, [
        'HEXPIRE',
        'hash:{1}',
        60,
        'NX',
        'FIELDS',
        2,
        'field1',
        'field2',
      ]);

      expect(
        await executor.hPExpireAt(
          'hash:{1}',
          1710000000000,
          ['field1'],
          condition: HashFieldExpireCondition.gt,
        ),
        [1, -1],
      );
      expect(executor.lastCommand, [
        'HPEXPIREAT',
        'hash:{1}',
        1710000000000,
        'GT',
        'FIELDS',
        1,
        'field1',
      ]);
    });

    test('hash ttl and expiretime helpers decode integer lists', () async {
      final executor = _FakeHashExecutor()..response = [120, -1, -2];

      expect(
        await executor.hTtl('hash:{1}', ['a', 'b', 'c']),
        [120, -1, -2],
      );
      expect(executor.lastCommand, [
        'HTTL',
        'hash:{1}',
        'FIELDS',
        3,
        'a',
        'b',
        'c',
      ]);

      expect(
        await executor.hExpireTime('hash:{1}', ['a', 'b', 'c']),
        [120, -1, -2],
      );
      expect(executor.lastCommand, [
        'HEXPIRETIME',
        'hash:{1}',
        'FIELDS',
        3,
        'a',
        'b',
        'c',
      ]);

      expect(
        await executor.hPExpireTime('hash:{1}', ['a', 'b']),
        [120, -1, -2],
      );
      expect(executor.lastCommand, [
        'HPEXPIRETIME',
        'hash:{1}',
        'FIELDS',
        2,
        'a',
        'b',
      ]);
    });

    test('hPersist, hGetDel and hGetEx build exact commands', () async {
      final executor = _FakeHashExecutor()..response = [1, -1];

      expect(await executor.hPersist('hash:{1}', ['a', 'b']), [1, -1]);
      expect(executor.lastCommand, [
        'HPERSIST',
        'hash:{1}',
        'FIELDS',
        2,
        'a',
        'b',
      ]);

      executor.response = ['v1', null];
      expect(await executor.hGetDel('hash:{1}', ['a', 'b']), ['v1', null]);
      expect(executor.lastCommand, [
        'HGETDEL',
        'hash:{1}',
        'FIELDS',
        2,
        'a',
        'b',
      ]);

      expect(
        await executor.hGetEx('hash:{1}', ['a'], ex: 30),
        ['v1', null],
      );
      expect(executor.lastCommand, [
        'HGETEX',
        'hash:{1}',
        'EX',
        30,
        'FIELDS',
        1,
        'a',
      ]);
    });

    test('hRandField helpers normalize reply shapes', () async {
      final executor = _FakeHashExecutor()..response = 'field1';

      expect(await executor.hRandField('hash:{1}'), 'field1');
      expect(executor.lastCommand, ['HRANDFIELD', 'hash:{1}']);

      executor.response = ['field1', 'field2'];
      expect(await executor.hRandFields('hash:{1}', 2), ['field1', 'field2']);
      expect(executor.lastCommand, ['HRANDFIELD', 'hash:{1}', 2]);

      executor.response = ['field1', 'v1', 'field2', null];
      expect(
        await executor.hRandFieldsWithValues('hash:{1}', 2),
        {'field1': 'v1', 'field2': null},
      );
      expect(executor.lastCommand, [
        'HRANDFIELD',
        'hash:{1}',
        2,
        'WITHVALUES',
      ]);
    });

    test('bytes helpers preserve raw hash payloads', () async {
      final executor = _FakeHashExecutor()
        ..response = Uint8List.fromList([1, 2, 3]);

      expect(
        await executor.hGetBytes('hash:{1}', 'field1'),
        Uint8List.fromList([1, 2, 3]),
      );
      expect(executor.lastCommand, ['HGET', 'hash:{1}', 'field1']);

      executor.response = [Uint8List.fromList([4]), null, Uint8List.fromList([5, 6])];
      expect(
        await executor.hmGetBytes('hash:{1}', ['a', 'b', 'c']),
        [Uint8List.fromList([4]), null, Uint8List.fromList([5, 6])],
      );
      expect(executor.lastCommand, ['HMGET', 'hash:{1}', 'a', 'b', 'c']);

      executor.response = [
        'field1',
        Uint8List.fromList([7, 8]),
        'field2',
        Uint8List.fromList([9]),
      ];
      expect(
        await executor.hGetAllBytes('hash:{1}'),
        {
          'field1': Uint8List.fromList([7, 8]),
          'field2': Uint8List.fromList([9]),
        },
      );
      expect(executor.lastCommand, ['HGETALL', 'hash:{1}']);

      executor.response = [Uint8List.fromList([10]), null];
      expect(
        await executor.hGetDelBytes('hash:{1}', ['a', 'b']),
        [Uint8List.fromList([10]), null],
      );
      expect(executor.lastCommand, [
        'HGETDEL',
        'hash:{1}',
        'FIELDS',
        2,
        'a',
        'b',
      ]);

      executor.response = [Uint8List.fromList([11, 12])];
      expect(
        await executor.hGetExBytes('hash:{1}', ['a'], px: 500),
        [Uint8List.fromList([11, 12])],
      );
      expect(executor.lastCommand, [
        'HGETEX',
        'hash:{1}',
        'PX',
        500,
        'FIELDS',
        1,
        'a',
      ]);

      executor.response = [Uint8List.fromList([13]), Uint8List.fromList([14, 15])];
      expect(
        await executor.hValsBytes('hash:{1}'),
        [Uint8List.fromList([13]), Uint8List.fromList([14, 15])],
      );
      expect(executor.lastCommand, ['HVALS', 'hash:{1}']);
    });

    test('hSetEx and hStrLen build exact commands', () async {
      final executor = _FakeHashExecutor()..response = 1;

      expect(
        await executor.hSetEx(
          'hash:{1}',
          {'field1': 'v1', 'field2': 'v2'},
          fnx: true,
          ex: 60,
        ),
        isTrue,
      );
      expect(executor.lastCommand, [
        'HSETEX',
        'hash:{1}',
        'FNX',
        'EX',
        60,
        'FIELDS',
        2,
        'field1',
        'v1',
        'field2',
        'v2',
      ]);

      executor.response = 4;
      expect(await executor.hStrLen('hash:{1}', 'field1'), 4);
      expect(executor.lastCommand, ['HSTRLEN', 'hash:{1}', 'field1']);
    });
  });
}
