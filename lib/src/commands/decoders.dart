import 'dart:convert';
import 'dart:typed_data';

class Decoders {
  static bool isByteString(dynamic res) => res is Uint8List;

  static Uint8List bytes(dynamic res) {
    if (res is Uint8List) return res;
    if (res is List<int>) return Uint8List.fromList(res);
    if (res is String) return Uint8List.fromList(utf8.encode(res));
    throw ArgumentError.value(res, 'res', 'cannot be converted to bytes');
  }

  static Uint8List? toBytesOrNull(dynamic res) {
    if (res == null) return null;
    return bytes(res);
  }

  static String string(dynamic res) {
    if (res == null) return '';
    if (res is String) return res;
    if (res is Uint8List || res is List<int>) {
      return utf8.decode(bytes(res), allowMalformed: true);
    }
    return res.toString();
  }

  static String? toStringOrNull(dynamic res) {
    if (res == null) return null;
    return string(res);
  }

  static int toInt(dynamic res) {
    if (res is int) return res;
    return int.parse(string(res));
  }

  static int? toIntOrNull(dynamic res) {
    if (res == null) return null;
    return toInt(res);
  }

  static double toDouble(dynamic res) {
    if (res is double) return res;
    if (res is int) return res.toDouble();
    return double.parse(string(res));
  }

  static double? toDoubleOrNull(dynamic res) {
    if (res == null) return null;
    return toDouble(res);
  }

  static bool toBool(dynamic res) {
    if (res is bool) return res;
    if (res is int) return res == 1;
    final text = string(res);
    return text == 'OK' || text == '1' || text == 'true';
  }

  static bool? toBoolOrNull(dynamic res) {
    if (res == null) return null;
    return toBool(res);
  }

  static List<String> toStringList(dynamic res) {
    if (res is! List || res is Uint8List) return const [];
    return res.map(string).toList(growable: false);
  }
}
