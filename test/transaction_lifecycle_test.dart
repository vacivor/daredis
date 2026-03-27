import 'package:daredis/daredis.dart';
import 'package:daredis/src/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('RedisTransaction lifecycle', () {
    test('close permanently closes the session', () async {
      final transaction = RedisTransaction.fromOptions(
        const ConnectionOptions(),
      );

      await transaction.close();

      await expectLater(
        transaction.connect(),
        throwsA(isA<DaredisStateException>()),
      );
    });

    test('quit permanently closes the session', () async {
      final transaction = RedisTransaction.fromOptions(
        const ConnectionOptions(),
      );

      await transaction.quit();

      await expectLater(
        transaction.connect(),
        throwsA(isA<DaredisStateException>()),
      );
    });
  });
}
