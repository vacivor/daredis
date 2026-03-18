import 'package:daredis/daredis.dart';

/// Minimal standalone example for a local Redis server.
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
