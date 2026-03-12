import 'package:daredis/daredis.dart';

Future<void> main() async {
  final client = Daredis(
    options: const ConnectionOptions(
      host: '127.0.0.1',
      port: 6379,
    ),
    poolSize: 4,
  );

  await client.connect();

  try {
    await client.set('example:user:1:name', 'alice');
    print(await client.get('example:user:1:name'));

    await client.hSet('example:user:1', 'city', 'shanghai');
    print(await client.hGetAll('example:user:1'));

    final pipeline = client.pipeline();
    pipeline.add(['SET', 'example:counter', '1']);
    pipeline.add(['INCR', 'example:counter']);
    pipeline.add(['GET', 'example:counter']);
    print(await pipeline.execute());
  } finally {
    await client.close();
  }
}
