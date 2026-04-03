import 'dart:async';
import 'dart:io';

import 'package:daredis/daredis.dart';
import 'package:daredis/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('Connection lifecycle', () {
    test('ReconnectPolicy uses exponential backoff capped by maxDelay', () {
      const policy = ReconnectPolicy(
        delay: Duration(milliseconds: 100),
        maxDelay: Duration(milliseconds: 350),
        backoffMultiplier: 2,
      );

      expect(policy.delayForAttempt(1), const Duration(milliseconds: 100));
      expect(policy.delayForAttempt(2), const Duration(milliseconds: 200));
      expect(policy.delayForAttempt(3), const Duration(milliseconds: 350));
      expect(policy.delayForAttempt(6), const Duration(milliseconds: 350));
    });

    test('connect is idempotent while a socket is already open', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final sockets = <Socket>[];

      final serverSubscription = server.listen(sockets.add);
      final connection = Connection(
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
      );

      await connection.connect();
      await connection.connect();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(sockets, hasLength(1));

      await connection.disconnect();
      await serverSubscription.cancel();
      for (final socket in sockets) {
        await socket.close();
      }
      await server.close();
    });

    test('disconnect does not schedule a reconnect', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final sockets = <Socket>[];

      final serverSubscription = server.listen(sockets.add);
      final connection = Connection(
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
        reconnectPolicy: const ReconnectPolicy(
          maxAttempts: 3,
          delay: Duration(milliseconds: 20),
        ),
      );

      await connection.connect();
      await connection.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(sockets, hasLength(1));

      await serverSubscription.cancel();
      for (final socket in sockets) {
        await socket.close();
      }
      await server.close();
    });

    test('quit sends QUIT and closes without reconnecting', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final sockets = <Socket>[];
      final received = <List<int>>[];

      final serverSubscription = server.listen((socket) {
        sockets.add(socket);
        socket.listen(
          (data) => received.add(List<int>.from(data)),
          onDone: () {},
        );
      });
      final connection = Connection(
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
        reconnectPolicy: const ReconnectPolicy(
          maxAttempts: 2,
          delay: Duration(milliseconds: 20),
        ),
      );

      await connection.connect();
      await connection.quit();
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(connection.isConnected, isFalse);
      expect(sockets, hasLength(1));
      expect(String.fromCharCodes(received.expand((chunk) => chunk)), contains('QUIT'));

      await serverSubscription.cancel();
      for (final socket in sockets) {
        await socket.close();
      }
      await server.close();
    });

    test('auth failures remain command errors during connect', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final sockets = <Socket>[];

      final serverSubscription = server.listen((socket) {
        sockets.add(socket);
        socket.listen((_) {
          socket
            ..add(
              '-WRONGPASS invalid username-password pair or user is disabled.\r\n'
                  .codeUnits,
            )
            ..close();
        });
      });

      final connection = Connection(
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
        password: 'bad-password',
      );

      await expectLater(
        connection.connect(),
        throwsA(isA<DaredisCommandException>()),
      );

      await serverSubscription.cancel();
      for (final socket in sockets) {
        await socket.close();
      }
      await server.close();
    });

    test('reports terminal reconnect failures via reconnectFailureHandler', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final sockets = <Socket>[];
      final failure = Completer<DaredisException>();
      var connectionCount = 0;

      final serverSubscription = server.listen((socket) {
        sockets.add(socket);
        connectionCount += 1;
        var responded = false;
        socket.listen((_) {
          if (responded) return;
          responded = true;
          if (connectionCount == 1) {
            socket.add('+OK\r\n'.codeUnits);
            unawaited(
              Future<void>.delayed(const Duration(milliseconds: 10), socket.close),
            );
            return;
          }
          socket
            ..add(
              '-WRONGPASS invalid username-password pair or user is disabled.\r\n'
                  .codeUnits,
            )
            ..close();
        });
      });

      final connection = Connection(
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
        password: 'secret',
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

      await connection.connect();
      final error = await failure.future.timeout(const Duration(seconds: 1));

      expect(error, isA<DaredisCommandException>());

      await connection.disconnect();
      await serverSubscription.cancel();
      for (final socket in sockets) {
        await socket.close();
      }
      await server.close();
    });

    test('connectionSetup runs on initial connect and reconnect', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final sockets = <Socket>[];
      final received = <String>[];
      var connectionCount = 0;
      final setupCount = Completer<void>();

      final serverSubscription = server.listen((socket) {
        sockets.add(socket);
        connectionCount += 1;
        var requestCount = 0;
        socket.listen((data) {
          final text = String.fromCharCodes(data);
          received.add(text);
          requestCount += 1;
          socket.add('+OK\r\n'.codeUnits);
          if (requestCount == 1 && connectionCount == 1) {
            unawaited(
              Future<void>.delayed(const Duration(milliseconds: 10), socket.close),
            );
          }
          if (received.where((entry) => entry.contains('CLIENT')).length >= 2 &&
              !setupCount.isCompleted) {
            setupCount.complete();
          }
        });
      });

      final connection = Connection(
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
        reconnectPolicy: const ReconnectPolicy(
          maxAttempts: 2,
          delay: Duration(milliseconds: 20),
        ),
        connectionSetup: (connection) => connection.sendCommand([
          'CLIENT',
          'SETNAME',
          'daredis-test',
        ]),
      );

      await connection.connect();
      await setupCount.future.timeout(const Duration(seconds: 1));

      expect(
        received.where((entry) => entry.contains('CLIENT')).length,
        2,
      );

      await connection.disconnect();
      await serverSubscription.cancel();
      for (final socket in sockets) {
        await socket.close();
      }
      await server.close();
    });
  });
}
