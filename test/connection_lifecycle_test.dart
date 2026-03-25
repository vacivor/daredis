import 'dart:io';

import 'package:daredis/daredis.dart';
import 'package:daredis/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('Connection lifecycle', () {
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
  });
}
