import 'exceptions.dart';

class RedisPipeline {
  final Future<dynamic> Function(List<dynamic> command, Duration? timeout)
  _sender;
  final List<PipelineItem> _items = [];
  bool _executed = false;

  RedisPipeline(this._sender);

  void add(List<dynamic> command, {Duration? timeout}) {
    if (_executed) {
      throw DaredisStateException('Pipeline already executed');
    }
    _items.add(PipelineItem(command, timeout));
  }

  Future<List<dynamic>> execute({Duration? timeout}) async {
    if (_executed) {
      throw DaredisStateException('Pipeline already executed');
    }
    _executed = true;
    final futures = _items.map((item) => _sender(item.command, item.timeout));
    final batch = Future.wait(futures);
    if (timeout == null) {
      return await batch;
    }
    return await batch.timeout(
      timeout,
      onTimeout: () => throw DaredisTimeoutException('Pipeline timed out'),
    );
  }

  List<PipelineItem> get items => List.unmodifiable(_items);
}

class PipelineItem {
  final List<dynamic> command;
  final Duration? timeout;

  PipelineItem(this.command, this.timeout);
}
