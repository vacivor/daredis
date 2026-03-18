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
    await client.set('example:key', 'hello');
    print(await client.get('example:key'));
  } finally {
    await client.close();
  }
}
