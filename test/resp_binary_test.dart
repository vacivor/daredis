import 'dart:typed_data';

import 'package:daredis/src/resp.dart';
import 'package:test/test.dart';

void main() {
  group('RESP binary safety', () {
    test('decoder can resume from a byte offset without copying prefixes', () {
      final decoder = RespDecoder();
      final payload = Uint8List.fromList('+OK\r\n:42\r\n'.codeUnits);

      final first = decoder.decode(payload);
      expect(first, isA<RespSimpleString>());
      expect((first as RespSimpleString).value, 'OK');

      final second = decoder.decode(payload, offset: decoder.consumedBytes);
      expect(second, isA<RespInteger>());
      expect((second as RespInteger).value, 42);
    });

    test('bulk strings decode to Uint8List by default', () {
      final native = respValueToNative(
        RespBulkString(Uint8List.fromList([0, 159, 146, 150])),
      );

      expect(native, isA<Uint8List>());
      expect(native, Uint8List.fromList([0, 159, 146, 150]));
    });

    test('nested arrays preserve binary-safe bulk strings', () {
      final native = respValueToNative(
        RespArray([
          RespBulkString(Uint8List.fromList([97, 98, 99])),
          RespArray([
            RespBulkString(Uint8List.fromList([1, 2])),
          ]),
        ]),
      );

      expect(native, isA<List<dynamic>>());
      expect(native[0], Uint8List.fromList([97, 98, 99]));
      expect(native[1][0], Uint8List.fromList([1, 2]));
    });
  });
}
