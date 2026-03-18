# Daredis

`Daredis` is a Redis client for Dart with:

- single-node and cluster clients
- connection pooling
- dedicated Pub/Sub sessions
- dedicated transaction sessions
- typed command helpers on top of raw Redis replies

It is designed around a simple rule:

- normal commands use pooled connections
- Pub/Sub uses a dedicated connection
- transactions use a dedicated connection
- cluster commands route to the correct node and use per-node pools

## Features

- Single-node Redis client: `Daredis`
- Redis Cluster client: `DaredisCluster`
- Connection pooling with timeouts, idle eviction, retry, and stats
- Dedicated Pub/Sub session API with reconnect support
- Dedicated transaction session API for single-node Redis
- Pipeline support
- Typed helper APIs for `COMMAND`, `FUNCTION`, `XINFO`, `ROLE`, and more
- Raw `sendCommand()` escape hatch when you need low-level access
- TLS/SSL, AUTH, and ACL-friendly connection options
- RESP decoding with Redis error mapping to custom exceptions

## Installation

Add `daredis` to your `pubspec.yaml`:

```yaml
dependencies:
  daredis: ^0.0.2
```

Then run:

```bash
dart pub get
```

## Examples

Ready-to-run examples live in:

- `example/single_node.dart`
- `example/cluster.dart`
- `example/sessions.dart`

Run one with:

```bash
dart run example/single_node.dart
```

## Quick Start

### Single Node

```dart
import 'package:daredis/daredis.dart';

Future<void> main() async {
  final client = Daredis(
    options: const ConnectionOptions(
      host: '127.0.0.1',
      port: 6379,
    ),
  );

  await client.connect();

  try {
    const key = 'example:greeting';

    await client.set(key, 'hello from daredis');
    final value = await client.get(key);

    print('Stored value: $value');

    await client.hSet('example:user:1', 'name', 'alice');
    await client.hSet('example:user:1', 'city', 'shanghai');
    final user = await client.hGetAll('example:user:1');

    print('User hash: $user');
  } finally {
    await client.close();
  }
}
```

### Cluster

Use hash tags when multiple keys must stay in the same slot.

```dart
import 'package:daredis/daredis.dart';

Future<void> main() async {
  final cluster = DaredisCluster(
    clientPoolSize: 4,
    options: ClusterOptions(
      seeds: const [
        ClusterNode('127.0.0.1', 7000),
        ClusterNode('127.0.0.1', 7001),
      ],
      nodePoolSize: 8,
    ),
  );

  await cluster.connect();

  await cluster.set('cart:{42}:total', '199');
  print(await cluster.get('cart:{42}:total'));

  await cluster.close();
}
```

## Client Model

The library uses different connection strategies for different workloads.

```text
Daredis
  -> Pool<Connection>

DaredisCluster
  -> Pool<_DaredisClusterConnection>
     -> per-node Pool<Connection>

openPubSub()
  -> dedicated Connection

openTransaction()
  -> dedicated Connection
```

Why this matters:

- ordinary commands can safely share pooled connections
- Pub/Sub cannot share a normal command connection once subscribed
- `WATCH/MULTI/EXEC` must stay on the same connection
- cluster routing needs an extra layer that maps keys to nodes

### Command Surface Design

The package models command availability through concrete client/session types.

- `Daredis` exposes the normal command groups for pooled single-node access
- `DaredisCluster` exposes the normal command groups plus cluster-only helpers
- `RedisTransaction` exposes transaction commands like `WATCH`, `MULTI`, and `EXEC`

This keeps command availability aligned with the underlying connection model
instead of exposing every command on every executor shape.

## Connection Options

```dart
final options = ConnectionOptions(
  host: '127.0.0.1',
  port: 6379,
  username: 'default',
  password: 'secret',
  useSsl: false,
  connectTimeout: const Duration(seconds: 5),
  commandTimeout: const Duration(seconds: 30),
  reconnectPolicy: const ReconnectPolicy(
    maxAttempts: 5,
    delay: Duration(seconds: 2),
  ),
);
```

## Single-Node Usage

### Basic Commands

```dart
await client.set('key', 'value');
print(await client.get('key'));

await client.hSet('user:1', 'name', 'alice');
print(await client.hGetAll('user:1'));

await client.rPush('jobs', ['a', 'b']);
print(await client.lRange('jobs', 0, -1));

await client.sAdd('tags', ['dart', 'redis']);
print(await client.sMembers('tags'));
```

