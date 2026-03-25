import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

void main() {
  group('Client pool config', () {
    test('Daredis exposes configured pool stats before connect', () async {
      final client = Daredis(
        poolSize: 6,
        maxWaiters: 12,
        acquireTimeout: const Duration(seconds: 2),
        idleTimeout: const Duration(seconds: 3),
        evictionInterval: const Duration(seconds: 1),
        createMaxAttempts: 4,
        createRetryDelay: const Duration(milliseconds: 25),
        useLifo: true,
      );

      expect(client.poolStats.maxSize, 6);
      expect(client.poolStats.maxIdle, 6);
      expect(client.poolStats.minIdle, 0);
      expect(client.poolStats.total, 0);
      expect(client.poolStats.isClosed, false);

      await client.close();
      expect(client.poolStats.isClosed, true);
    });

    test('DaredisCluster exposes configured pool stats before connect', () async {
      final cluster = DaredisCluster(
        options: const ClusterOptions(
          seeds: [ClusterNode('127.0.0.1', 7000)],
          nodePoolSize: 5,
          poolMaxWaiters: 9,
          poolAcquireTimeout: Duration(seconds: 2),
          poolIdleTimeout: Duration(seconds: 4),
          poolEvictionInterval: Duration(seconds: 1),
          poolCreateMaxAttempts: 3,
          poolCreateRetryDelay: Duration(milliseconds: 40),
          poolUseLifo: true,
        ),
      );

      expect(cluster.poolStats.maxSize, 5);
      expect(cluster.poolStats.maxIdle, 5);
      expect(cluster.poolStats.minIdle, 0);
      expect(cluster.poolStats.total, 0);
      expect(cluster.poolStats.isClosed, false);

      await cluster.close();
      expect(cluster.poolStats.isClosed, true);
    });
  });
}
