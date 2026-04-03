## 0.3.0

### Breaking changes

- Narrowed the session capability interfaces to marker-only traits so their abstract API no longer advertises opener methods with misleading `dynamic` signatures.

### Improvements

- Added explicit reconnect terminal-failure hooks for connections, pub/sub sessions, and monitor sessions via `ConnectionOptions.reconnectFailureHandler`.
- Added observable replica-aware cluster routing with `ClusterReadPreference.replicaPreferred`, `ClusterRouteObserver`, and `ClusterRouteInfo`.
- Expanded and tightened conservative replica routing for keyed read commands, including arg-sensitive handling for commands such as `SORT`, `GEORADIUS`, and `JSON.DEBUG`.
- Clarified replica eligibility semantics so only keyed read commands participate in replica routing, while keyless or filter-based reads stay on stable primaries.
- Lowered the minimum supported Dart SDK from `3.10.7` to `3.8.0` to widen package compatibility without changing the current API surface.

### Fixes

- Hardened pub/sub acknowledgement handling so timed-out subscribe and unsubscribe operations do not leave stale waiters or corrupt reconnect replay state.
- Added exponential reconnect backoff and tightened connection/session error handling for standalone connections, pub/sub sessions, and monitor sessions.
- Fixed pool disposal ordering and idle maintenance edge cases to avoid silent async failures and cleaner resource turnover.
- Tightened decoding and normalization paths for server replies, bit operations, and cluster routing errors.
- Reduced internal duplication and decode overhead in shared server helpers, cluster pipeline handling, and RESP frame processing.

### Docs

- Documented the current `replicaPreferred` coverage and clarified the binary-safe contract between raw `sendCommand()` and typed helper APIs.
- Refreshed changelog and examples to match the new cluster routing and observability features.

## 0.2.1

### Fixes

- Hardened pub/sub acknowledgement handling so timed-out subscribe and unsubscribe operations do not leave stale waiters or corrupt reconnect replay state.
- Added exponential reconnect backoff and tightened connection/session error handling for standalone connections, pub/sub sessions, and monitor sessions.
- Fixed pool disposal ordering and idle maintenance edge cases to avoid silent async failures and cleaner resource turnover.
- Tightened decoding and normalization paths for server replies, bit operations, and cluster routing errors.
- Reduced internal duplication and decode overhead in shared server helpers, cluster pipeline handling, and RESP frame processing.

### Improvements

- Lowered the minimum supported Dart SDK from `3.10.7` to `3.8.0` to widen package compatibility without changing the current API surface.
- Added replica-aware cluster read routing via `ClusterReadPreference.replicaPreferred` for a conservative whitelist of keyed read commands.
- Added `ClusterRouteObserver` / `ClusterRouteInfo` so applications can observe whether cluster commands were routed to primaries or replicas.
- Documented the current `replicaPreferred` coverage and clarified the binary-safe contract between raw `sendCommand()` and typed helper APIs.

## 0.2.0

### Breaking changes

- Made raw RESP bulk-string replies binary-safe by default, so low-level `sendCommand()` paths now preserve `Uint8List` payloads instead of eagerly decoding them as text.
- Narrowed command availability to the correct execution surface: dangerous operational commands remain admin-only, and connection-scoped commands such as `WAIT`, `WAITAOF`, `RESET`, `QUIT`, and standalone `SELECT` are exposed only on dedicated sessions.

### Improvements

- Expanded typed command helper coverage across core Redis command families, module commands, and session-specific workflows.
- Added explicit binary-safe helper variants for common string, hash, list, set, sorted-set, and stream read paths.
- Added dedicated `MONITOR` support and completed remaining helper coverage for command families that fit the current client/session model.

### Docs

- Removed the standalone command adaptation progress tracker in favor of documenting command access tiers directly in the README and API surface.

## 0.1.0

### Breaking changes

- Removed `DaredisCluster.clientPoolSize`. Cluster clients now use one slot-aware router with per-node pools, so `nodePoolSize` is the concurrency knob to configure.
- Changed pipeline execution to run on a single connection. On Redis Cluster, all keyed commands in one pipeline must now route to the same node.
- Made `RedisPubSub.close()` terminal. Closing a pub/sub session now completes its message stream and the same session cannot be reopened.
- Made `RedisTransaction` and `RedisClusterTransaction` single-use after `close()`. Open a fresh session with `openTransaction()` for the next transaction.

### Improvements

- Tightened low-level connection lifecycle handling around idempotent `connect()`, manual disconnect, and auth error propagation.

### Docs

- Refreshed README, examples, and package-level docs to match the updated client and session semantics.

## 0.0.5

- Extracted cluster command policy and redirect helpers into dedicated internal modules.
- Clarified native Redis Cluster multi-key rules in documentation and tests.

## 0.0.4

- Added slot-routed transactions for Redis Cluster via `openTransaction(String routingKey)`.
- Enforced single-slot validation for cluster transaction sessions.
- Fixed cluster test cleanup to avoid cross-slot multi-key deletes.

## 0.0.3

- Added a publish-friendly `example/example.dart` entry example.
- Expanded dartdoc coverage for public client, session, connection, and utility APIs.
- Aligned the README quick start with the published package example.

## 0.0.2

- Refined command capability modeling around concrete client and session types.
- Moved command helpers to mixin-based composition for standalone, cluster, and transaction clients.
- Improved integration tests and cluster test configuration coverage.

## 0.0.1

- Initial release with single-node/cluster clients and connection pooling.
