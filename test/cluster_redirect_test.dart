import 'package:daredis/src/cluster_slots.dart';
import 'package:daredis/src/cluster_redirect.dart';
import 'package:test/test.dart';

void main() {
  group('Cluster redirect helpers', () {
    test('parses MOVED redirects', () {
      final redirect = parseClusterRedirect('MOVED 12182 10.0.0.12:7003');

      expect(redirect, isNotNull);
      expect(redirect!.slot, 12182);
      expect(redirect.address, const ClusterNodeAddress('10.0.0.12', 7003));
      expect(redirect.isMoved, isTrue);
    });

    test('parses ASK redirects with IPv6 addresses', () {
      final redirect = parseClusterRedirect('ASK 9 [2001:db8::1]:7005');

      expect(redirect, isNotNull);
      expect(redirect!.slot, 9);
      expect(redirect.address, const ClusterNodeAddress('2001:db8::1', 7005));
      expect(redirect.isMoved, isFalse);
    });

    test('detects retryable cluster errors', () {
      expect(isRetryableClusterError('TRYAGAIN slot migration'), isTrue);
      expect(isRetryableClusterError('CLUSTERDOWN hash slot not served'), isTrue);
      expect(isRetryableClusterError('LOADING Redis is loading the dataset'), isTrue);
      expect(isRetryableClusterError('ERR wrongtype'), isFalse);
    });

    test('detects routing-related cluster errors', () {
      expect(isClusterRoutingError('MOVED 1 127.0.0.1:7000'), isTrue);
      expect(isClusterRoutingError('ASK 1 127.0.0.1:7000'), isTrue);
      expect(isClusterRoutingError('CROSSSLOT Keys in request'), isTrue);
      expect(isClusterRoutingError('ERR wrongtype'), isFalse);
    });

    test('parses standalone node addresses', () {
      expect(
        parseClusterNodeAddress('127.0.0.1:7002'),
        const ClusterNodeAddress('127.0.0.1', 7002),
      );
      expect(parseClusterNodeAddress('invalid-address'), isNull);
    });
  });
}
