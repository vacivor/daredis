import 'package:daredis/src/commands/decoders.dart';
import 'package:daredis/src/crc16.dart';
import 'package:daredis/src/exceptions.dart';

const int _clusterSlotCount = 16384;

/// Host and port pair for a Redis Cluster node.
class ClusterNodeAddress {
  /// Hostname or IP address of the cluster node.
  final String host;

  /// TCP port of the cluster node.
  final int port;

  /// Creates a cluster node address.
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

/// In-memory slot-to-node mapping built from `CLUSTER SLOTS` responses.
class ClusterSlotCache {
  final List<_ClusterSlotOwners?> _slots = List<_ClusterSlotOwners?>.filled(
    _clusterSlotCount,
    null,
  );

  /// Returns the node responsible for [slot], or `null` when unknown.
  ClusterNodeAddress? nodeForSlot(int slot) {
    return primaryForSlot(slot);
  }

  /// Returns the primary node responsible for [slot], or `null` when unknown.
  ClusterNodeAddress? primaryForSlot(int slot) {
    if (slot < 0 || slot >= _clusterSlotCount) return null;
    return _slots[slot]?.primary;
  }

  /// Returns the node responsible for [key], or `null` when unknown.
  ClusterNodeAddress? nodeForKey(String key) {
    return nodeForSlot(slotForKey(key));
  }

  /// Returns the replica nodes responsible for [slot], or an empty list when
  /// no replica metadata is available.
  List<ClusterNodeAddress> replicasForSlot(int slot) {
    if (slot < 0 || slot >= _clusterSlotCount) return const [];
    return _slots[slot]?.replicas ?? const [];
  }

  /// Computes the Redis Cluster slot for [key], including hash tag handling.
  int slotForKey(String key) {
    final hashKey = _extractHashTag(key);
    return CRC16.getStringCRC16(hashKey) % _clusterSlotCount;
  }

  /// Updates the owner of [slot] to [node].
  void updateSlot(int slot, ClusterNodeAddress node) {
    if (slot < 0 || slot >= _clusterSlotCount) return;
    _slots[slot] = _ClusterSlotOwners(primary: node);
  }

  /// Replaces slot mappings using a raw `CLUSTER SLOTS` [response].
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
      final host = Decoders.string(masterInfo[0]);
      final port = _parseInt(masterInfo[1]);
      final primary = ClusterNodeAddress(host, port);
      final replicas = <ClusterNodeAddress>[];
      for (final replicaInfo in entry.skip(3)) {
        if (replicaInfo is! List || replicaInfo.length < 2) continue;
        replicas.add(
          ClusterNodeAddress(
            Decoders.string(replicaInfo[0]),
            _parseInt(replicaInfo[1]),
          ),
        );
      }
      final owners = _ClusterSlotOwners(
        primary: primary,
        replicas: List<ClusterNodeAddress>.unmodifiable(replicas),
      );
      for (var slot = start; slot <= end; slot++) {
        _slots[slot] = owners;
      }
    }
  }

  /// Returns the distinct nodes currently referenced by the slot table.
  Iterable<ClusterNodeAddress> uniqueNodes() {
    final nodes = <ClusterNodeAddress>{};
    for (final owners in _slots) {
      if (owners == null) continue;
      nodes.add(owners.primary);
      nodes.addAll(owners.replicas);
    }
    return nodes;
  }

  /// Returns the distinct primary nodes currently referenced by the slot table.
  Iterable<ClusterNodeAddress> uniquePrimaryNodes() {
    final nodes = <ClusterNodeAddress>{};
    for (final owners in _slots) {
      if (owners != null) nodes.add(owners.primary);
    }
    return nodes;
  }

  /// Returns the distinct replica nodes currently referenced by the slot table.
  Iterable<ClusterNodeAddress> uniqueReplicaNodes() {
    final nodes = <ClusterNodeAddress>{};
    for (final owners in _slots) {
      if (owners == null) continue;
      nodes.addAll(owners.replicas);
    }
    return nodes;
  }

  /// Whether [address] currently appears in replica metadata.
  bool isReplicaAddress(ClusterNodeAddress address) {
    for (final owners in _slots) {
      if (owners != null && owners.replicas.contains(address)) {
        return true;
      }
    }
    return false;
  }

  /// Whether no slots have been populated yet.
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
    return Decoders.toInt(value);
  }
}

class _ClusterSlotOwners {
  final ClusterNodeAddress primary;
  final List<ClusterNodeAddress> replicas;

  const _ClusterSlotOwners({
    required this.primary,
    this.replicas = const [],
  });
}

/// Converts a raw Redis key representation to a Dart string.
String keyToString(dynamic key) {
  if (key == null) return '';
  return Decoders.string(key);
}
