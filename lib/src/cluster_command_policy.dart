import 'package:daredis/src/cluster_command_spec.dart';
import 'package:daredis/src/cluster_slots.dart';
import 'package:daredis/src/exceptions.dart';

/// Internal cluster command routing and validation rules.
///
/// This keeps cluster-specific semantics concentrated in the routing layer
/// instead of spreading them across individual command helpers.
class ClusterCommandPolicy {
  /// Returns whether [command] has a registered cluster key specification.
  static bool hasKnownSpec(List<dynamic> command) {
    if (command.isEmpty) return false;
    final cmd = command.first.toString().toUpperCase();
    return ClusterCommandSpec.specs.containsKey(cmd);
  }

  /// Ensures [command] uses a registered cluster key specification.
  static void requireKnownSpec(List<dynamic> command, {required String context}) {
    if (hasKnownSpec(command)) return;
    final name = command.isEmpty ? '<empty>' : command.first.toString();
    throw DaredisUnsupportedException(
      'Cluster $context requires a known command spec for "$name". '
      'Use cluster.sendCommand() or add a ClusterCommandSpec entry first.',
    );
  }

  /// Returns the first extracted key for [command], or `null` when none exist.
  static String? firstKey(List<dynamic> command) {
    final keys = ClusterCommandSpec.extractKeys(command);
    if (keys.isEmpty) return null;
    return keys.first;
  }

  /// Validates that all keys in [command] hash to the same slot.
  static void validateSameSlot(
    List<dynamic> command,
    ClusterSlotCache slotCache,
  ) {
    final keys = ClusterCommandSpec.extractKeys(command);
    if (keys.length <= 1) return;
    ClusterCommandSpec.validateSameSlot(keys, slotCache);
  }

  /// Validates that all keys in [command] stay within the pinned [slot].
  static void validatePinnedSlot(
    List<dynamic> command, {
    required int slot,
    required ClusterSlotCache slotCache,
  }) {
    final keys = ClusterCommandSpec.extractKeys(command);
    for (final key in keys) {
      final nextSlot = slotCache.slotForKey(key);
      if (nextSlot != slot) {
        throw RespException(
          'CROSSSLOT Transaction is pinned to slot $slot but key "$key" '
          'maps to slot $nextSlot',
        );
      }
    }
  }
}
