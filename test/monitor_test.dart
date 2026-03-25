import 'dart:io';

import 'package:daredis/daredis.dart';
import 'package:daredis/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('RedisMonitor', () {
    test('routes decoded frames to the message stream', () async {
      final monitor = RedisMonitor(host: '127.0.0.1', port: 6379);

      final next = monitor.messages.first;
      monitor.handleFrame('1710000000.0 [0 127.0.0.1:6379] "PING"');

      expect(
        await next,
        '1710000000.0 [0 127.0.0.1:6379] "PING"',
      );
    });

    test('getMessage returns null on timeout', () async {
      final monitor = RedisMonitor(host: '127.0.0.1', port: 6379);

      final message = await monitor.getMessage(
        timeout: const Duration(milliseconds: 10),
      );

      expect(message, isNull);
    });

    test('connect enters monitor mode and streams messages', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final sockets = <Socket>[];

      final serverSubscription = server.listen((socket) {
        sockets.add(socket);
        var responded = false;
        socket.listen((_) {
          if (responded) return;
          responded = true;
          socket.add('+OK\r\n'.codeUnits);
          socket.add(
            '+1710000000.0 [0 127.0.0.1:6379] "PING"\r\n'.codeUnits,
          );
        });
      });

      final monitor = RedisMonitor(
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
      );

      final nextMessage = monitor.messages.first.timeout(
        const Duration(seconds: 1),
      );
      await monitor.connect();
      final message = await nextMessage;

      expect(message, '1710000000.0 [0 127.0.0.1:6379] "PING"');

      await monitor.close();
      await serverSubscription.cancel();
      for (final socket in sockets) {
        await socket.close();
      }
      await server.close();
    });

    test('close closes the message stream', () async {
      final monitor = RedisMonitor(host: '127.0.0.1', port: 6379);

      final done = expectLater(monitor.messages, emitsDone);

      await monitor.close();

      await done;
    });

    test('close permanently closes the session', () async {
      final monitor = RedisMonitor(host: '127.0.0.1', port: 6379);

      await monitor.close();

      await expectLater(
        monitor.connect(),
        throwsA(isA<DaredisStateException>()),
      );
    });
  });
}
