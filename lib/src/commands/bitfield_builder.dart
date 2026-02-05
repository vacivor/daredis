part of '../../daredis.dart';

class BitFieldBuilder {
  final List<dynamic> _subcommands = [];

  List<dynamic> get subcommands => List.unmodifiable(_subcommands);

  BitFieldBuilder get(String type, int offset) {
    _subcommands.addAll(['GET', type, offset]);
    return this;
  }

  BitFieldBuilder set(String type, int offset, int value) {
    _subcommands.addAll(['SET', type, offset, value]);
    return this;
  }

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
