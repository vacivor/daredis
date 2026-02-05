import 'dart:convert';

import 'package:daredis/src/crc16.dart';
import 'package:daredis/src/exceptions.dart';

const int _clusterSlotCount = 16384;

class ClusterNodeAddress {
  final String host;
  final int port;

  const ClusterNodeAddress(this.host, this.port);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClusterNodeAddress &&
          runtimeType == other.runtimeType &&
          host == other.host &&
          port == other.port;

  @override
  int get hashCode => Object.hash(host, port);

  @override
  String toString() => '$host:$port';
}

class ClusterSlotCache {
  final List<ClusterNodeAddress?> _slots = List<ClusterNodeAddress?>.filled(
    _clusterSlotCount,
    null,
  );

  ClusterNodeAddress? nodeForSlot(int slot) {
    if (slot < 0 || slot >= _clusterSlotCount) return null;
    return _slots[slot];
  }

  ClusterNodeAddress? nodeForKey(String key) {
    return nodeForSlot(slotForKey(key));
  }

  int slotForKey(String key) {
    final hashKey = _extractHashTag(key);
    return CRC16.getStringCRC16(hashKey) % _clusterSlotCount;
  }

  void updateSlot(int slot, ClusterNodeAddress node) {
    if (slot < 0 || slot >= _clusterSlotCount) return;
    _slots[slot] = node;
  }

  void updateFromSlotsResponse(dynamic response) {
    if (response is! List) {
      throw RespException('Unexpected CLUSTER SLOTS response: $response');
    }
    for (final entry in response) {
      if (entry is! List || entry.length < 3) continue;
      final start = _parseInt(entry[0]);
      final end = _parseInt(entry[1]);
      final masterInfo = entry[2];
      if (masterInfo is! List || masterInfo.length < 2) continue;
      final host = masterInfo[0].toString();
      final port = _parseInt(masterInfo[1]);
      final node = ClusterNodeAddress(host, port);
      for (var slot = start; slot <= end; slot++) {
        updateSlot(slot, node);
      }
    }
  }

  Iterable<ClusterNodeAddress> uniqueNodes() {
    final nodes = <ClusterNodeAddress>{};
    for (final node in _slots) {
      if (node != null) nodes.add(node);
    }
    return nodes;
  }

  bool get isEmpty => _slots.every((node) => node == null);

  String _extractHashTag(String key) {
    final start = key.indexOf('{');
    if (start == -1) return key;
    final end = key.indexOf('}', start + 1);
    if (end == -1 || end == start + 1) return key;
    return key.substring(start + 1, end);
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.parse(value.toString());
  }
}

String keyToString(dynamic key) {
  if (key == null) return '';
  if (key is String) return key;
  if (key is List<int>) {
    return utf8.decode(key, allowMalformed: true);
  }
  return key.toString();
}
