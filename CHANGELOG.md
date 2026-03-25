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

- Added slot-routed Redis Cluster transactions via `openTransaction(String routingKey)`.
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
