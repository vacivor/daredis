import 'package:daredis/daredis.dart';

Future<void> main() async {
  final cluster = DaredisCluster(
    options: ClusterOptions(
      seeds: const [
        ClusterNode('127.0.0.1', 7000),
      ],
      nodePoolSize: 8,
    ),
  );

  await cluster.connect();

  try {
    await cluster.mSet({
      'example:user:{42}:name': 'alice',
      'example:user:{42}:city': 'shanghai',
    });

    final values = await cluster.mGet([
      'example:user:{42}:name',
      'example:user:{42}:city',
    ]);
    print(values);

    final slot = await cluster.clusterKeyslot('example:user:{42}:name');
    print('slot=$slot');
  } finally {
    await cluster.close();
  }
}
