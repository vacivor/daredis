# Daredis

A Redis client for Dart with connection pooling, cluster support, and a pub/sub session API.

## Features

- Single node and cluster clients
- Connection pool with health checks and stats
- Pub/Sub sessions with auto-reconnect
- Redis command helpers with typed decoders
- RESP2/RESP3 decoding support
- Pipeline support
- SSL/TLS and Auth support

## Usage

### Single node

```dart
import 'package:daredis/daredis.dart';

void main() async {
  final client = Daredis(
    options: ConnectionOptions(
      host: '127.0.0.1', 
      port: 6379,
      // password: 'your_password', // Optional
    ),
    poolSize: 4,
  );

  await client.connect();
  
  // String commands
  await client.set('key', 'value');
  final value = await client.get('key');
  print(value); // value

  // List commands
  await client.rpush('list', ['item1', 'item2']);
  final list = await client.lrange('list', 0, -1);
  print(list); // [item1, item2]

  await client.close();
}
```

### Cluster

```dart
import 'package:daredis/daredis.dart';

void main() async {
  final cluster = DaredisCluster(
    options: ClusterOptions(
      seeds: [
        ClusterNode('127.0.0.1', 7000),
        ClusterNode('127.0.0.1', 7001),
      ],
      // connectionOptions: ConnectionOptions(password: 'pass'), // Optional
    ),
  );

  await cluster.connect();
  
  // Use hashtag for cluster slots
  await cluster.set('key:{tag}', 'value');
  print(await cluster.get('key:{tag}'));
  
  await cluster.close();
}
```

### Pipeline

Pipelines allow you to send multiple commands to the server without waiting for the replies, and then read the replies in a single step.

```dart
final pipeline = client.pipeline();
pipeline.add(['SET', 'key1', 'v1']);
pipeline.add(['GET', 'key1']);
pipeline.add(['INCR', 'counter']);

final results = await pipeline.execute();
print(results); // [OK, v1, 1]
```

### Pub/Sub

```dart
import 'package:daredis/daredis.dart';

void main() async {
  final client = Daredis(
    options: ConnectionOptions(host: '127.0.0.1', port: 6379),
  );
  await client.connect();

  final pubsub = await client.openPubSub();
  
  pubsub.dataMessages.listen((msg) {
    print('channel=${msg.channel} payload=${msg.payload}');
  });

  await pubsub.subscribe(['news']);
  
  // In another connection or client
  await client.publish('news', 'hello world');
  
  // To close
  // await pubsub.close();
}
```

### Reconnect policy

```dart
final client = Daredis(
  options: ConnectionOptions(
    host: '127.0.0.1',
    port: 6379,
    reconnectPolicy: const ReconnectPolicy(
      maxAttempts: 5,
      delay: Duration(seconds: 2),
    ),
  ),
);
```

### Pool configuration & stats

```dart
final client = Daredis(
  poolSize: 10,
  testOnBorrow: true, // Check connection health before use
  acquireTimeout: Duration(seconds: 5),
);

final stats = client.poolStats;
print('Total: ${stats.total}');
print('Idle: ${stats.idle}');
print('In use: ${stats.inUse}');
print('Waiters: ${stats.waiters}');
```

### SSL/TLS

```dart
final client = Daredis(
  options: ConnectionOptions(
    host: 'your-redis-server',
    port: 6380,
    useSsl: true,
  ),
);
```
