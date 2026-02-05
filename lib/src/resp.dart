import 'dart:convert';
import 'dart:typed_data';

import 'exceptions.dart';

const int _cr = 13;
const int _lf = 10;
const int _crlfLength = 2;
const int _nullLength = -1;

const int _byteTypeSimpleString = 43; // +
const int _byteTypeSimpleError = 45; // -
const int _byteTypeInteger = 58; // :
const int _byteTypeBulkString = 36; // $
const int _byteTypeArray = 42; // *
const int _byteTypeNull = 95; // _
const int _byteTypeBoolean = 35; // #
const int _byteTypeDouble = 44; // ,
const int _byteTypeBigNumber = 40; // (
const int _byteTypeMap = 37; // %
const int _byteTypeSet = 126; // ~
const int _byteTypeBlobError = 33; // !
const int _byteTypeVerbatimString = 61; // =
const int _byteTypeAttribute = 124; // |
const int _byteTypePush = 62; // >
const int _byteTypeChunkedString = 59; // ;

const int _byteBoolTrue = 116; // t
const int _byteBoolFalse = 102; // f

final Uint8List _crlfBytes = Uint8List.fromList([_cr, _lf]);

abstract class RespValue {
  const RespValue();
}

class RespNull extends RespValue {
  const RespNull();
}

const RespNull respNull = RespNull();

class RespSimpleString extends RespValue {
  final String value;

  const RespSimpleString(this.value);
}

class RespSimpleError extends RespValue implements Exception {
  final String message;

  const RespSimpleError(this.message);

  @override
  String toString() => 'RespSimpleError: $message';
}

class RespInteger extends RespValue {
  final int value;

  const RespInteger(this.value);
}

class RespDouble extends RespValue {
  final double value;

  const RespDouble(this.value);
}

class RespBigNumber extends RespValue {
  final BigInt value;

  const RespBigNumber(this.value);
}

class RespBoolean extends RespValue {
  final bool value;

  const RespBoolean(this.value);
}

class RespBulkString extends RespValue {
  final Uint8List bytes;

  const RespBulkString(this.bytes);

  factory RespBulkString.fromString(String value) {
    return RespBulkString(Uint8List.fromList(utf8.encode(value)));
  }

  String asString({bool allowMalformed = true}) {
    return utf8.decode(bytes, allowMalformed: allowMalformed);
  }
}

class RespArray extends RespValue {
  final List<RespValue?> items;

  const RespArray(this.items);
}

class RespSet extends RespValue {
  final List<RespValue?> items;

  const RespSet(this.items);
}

class RespMap extends RespValue {
  final List<MapEntry<RespValue?, RespValue?>> entries;

  const RespMap(this.entries);
}

class RespBlobError extends RespValue implements Exception {
  final Uint8List bytes;

  RespBlobError(this.bytes);

  factory RespBlobError.fromString(String message) {
    return RespBlobError(Uint8List.fromList(utf8.encode(message)));
  }

  String message({bool allowMalformed = true}) {
    return utf8.decode(bytes, allowMalformed: allowMalformed);
  }

  @override
  String toString() => 'RespBlobError: ${message()}';
}

class RespVerbatimString extends RespValue {
  final String format;
  final String value;

  const RespVerbatimString(this.format, this.value);
}

class RespAttribute extends RespValue {
  final List<MapEntry<RespValue?, RespValue?>> attributes;
  final RespValue? value;

  const RespAttribute(this.attributes, this.value);
}

class RespPush extends RespValue {
  final List<RespValue?> items;

  const RespPush(this.items);
}

class RespChunkedString extends RespValue {
  final List<Uint8List> chunks;

  const RespChunkedString(this.chunks);

  Uint8List concatBytes() {
    final builder = BytesBuilder(copy: false);
    for (final chunk in chunks) {
      builder.add(chunk);
    }
    return builder.toBytes();
  }
}

dynamic respValueToNative(RespValue? value, {bool allowMalformed = true}) {
  if (value == null || value is RespNull) return null;
  if (value is RespSimpleString) return value.value;
  if (value is RespSimpleError) {
    throw DaredisCommandException(value.message);
  }
  if (value is RespInteger) return value.value;
  if (value is RespDouble) return value.value;
  if (value is RespBigNumber) return value.value;
  if (value is RespBoolean) return value.value;
  if (value is RespBulkString) {
    return value.asString(allowMalformed: allowMalformed);
  }
  if (value is RespArray) {
    return value.items
        .map((item) => respValueToNative(item, allowMalformed: allowMalformed))
        .toList();
  }
  if (value is RespSet) {
    return value.items
        .map((item) => respValueToNative(item, allowMalformed: allowMalformed))
        .toList();
  }
  if (value is RespMap) {
    return Map<dynamic, dynamic>.fromEntries(
      value.entries.map(
        (entry) => MapEntry(
          respValueToNative(entry.key, allowMalformed: allowMalformed),
          respValueToNative(entry.value, allowMalformed: allowMalformed),
        ),
      ),
    );
  }
  if (value is RespBlobError) {
    throw DaredisCommandException(
      value.message(allowMalformed: allowMalformed),
    );
  }
  if (value is RespVerbatimString) return value.value;
  if (value is RespAttribute) {
    return respValueToNative(value.value, allowMalformed: allowMalformed);
  }
  if (value is RespPush) {
    return value.items
        .map((item) => respValueToNative(item, allowMalformed: allowMalformed))
        .toList();
  }
  if (value is RespChunkedString) {
    return utf8.decode(value.concatBytes(), allowMalformed: allowMalformed);
  }
  throw RespException('Unsupported RESP value: ${value.runtimeType}');
}

