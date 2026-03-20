import 'package:daredis/src/cluster_slots.dart';

/// Parsed `MOVED` or `ASK` redirect returned by a Redis cluster node.
class ClusterRedirect {
  /// Hash slot that triggered the redirect.
  final int slot;

  /// Redirect target node.
  final ClusterNodeAddress address;

  /// Whether the redirect is permanent (`MOVED`) rather than transient (`ASK`).
  final bool isMoved;

  const ClusterRedirect({
    required this.slot,
    required this.address,
    required this.isMoved,
  });
}

/// Parses a `host:port` or `[ipv6]:port` cluster node address.
ClusterNodeAddress? parseClusterNodeAddress(String value) {
  if (value.startsWith('[')) {
    final endBracket = value.indexOf(']');
    if (endBracket == -1) return null;
    final host = value.substring(1, endBracket);
    final portPart = value.substring(endBracket + 2);
    final port = int.tryParse(portPart);
    if (port == null) return null;
    return ClusterNodeAddress(host, port);
  }

  final separator = value.lastIndexOf(':');
  if (separator == -1) return null;
  final host = value.substring(0, separator);
  final port = int.tryParse(value.substring(separator + 1));
  if (port == null) return null;
  return ClusterNodeAddress(host, port);
}

/// Parses a Redis error into a structured cluster redirect when possible.
ClusterRedirect? parseClusterRedirect(Object error) {
  final message = error.toString();
  final movedIndex = message.indexOf('MOVED ');
  final askIndex = message.indexOf('ASK ');
  final isMoved = movedIndex != -1;
  final isAsk = askIndex != -1;
  if (!isMoved && !isAsk) return null;

  final start = isMoved ? movedIndex : askIndex;
  final parts = message.substring(start).split(' ');
  if (parts.length < 3) return null;
  final slot = int.tryParse(parts[1]) ?? -1;
  final address = parseClusterNodeAddress(parts[2]);
  if (address == null || slot < 0) return null;
  return ClusterRedirect(slot: slot, address: address, isMoved: isMoved);
}

/// Whether an error indicates a retryable cluster condition.
bool isRetryableClusterError(Object error) {
  final message = error.toString().toUpperCase();
  return message.contains('TRYAGAIN') ||
      message.contains('CLUSTERDOWN') ||
      message.contains('LOADING');
}

/// Whether an error indicates cluster routing needs to be refreshed.
bool isClusterRoutingError(Object error) {
  final message = error.toString().toUpperCase();
  return message.contains('MOVED ') ||
      message.contains('ASK ') ||
      message.contains('CLUSTERDOWN') ||
      message.contains('TRYAGAIN') ||
      message.contains('CROSSSLOT');
}
