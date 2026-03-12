import 'package:daredis/daredis.dart';
import 'package:test/test.dart';

void main() {
  group('RedisPubSub', () {
    test('routes subscription and data messages to the right streams', () async {
      final pubsub = RedisPubSub(host: '127.0.0.1', port: 6379);

      final subscriptionFuture = pubsub.subscriptionEvents.first;
      final dataFuture = pubsub.dataMessages.first;

      pubsub.handleFrame(['subscribe', 'news', 1]);
      pubsub.handleFrame(['message', 'news', 'hello']);

      final subscription = await subscriptionFuture;
      final data = await dataFuture;

      expect(subscription.isSubscriptionEvent, true);
      expect(subscription.channel, 'news');
      expect(subscription.subscriptionCount, 1);

      expect(data.isDataMessage, true);
      expect(data.channel, 'news');
      expect(data.payload, 'hello');
    });

    test('getMessage can ignore subscription messages', () async {
      final pubsub = RedisPubSub(host: '127.0.0.1', port: 6379);

      final nextMessage = pubsub.getMessage(
        ignoreSubscriptionMessages: true,
      );

      pubsub.handleFrame(['subscribe', 'news', 1]);
      pubsub.handleFrame(['message', 'news', 'payload']);

      final message = await nextMessage;

      expect(message, isNotNull);
      expect(message!.type, 'message');
      expect(message.payload, 'payload');
    });

    test('getMessage returns null on timeout', () async {
      final pubsub = RedisPubSub(host: '127.0.0.1', port: 6379);

      final message = await pubsub.getMessage(
        timeout: const Duration(milliseconds: 10),
      );

      expect(message, isNull);
    });

    test('handleFrame supports pattern messages', () async {
      final pubsub = RedisPubSub(host: '127.0.0.1', port: 6379);

      final future = pubsub.dataMessages.first;
      pubsub.handleFrame(['pmessage', 'news.*', 'news.1', 'hello']);
      final message = await future;

      expect(message.type, 'pmessage');
      expect(message.pattern, 'news.*');
      expect(message.channel, 'news.1');
      expect(message.payload, 'hello');
    });
  });
}