### Pipeline

Use a pipeline when you want to batch commands and collect results together.

```dart
final pipeline = client.pipeline();
pipeline.add(['SET', 'key1', 'v1']);
pipeline.add(['GET', 'key1']);
pipeline.add(['INCR', 'counter']);

final results = await pipeline.execute();
print(results);
```

### Transactions

Transactions are exposed as a dedicated session because `WATCH`, `MULTI`, and
`EXEC` must run on the same connection.

Those transactional commands are intentionally exposed on `RedisTransaction`,
not on the pooled `Daredis` client itself.

```dart
final tx = await client.openTransaction();
try {
  await tx.watch(['account:1']);
  await tx.multi();
  await tx.set('account:1', 'updated');
  final replies = await tx.exec();
  print(replies);
} finally {
  await tx.close();
}
```

`DaredisCluster` intentionally does not support transactions. If you need
`WATCH/MULTI/EXEC`, use a direct `Daredis` client against a single Redis node.

### Pub/Sub

Pub/Sub also uses a dedicated connection.

```dart
final pubsub = await client.openPubSub();

await pubsub.subscribe(['news']);

final sub = pubsub.dataMessages.listen((message) {
  print('channel=${message.channel} payload=${message.payload}');
});

await client.sendCommand(['PUBLISH', 'news', 'hello world']);

await sub.cancel();
await pubsub.close();
```

You can also consume messages in a pull style:

```dart
final message = await pubsub.getMessage(
  timeout: const Duration(seconds: 1),
  ignoreSubscriptionMessages: true,
);
```

## Cluster Usage

### Same-Slot Multi-Key Operations

Redis Cluster requires multi-key commands to stay in one slot. Use hash tags:

```dart
await cluster.mSet({
  'profile:{7}:name': 'alice',
  'profile:{7}:city': 'shanghai',
});

final values = await cluster.mGet([
  'profile:{7}:name',
  'profile:{7}:city',
]);

print(values); // [alice, shanghai]
```

### Cluster Metadata

```dart
final info = await cluster.clusterInfo();
print(info['cluster_state']);

final slot = await cluster.clusterKeyslot('profile:{7}:name');
print(slot);

final ranges = await cluster.clusterSlotRanges();
print(ranges.first.primary);
```

## Pool Configuration

`Daredis` uses a pool of `Connection` objects for normal commands.

```dart
final client = Daredis(
  options: const ConnectionOptions(host: '127.0.0.1', port: 6379),
  poolSize: 10,
  testOnBorrow: true,
  testOnReturn: false,
  maxWaiters: 500,
  acquireTimeout: const Duration(seconds: 5),
  idleTimeout: const Duration(seconds: 30),
  evictionInterval: const Duration(seconds: 10),
  createMaxAttempts: 3,
  createRetryDelay: const Duration(milliseconds: 100),
  useLifo: true,
);
```

### Pool Stats

```dart
final stats = client.poolStats;

print(stats.total);
print(stats.idle);
print(stats.inUse);
print(stats.creating);
print(stats.waiters);
print(stats.createdCount);
print(stats.disposedCount);
print(stats.createFailureCount);
print(stats.lastEvictionAt);
print(stats.lastCreateFailureAt);
```

Recommended production-style defaults:

- `idleTimeout: 30s`
- `evictionInterval: 10s`
- `createMaxAttempts: 3`
- `createRetryDelay: 100ms`
- `useLifo: true` if you want to prefer hot connection reuse
- set `maxWaiters` explicitly for latency-sensitive services

## Cluster Pool Configuration

Cluster uses two levels of pooling:

- `clientPoolSize`: top-level cluster routing clients
- `nodePoolSize`: per-node Redis connection pools

```dart
final cluster = DaredisCluster(
  clientPoolSize: 4,
  options: ClusterOptions(
    seeds: const [
      ClusterNode('127.0.0.1', 7000),
      ClusterNode('127.0.0.1', 7001),
    ],
    nodePoolSize: 8,
    poolMaxWaiters: 500,
    poolAcquireTimeout: const Duration(seconds: 5),
    poolIdleTimeout: const Duration(seconds: 30),
    poolEvictionInterval: const Duration(seconds: 10),
    poolCreateMaxAttempts: 3,
    poolCreateRetryDelay: const Duration(milliseconds: 100),
    poolUseLifo: true,
  ),
);
```

