class Decoders {
  static String string(dynamic res) {
    if (res == null) return '';
    return res.toString();
  }

  static String? toStringOrNull(dynamic res) {
    if (res == null) return null;
    return res.toString();
  }

  static int toInt(dynamic res) {
    if (res is int) return res;
    return int.parse(res.toString());
  }

  static int? toIntOrNull(dynamic res) {
    if (res == null) return null;
    return toInt(res);
  }

  static double toDouble(dynamic res) {
    if (res is double) return res;
    if (res is int) return res.toDouble();
    return double.parse(res.toString());
  }

  static double? toDoubleOrNull(dynamic res) {
    if (res == null) return null;
    return toDouble(res);
  }

  static bool toBool(dynamic res) {
    if (res is bool) return res;
    if (res is int) return res == 1;
    if (res is String) return res == 'OK' || res == '1' || res == 'true';
    return false;
  }

  static bool? toBoolOrNull(dynamic res) {
    if (res == null) return null;
    return toBool(res);
  }
}
