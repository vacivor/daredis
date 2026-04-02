import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:daredis/daredis.dart';
import 'package:daredis/src/exceptions.dart';
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

    test('handleFrame supports shard messages and shard subscription events', () async {
      final pubsub = RedisPubSub(host: '127.0.0.1', port: 6379);

      final subscriptionFuture = pubsub.subscriptionEvents.firstWhere(
        (message) => message.type == 'ssubscribe',
      );
      final dataFuture = pubsub.dataMessages.firstWhere(
        (message) => message.type == 'smessage',
      );

      pubsub.handleFrame(['ssubscribe', 'orders:{1}', 1]);
      pubsub.handleFrame(['smessage', 'orders:{1}', 'ready']);

      final subscription = await subscriptionFuture;
      final data = await dataFuture;

      expect(subscription.channel, 'orders:{1}');
      expect(subscription.subscriptionCount, 1);
      expect(subscription.isSubscriptionEvent, isTrue);

      expect(data.channel, 'orders:{1}');
      expect(data.payload, 'ready');
      expect(data.isDataMessage, isTrue);
    });

    test('close closes the message stream', () async {
      final pubsub = RedisPubSub(host: '127.0.0.1', port: 6379);

      final done = expectLater(pubsub.messages, emitsDone);

      await pubsub.close();

      await done;
    });

    test('close permanently closes the session', () async {
      final pubsub = RedisPubSub(host: '127.0.0.1', port: 6379);

      await pubsub.close();

      await expectLater(
        pubsub.connect(),
        throwsA(isA<DaredisStateException>()),
      );
    });

    test('subscribe timeout does not replay unacknowledged subscriptions on reconnect', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final commandTexts = <String>[];
      var connectionCount = 0;

      final serverSubscription = server.listen((socket) {
        connectionCount += 1;
        socket.listen((data) {
          final text = utf8.decode(data, allowMalformed: true);
          commandTexts.add(text);
          if (text.contains('confirmed')) {
            socket.add(
              '*3\r\n\$9\r\nsubscribe\r\n\$9\r\nconfirmed\r\n:1\r\n'.codeUnits,
            );
          }
        });
      });

      final pubsub = RedisPubSub(
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
        commandTimeout: const Duration(milliseconds: 40),
        reconnectPolicy: const ReconnectPolicy(
          maxAttempts: 3,
          delay: Duration(milliseconds: 20),
        ),
      );

      await pubsub.connect();

      await expectLater(
        pubsub.subscribe(['stale']),
        throwsA(isA<DaredisTimeoutException>()),
      );

      await Future<void>.delayed(const Duration(milliseconds: 120));
      await pubsub.subscribe(['confirmed']);

      expect(connectionCount, greaterThanOrEqualTo(2));
      expect(
        commandTexts.where((text) => text.contains('stale')),
        hasLength(1),
      );
      expect(
        commandTexts.where((text) => text.contains('confirmed')),
        hasLength(1),
      );

      await pubsub.close();
      await serverSubscription.cancel();
      await server.close();
    });

    test('unsubscribe timeout preserves confirmed subscriptions for reconnect', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final commandTexts = <String>[];
      var connectionCount = 0;

      final serverSubscription = server.listen((socket) {
        connectionCount += 1;
        socket.listen((data) {
          final text = utf8.decode(data, allowMalformed: true);
          commandTexts.add(text);
          if (text.contains('SUBSCRIBE') && text.contains('news')) {
            socket.add(
              '*3\r\n\$9\r\nsubscribe\r\n\$4\r\nnews\r\n:1\r\n'.codeUnits,
            );
          }
        });
      });

      final pubsub = RedisPubSub(
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
        commandTimeout: const Duration(milliseconds: 40),
        reconnectPolicy: const ReconnectPolicy(
          maxAttempts: 3,
          delay: Duration(milliseconds: 20),
        ),
      );

      await pubsub.connect();
      await pubsub.subscribe(['news']);

      await expectLater(
        pubsub.unsubscribe(['news']),
        throwsA(isA<DaredisTimeoutException>()),
      );

      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(connectionCount, greaterThanOrEqualTo(2));
      expect(
        commandTexts.where(
          (text) => text.contains('\r\nSUBSCRIBE\r\n') && text.contains('news'),
        ),
        hasLength(2),
      );
      expect(
        commandTexts.where(
          (text) =>
              text.contains('\r\nUNSUBSCRIBE\r\n') && text.contains('news'),
        ),
        hasLength(1),
      );

      await pubsub.close();
      await serverSubscription.cancel();
      await server.close();
    });

    test('reports terminal reconnect failures via reconnectFailureHandler', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final sockets = <Socket>[];
      final failure = Completer<DaredisException>();

      final serverSubscription = server.listen((socket) {
        sockets.add(socket);
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 10)).then((_) async {
            socket.destroy();
            await server.close();
          }),
        );
      });

      final pubsub = RedisPubSub(
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
        reconnectPolicy: const ReconnectPolicy(
          maxAttempts: 2,
          delay: Duration(milliseconds: 20),
        ),
        reconnectFailureHandler: (error, _) {
          if (!failure.isCompleted) {
            failure.complete(error);
          }
        },
      );

      await pubsub.connect();
      final error = await failure.future.timeout(const Duration(seconds: 1));

      expect(error, isA<DaredisNetworkException>());

      await pubsub.close();
      await serverSubscription.cancel();
      for (final socket in sockets) {
        await socket.close();
      }
      await server.close();
    });
  });
}