## Typed Helper APIs

`sendCommand()` is still available as a low-level escape hatch, but for most
application code the typed helpers are easier to read and maintain.

### Command Metadata

```dart
final docs = await client.commandDocEntriesFor(['SET']);
print(docs.first.name);
print(docs.first.summary);
print(docs.first.arguments.first.name);

final info = await client.commandInfoEntriesFor(['GET']);
print(info.first.name);
print(info.first.flags);
print(info.first.categories);
print(info.first.firstKey);
```

### Stream Metadata

```dart
final streamInfo = await client.xInfoStreamEntry('orders');
print(streamInfo.length);

final groups = await client.xInfoGroupEntries('orders');
for (final group in groups) {
  print('${group.name} pending=${group.pending}');
}

final consumers = await client.xInfoConsumerEntries('orders', 'group-a');
for (final consumer in consumers) {
  print('${consumer.name} idle=${consumer.idle}');
}
```

### Functions

```dart
final libraries = await client.functionLibraryEntries();
for (final library in libraries) {
  print(library.libraryName);
  for (final function in library.functions) {
    print(function.name);
  }
}

final stats = await client.functionStatsEntry();
print(stats.runningScript?.functionName);
print(stats.engines['LUA']?.librariesCount);
print(stats.engines['LUA']?.functionsCount);
```

### Role

```dart
final role = await client.roleInfo();
print(role.role);

if (role.role == 'master') {
  print(role.replicas.length);
}
```

## Scripting Helpers

Raw script commands are available:

- `eval(...)`
- `evalRo(...)`
- `evalSha(...)`
- `evalShaRo(...)`

There are also typed convenience helpers for common result shapes:

- `evalString(...)`
- `evalInt(...)`
- `evalListString(...)`
- `evalRoString(...)`
- `evalRoInt(...)`
- `evalRoListString(...)`
- `evalShaString(...)`
- `evalShaInt(...)`
- `evalShaListString(...)`
- `evalShaRoString(...)`
- `evalShaRoInt(...)`
- `evalShaRoListString(...)`

Example:

```dart
final sha = await client.scriptLoad("return redis.call('GET', KEYS[1])");

final value = await client.evalShaString(
  sha,
  1,
  ['user:1:name'],
  const [],
);

print(value);
```

## TLS / SSL

```dart
final client = Daredis(
  options: const ConnectionOptions(
    host: 'your-redis-server',
    port: 6380,
    useSsl: true,
  ),
);
```

## Exceptions

The library maps Redis and client failures to custom exception types:

- `DaredisConnectionException`
- `DaredisTimeoutException`
- `DaredisNetworkException`
- `DaredisCommandException`
- `DaredisClusterException`
- `DaredisStateException`
- `DaredisArgumentException`
- `DaredisUnsupportedException`
- `DaredisProtocolException`

Example:

```dart
try {
  await client.set('key', 'value');
} on DaredisCommandException catch (e) {
  print(e);
}
```

## Low-Level Escape Hatch

If you need a Redis command that does not yet have a high-level helper, use
`sendCommand()`:

```dart
final reply = await client.sendCommand(['PING']);
print(reply);
```

This is intentionally kept available, but for readability and long-term
maintainability it is better to prefer the typed helpers when they exist.

## Supported High-Level Areas

The library already includes helpers for:

- strings
- keys
- lists
- hashes
- sets
- sorted sets
- streams
- server and command metadata
- scripting
- geo
- hyperloglog
- cluster metadata and routing helpers

## Testing

The project includes:

- unit tests for pool, cluster routing, redirect handling, and Pub/Sub helpers
- integration tests for single-node Redis
- integration tests for Redis Cluster

Typical commands:

```bash
dart analyze
dart test
```

## License

This project is licensed under the MIT License. See
`LICENSE`.

## Current Design Notes

- `Daredis` is the top-level single-node client
- `DaredisCluster` is the top-level cluster client
- normal commands use pooled connections
- Pub/Sub and transactions use dedicated connections
- cluster transactions are intentionally unsupported

This keeps the API honest and avoids hiding Redis connection semantics behind
an unsafe abstraction.
