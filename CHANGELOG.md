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
