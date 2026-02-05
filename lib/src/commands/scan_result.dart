part of '../../daredis.dart';

class ScanResult<T> {
  final int cursor;
  final List<T> items;

  const ScanResult(this.cursor, this.items);

  bool get isComplete => cursor == 0;
}
