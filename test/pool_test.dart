import 'dart:async';

import 'package:daredis/src/exceptions.dart';
import 'package:daredis/src/pool.dart';
import 'package:test/test.dart';

void main() {
  group('Pool', () {
    test('reuses hot connections with LIFO enabled', () async {
      var nextId = 0;
      final pool = Pool<int>(
        config: PoolConfig(
          maxSize: 4,
          maxIdle: 4,
          useLifo: true,
          testOnBorrow: false,
          testOnReturn: false,
        ),
        create: () async => ++nextId,
      );

      final first = await pool.acquire();
      final second = await pool.acquire();
      await pool.release(first);
      await pool.release(second);

      final reused = await pool.acquire();

      expect(reused, second);
      await pool.release(reused);
      await pool.close();
    });

    test('disposes expired idle connections before reuse', () async {
      var nextId = 0;
      final disposed = <int>[];
      final pool = Pool<int>(
        config: PoolConfig(
          maxSize: 2,
          maxIdle: 2,
          idleTimeout: const Duration(milliseconds: 5),
          testOnBorrow: false,
          testOnReturn: false,
        ),
        create: () async => ++nextId,
        dispose: (item) async => disposed.add(item),
      );

      final first = await pool.acquire();
      await pool.release(first);
      await Future<void>.delayed(const Duration(milliseconds: 15));

      final second = await pool.acquire();

      expect(second, isNot(first));
      expect(disposed, contains(first));
      expect(pool.stats.disposedCount, 1);

      await pool.release(second);
      await pool.close();
    });

    test('awaits disposal of expired idle items before creating replacements', () async {
      var nextId = 0;
      var disposeStarted = false;
      var disposeFinished = false;
      final disposeCompleter = Completer<void>();

      final pool = Pool<int>(
        config: PoolConfig(
          maxSize: 1,
          maxIdle: 1,
          idleTimeout: const Duration(milliseconds: 5),
          testOnBorrow: false,
          testOnReturn: false,
        ),
        create: () async {
          if (nextId > 0) {
            expect(disposeStarted, isTrue);
            expect(disposeFinished, isTrue);
          }
          return ++nextId;
        },
        dispose: (item) async {
          disposeStarted = true;
          await disposeCompleter.future;
          disposeFinished = true;
        },
      );

      final first = await pool.acquire();
      await pool.release(first);
      await Future<void>.delayed(const Duration(milliseconds: 15));

      final secondFuture = pool.acquire();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(disposeStarted, isTrue);
      expect(disposeFinished, isFalse);

      disposeCompleter.complete();
      final second = await secondFuture;

      expect(second, isNot(first));

      await pool.release(second);
      await pool.close();
    });

    test('checked-out items do not accrue idle timeout until released', () async {
      var nextId = 0;
      final disposed = <int>[];
      final pool = Pool<int>(
        config: PoolConfig(
          maxSize: 1,
          maxIdle: 1,
          idleTimeout: const Duration(milliseconds: 5),
          testOnBorrow: false,
          testOnReturn: false,
        ),
        create: () async => ++nextId,
        dispose: (item) async => disposed.add(item),
      );

      final first = await pool.acquire();
      await Future<void>.delayed(const Duration(milliseconds: 15));
      await pool.release(first);

      final reused = await pool.acquire();

      expect(reused, first);
      expect(disposed, isEmpty);

      await pool.release(reused);
      await pool.close();
    });

    test('retries create failures and records metrics', () async {
      var attempts = 0;
      final pool = Pool<int>(
        config: PoolConfig(
          maxSize: 1,
          createMaxAttempts: 3,
          createRetryDelay: Duration.zero,
          testOnBorrow: false,
          testOnReturn: false,
        ),
        create: () async {
          attempts += 1;
          if (attempts < 3) {
            throw StateError('boom');
          }
          return 7;
        },
      );

      final item = await pool.acquire();

      expect(item, 7);
      expect(attempts, 3);
      expect(pool.stats.createdCount, 1);
      expect(pool.stats.createFailureCount, 2);
      expect(pool.stats.lastCreateFailureAt, isNotNull);

      await pool.release(item);
      await pool.close();
    });

    test('eviction updates timestamps and honors idle cleanup', () async {
      var nextId = 0;
      final disposed = <int>[];
      final pool = Pool<int>(
        config: PoolConfig(
          maxSize: 2,
          maxIdle: 2,
          idleTimeout: const Duration(milliseconds: 5),
          evictionInterval: const Duration(milliseconds: 10),
          evictionMaxItems: 1,
          testOnBorrow: false,
          testOnReturn: false,
          testWhileIdle: false,
        ),
        create: () async => ++nextId,
        dispose: (item) async => disposed.add(item),
      );

      final first = await pool.acquire();
      await pool.release(first);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(pool.stats.lastEvictionAt, isNotNull);
      expect(disposed, isNotEmpty);
      expect(pool.stats.disposedCount, greaterThanOrEqualTo(1));

      await pool.close();
    });

    test('times out waiting for a resource', () async {
      final pool = Pool<int>(
        config: PoolConfig(
          maxSize: 1,
          acquireTimeout: const Duration(milliseconds: 20),
          testOnBorrow: false,
          testOnReturn: false,
        ),
        create: () async => 1,
      );

      final item = await pool.acquire();

      await expectLater(
        pool.acquire(),
        throwsA(isA<DaredisTimeoutException>()),
      );

      await pool.release(item);
      await pool.close();
    });

    test('fails fast when waiter queue is full', () async {
      final pool = Pool<int>(
        config: PoolConfig(
          maxSize: 1,
          maxWaiters: 1,
          acquireTimeout: const Duration(seconds: 1),
          testOnBorrow: false,
          testOnReturn: false,
        ),
        create: () async => 1,
      );

      final item = await pool.acquire();
      final pendingAcquire = pool.acquire();

      await expectLater(
        pool.acquire(),
        throwsA(isA<DaredisStateException>()),
      );

      await pool.release(item);
      final reused = await pendingAcquire;
      expect(reused, 1);
      await pool.release(reused);
      await pool.close();
    });

    test('warms up to min idle', () async {
      var nextId = 0;
      final pool = Pool<int>(
        config: PoolConfig(
          maxSize: 4,
          minIdle: 2,
          maxIdle: 4,
          testOnBorrow: false,
          testOnReturn: false,
        ),
        create: () async => ++nextId,
      );

      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(pool.stats.idle, greaterThanOrEqualTo(2));
      expect(pool.stats.createdCount, greaterThanOrEqualTo(2));

      await pool.close();
    });
  });
}
