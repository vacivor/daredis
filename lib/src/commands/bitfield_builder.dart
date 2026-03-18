part of '../../daredis.dart';

/// Builder for Redis `BITFIELD` and `BITFIELD_RO` subcommands.
class BitFieldBuilder {
  final List<dynamic> _subcommands = [];

  /// Returns the collected subcommands in the order they were added.
  List<dynamic> get subcommands => List.unmodifiable(_subcommands);

  /// Appends a `GET` subcommand for the integer [type] at [offset].
  BitFieldBuilder get(String type, int offset) {
    _subcommands.addAll(['GET', type, offset]);
    return this;
  }

  /// Appends a `SET` subcommand for the integer [type] at [offset].
  BitFieldBuilder set(String type, int offset, int value) {
    _subcommands.addAll(['SET', type, offset, value]);
    return this;
  }

  /// Appends an `INCRBY` subcommand for the integer [type] at [offset].
  ///
  /// When [overflow] is provided, an `OVERFLOW` modifier is emitted before the
  /// increment operation.
  BitFieldBuilder incrBy(
    String type,
    int offset,
    int increment, {
    String? overflow,
  }) {
    if (overflow != null) {
      _subcommands.addAll(['OVERFLOW', overflow]);
    }
    _subcommands.addAll(['INCRBY', type, offset, increment]);
    return this;
  }
}
