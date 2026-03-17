import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

void main() {
  group('Command capabilities', () {
    test('cluster client exposes cluster-only client type', () {
      final standalone = Daredis();
      final cluster = DaredisCluster(
        options: const ClusterOptions(
          seeds: [ClusterNode('127.0.0.1', 7000)],
        ),
      );

      expect(standalone, isNot(isA<RedisClusterClient>()));
      expect(cluster, isA<RedisClusterClient>());
    });

    test('transaction session exposes transaction session type', () {
      final standalone = Daredis();
      final transaction = RedisTransaction.fromOptions(
        const ConnectionOptions(),
      );

      expect(standalone, isNot(isA<RedisTransactionSession>()));
      expect(transaction, isA<RedisTransactionSession>());
    });

    test('session openers are exposed as separate capabilities', () {
      final standalone = Daredis();
      final cluster = DaredisCluster(
        options: const ClusterOptions(
          seeds: [ClusterNode('127.0.0.1', 7000)],
        ),
      );

      expect(standalone, isA<RedisPubSubCapable>());
      expect(standalone, isA<RedisTransactionCapable>());
      expect(cluster, isA<RedisPubSubCapable>());
      expect(cluster, isNot(isA<RedisTransactionCapable>()));
    });
  });
}