class RespEncoder {
  Uint8List encode(dynamic value) {
    return _encodeValue(_coerce(value));
  }

  Uint8List encodeCommand(List<dynamic> command) {
    final items = <RespValue>[];
    for (final arg in command) {
      if (arg == null) {
        throw DaredisArgumentException('Command arguments cannot be null');
      }
      items.add(_coerceCommandArg(arg));
    }
    return _encodeAggregate(_byteTypeArray, items);
  }

  RespValue _coerce(dynamic value) {
    if (value is RespValue) return value;
    if (value == null) return respNull;
    if (value is String) return RespBulkString.fromString(value);
    if (value is int) return RespInteger(value);
    if (value is double) return RespDouble(value);
    if (value is bool) return RespBoolean(value);
    if (value is BigInt) return RespBigNumber(value);
    if (value is Uint8List) return RespBulkString(value);
    if (value is List) {
      return RespArray(value.map(_coerce).toList());
    }
    if (value is Set) {
      return RespSet(value.map(_coerce).toList());
    }
    if (value is Map) {
      return RespMap(
        value.entries
            .map((entry) => MapEntry(_coerce(entry.key), _coerce(entry.value)))
            .toList(),
      );
    }
    throw RespException(
      'Unsupported value for RESP encoding: ${value.runtimeType}',
    );
  }

  RespValue _coerceCommandArg(dynamic value) {
    if (value is RespBulkString) return value;
    if (value is Uint8List) return RespBulkString(value);
    return RespBulkString.fromString(value.toString());
  }

  Uint8List _encodeValue(RespValue value) {
    if (value is RespNull) {
      return _encodeNull();
    }
    if (value is RespSimpleString) {
      return _encodeSimpleString(value.value);
    }
    if (value is RespSimpleError) {
      return _encodeSimpleError(value.message);
    }
    if (value is RespInteger) {
      return _encodeNumber(_byteTypeInteger, value.value.toString());
    }
    if (value is RespDouble) {
      return _encodeNumber(_byteTypeDouble, value.value.toString());
    }
    if (value is RespBigNumber) {
      return _encodeNumber(_byteTypeBigNumber, value.value.toString());
    }
    if (value is RespBoolean) {
      return _encodeBoolean(value.value);
    }
    if (value is RespBulkString) {
      return _encodeBulkBytes(value.bytes);
    }
    if (value is RespArray) {
      return _encodeAggregate(_byteTypeArray, value.items);
    }
    if (value is RespSet) {
      return _encodeAggregate(_byteTypeSet, value.items);
    }
    if (value is RespMap) {
      return _encodeMap(value.entries);
    }
    if (value is RespBlobError) {
      return _encodeBlobError(value.bytes);
    }
    if (value is RespVerbatimString) {
      return _encodeVerbatimString(value);
    }
    if (value is RespAttribute) {
      return _encodeAttribute(value);
    }
    if (value is RespPush) {
      return _encodePush(value);
    }
    if (value is RespChunkedString) {
      return _encodeChunkedString(value.chunks);
    }
    throw RespException('Unsupported RESP value: ${value.runtimeType}');
  }

  Uint8List _encodeNull() {
    return Uint8List.fromList([_byteTypeNull, _cr, _lf]);
  }

  Uint8List _encodeSimpleString(String value) {
    final builder = BytesBuilder(copy: false);
    builder.addByte(_byteTypeSimpleString);
    builder.add(utf8.encode(value));
    builder.add(_crlfBytes);
    return builder.toBytes();
  }

  Uint8List _encodeSimpleError(String message) {
    final builder = BytesBuilder(copy: false);
    builder.addByte(_byteTypeSimpleError);
    builder.add(utf8.encode(message));
    builder.add(_crlfBytes);
    return builder.toBytes();
  }

  Uint8List _encodeBoolean(bool value) {
    return Uint8List.fromList([
      _byteTypeBoolean,
      value ? _byteBoolTrue : _byteBoolFalse,
      _cr,
      _lf,
    ]);
  }

