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
    final pubsub = await client.openPubSub();
    await pubsub.subscribe(['example:news']);

    final sub = pubsub.dataMessages.listen((message) {
      print('pubsub: ${message.channel} -> ${message.payload}');
    });

    await client.sendCommand(['PUBLISH', 'example:news', 'hello']);

    final tx = await client.openTransaction();
    try {
      await tx.watch(['example:tx:key']);
      await tx.multi();
      await tx.set('example:tx:key', 'updated');
      print(await tx.exec());
    } finally {
      await tx.close();
    }

    await sub.cancel();
    await pubsub.close();
  } finally {
    await client.close();
  }
}
