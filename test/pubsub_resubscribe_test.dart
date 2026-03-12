import 'package:daredis/src/pubsub.dart';
import 'package:test/test.dart';

void main() {
  group('PubSub resubscribe helpers', () {
    test('builds channel and pattern resubscribe commands', () {
      final commands = buildPubSubResubscribeCommands(
        channels: const ['news', 'alerts'],
        patterns: const ['news.*'],
      );

      expect(commands, [
        ['SUBSCRIBE', 'news', 'alerts'],
        ['PSUBSCRIBE', 'news.*'],
      ]);
    });

    test('skips empty subscription groups', () {
      expect(
        buildPubSubResubscribeCommands(
          channels: const [],
          patterns: const ['orders.*'],
        ),
        [
          ['PSUBSCRIBE', 'orders.*'],
        ],
      );
    });
  });
}