  Uint8List _encodeNumber(int typeByte, String number) {
    final builder = BytesBuilder(copy: false);
    builder.addByte(typeByte);
    builder.add(utf8.encode(number));
    builder.add(_crlfBytes);
    return builder.toBytes();
  }

  Uint8List _encodeBulkBytes(Uint8List bytes) {
    final builder = BytesBuilder(copy: false);
    builder.addByte(_byteTypeBulkString);
    builder.add(utf8.encode(bytes.length.toString()));
    builder.add(_crlfBytes);
    builder.add(bytes);
    builder.add(_crlfBytes);
    return builder.toBytes();
  }

  Uint8List _encodeAggregate(int typeByte, List<RespValue?> items) {
    final builder = BytesBuilder(copy: false);
    builder.addByte(typeByte);
    builder.add(utf8.encode(items.length.toString()));
    builder.add(_crlfBytes);
    for (final item in items) {
      builder.add(item == null ? _encodeNull() : encode(item));
    }
    return builder.toBytes();
  }

  Uint8List _encodeMap(List<MapEntry<RespValue?, RespValue?>> entries) {
    final builder = BytesBuilder(copy: false);
    builder.addByte(_byteTypeMap);
    builder.add(utf8.encode(entries.length.toString()));
    builder.add(_crlfBytes);
    for (final entry in entries) {
      builder.add(entry.key == null ? _encodeNull() : encode(entry.key!));
      builder.add(entry.value == null ? _encodeNull() : encode(entry.value!));
    }
    return builder.toBytes();
  }

  Uint8List _encodeBlobError(Uint8List bytes) {
    final builder = BytesBuilder(copy: false);
    builder.addByte(_byteTypeBlobError);
    builder.add(utf8.encode(bytes.length.toString()));
    builder.add(_crlfBytes);
    builder.add(bytes);
    builder.add(_crlfBytes);
    return builder.toBytes();
  }

  Uint8List _encodeVerbatimString(RespVerbatimString value) {
    if (value.format.length != 3) {
      throw RespException('Verbatim string format must be 3 characters');
    }
    final payload = utf8.encode('${value.format}:${value.value}');
    final builder = BytesBuilder(copy: false);
    builder.addByte(_byteTypeVerbatimString);
    builder.add(utf8.encode(payload.length.toString()));
    builder.add(_crlfBytes);
    builder.add(payload);
    builder.add(_crlfBytes);
    return builder.toBytes();
  }

  Uint8List _encodeAttribute(RespAttribute value) {
    final builder = BytesBuilder(copy: false);
    builder.addByte(_byteTypeAttribute);
    builder.add(utf8.encode(value.attributes.length.toString()));
    builder.add(_crlfBytes);
    for (final entry in value.attributes) {
      builder.add(entry.key == null ? _encodeNull() : encode(entry.key!));
      builder.add(entry.value == null ? _encodeNull() : encode(entry.value!));
    }
    builder.add(value.value == null ? _encodeNull() : encode(value.value!));
    return builder.toBytes();
  }

  Uint8List _encodePush(RespPush value) {
    final builder = BytesBuilder(copy: false);
    builder.addByte(_byteTypePush);
    builder.add(utf8.encode(value.items.length.toString()));
    builder.add(_crlfBytes);
    for (final item in value.items) {
      builder.add(item == null ? _encodeNull() : encode(item));
    }
    return builder.toBytes();
  }

  Uint8List _encodeChunkedString(List<Uint8List> chunks) {
    final builder = BytesBuilder(copy: false);
    for (final chunk in chunks) {
      builder.addByte(_byteTypeChunkedString);
      builder.add(utf8.encode(chunk.length.toString()));
      builder.add(_crlfBytes);
      builder.add(chunk);
      builder.add(_crlfBytes);
    }
    builder.addByte(_byteTypeChunkedString);
    builder.add(utf8.encode('0'));
    builder.add(_crlfBytes);
    return builder.toBytes();
  }
}

class RespDecoder {
  int _offset = 0;
  Uint8List _data = Uint8List(0);

  int get consumedBytes => _offset;

  RespValue? decode(Uint8List data) {
    _data = data;
    _offset = 0;
    return _decodeNext();
  }

  RespValue? _decodeNext() {
    if (_offset >= _data.length) {
      throw IncompleteDataException();
    }

    final type = _data[_offset++];
    if (type == _byteTypeSimpleString) {
      return RespSimpleString(_readLineAsString());
    }
    if (type == _byteTypeSimpleError) {
      return RespSimpleError(_readLineAsString());
    }
    if (type == _byteTypeInteger) {
      return RespInteger(int.parse(_readLineAsString()));
    }
    if (type == _byteTypeBulkString) {
      final length = int.parse(_readLineAsString());
      if (length == _nullLength) return respNull;
      return RespBulkString(_readExactBytes(length));
    }
    if (type == _byteTypeArray) {
      final length = int.parse(_readLineAsString());
      if (length == _nullLength) return respNull;
      final items = <RespValue?>[];
      for (var i = 0; i < length; i++) {
        items.add(_decodeNext());
      }
      return RespArray(items);
    }
    if (type == _byteTypeNull) {
      _readLineBytes();
      return respNull;
    }
    if (type == _byteTypeBoolean) {
      final val = _readLineBytes();
      return RespBoolean(val.length == 1 && val[0] == _byteBoolTrue);
    }
    if (type == _byteTypeDouble) {
      return RespDouble(double.parse(_readLineAsString()));
    }
    if (type == _byteTypeBigNumber) {
      return RespBigNumber(BigInt.parse(_readLineAsString()));
    }
    if (type == _byteTypeMap) {
      final length = int.parse(_readLineAsString());
      if (length == _nullLength) return respNull;
      final entries = <MapEntry<RespValue?, RespValue?>>[];
      for (var i = 0; i < length; i++) {
        final key = _decodeNext();
        final value = _decodeNext();
        entries.add(MapEntry(key, value));
      }
      return RespMap(entries);
    }
    if (type == _byteTypeSet) {
      final length = int.parse(_readLineAsString());
      if (length == _nullLength) return respNull;
      final items = <RespValue?>[];
      for (var i = 0; i < length; i++) {
        items.add(_decodeNext());
      }
      return RespSet(items);
    }
    if (type == _byteTypeBlobError) {
      final length = int.parse(_readLineAsString());
      if (length == _nullLength) return RespBlobError(Uint8List(0));
      return RespBlobError(_readExactBytes(length));
    }
    if (type == _byteTypeVerbatimString) {
      final length = int.parse(_readLineAsString());
      if (length == _nullLength) return respNull;
      final payload = _readExactBytes(length);
      final split = _splitVerbatimPayload(payload);
      return RespVerbatimString(split.format, split.value);
    }
    if (type == _byteTypeAttribute) {
      final length = int.parse(_readLineAsString());
      final attributes = <MapEntry<RespValue?, RespValue?>>[];
      if (length > 0) {
        for (var i = 0; i < length; i++) {
          attributes.add(MapEntry(_decodeNext(), _decodeNext()));
        }
      }
      final value = _decodeNext();
      return RespAttribute(attributes, value);
    }
    if (type == _byteTypePush) {
      final length = int.parse(_readLineAsString());
      if (length == _nullLength) return respNull;
      final items = <RespValue?>[];
      for (var i = 0; i < length; i++) {
        items.add(_decodeNext());
      }
      return RespPush(items);
    }
    if (type == _byteTypeChunkedString) {
      final chunks = <Uint8List>[];
      while (true) {
        final length = int.parse(_readLineAsString());
        if (length == 0) {
          break;
        }
        chunks.add(_readExactBytes(length));
        if (_offset >= _data.length) {
          throw IncompleteDataException();
        }
        final nextType = _data[_offset++];
        if (nextType != _byteTypeChunkedString) {
          throw RespException('Expected chunked string continuation');
        }
      }
      return RespChunkedString(chunks);
    }

    throw RespException('Unknown RESP type byte: $type');
  }

  Uint8List _readLineBytes() {
    final start = _offset;
    while (_offset < _data.length - 1) {
      if (_data[_offset] == _cr && _data[_offset + 1] == _lf) {
        final res = _data.sublist(start, _offset);
        _offset += _crlfLength;
        return res;
      }
      _offset++;
    }
    throw IncompleteDataException();
  }

  String _readLineAsString() {
    return utf8.decode(_readLineBytes());
  }

  Uint8List _readExactBytes(int length) {
    if (_offset + length + _crlfLength > _data.length) {
      throw IncompleteDataException();
    }
    final res = _data.sublist(_offset, _offset + length);
    _offset += length;
    if (_data[_offset] != _cr || _data[_offset + 1] != _lf) {
      throw RespException('Expected CRLF after bulk data');
    }
    _offset += _crlfLength;
    return res;
  }

  _VerbatimPayload _splitVerbatimPayload(Uint8List payload) {
    final separatorIndex = payload.indexOf(58); // :
    if (separatorIndex < 0) {
      return _VerbatimPayload('', utf8.decode(payload, allowMalformed: true));
    }
    final format = utf8.decode(payload.sublist(0, separatorIndex));
    final value = utf8.decode(
      payload.sublist(separatorIndex + 1),
      allowMalformed: true,
    );
    return _VerbatimPayload(format, value);
  }
}

class _VerbatimPayload {
  final String format;
  final String value;

  _VerbatimPayload(this.format, this.value);
}
