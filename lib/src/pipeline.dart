import 'exceptions.dart';

/// Simple client-side pipeline that batches commands and awaits all results.
class RedisPipeline {
  final Future<dynamic> Function(List<dynamic> command, Duration? timeout)
  _sender;
  final List<PipelineItem> _items = [];
  bool _executed = false;

  /// Creates a pipeline that sends commands through [_sender].
  RedisPipeline(this._sender);

  /// Adds [command] to the pipeline.
  void add(List<dynamic> command, {Duration? timeout}) {
    if (_executed) {
      throw DaredisStateException('Pipeline already executed');
    }
    _items.add(PipelineItem(command, timeout));
  }

  /// Executes all queued commands and returns their replies in order.
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

  /// Returns the queued pipeline items.
  List<PipelineItem> get items => List.unmodifiable(_items);
}

/// One queued command in a pipeline.
class PipelineItem {
  /// Raw Redis command arguments.
  final List<dynamic> command;

  /// Optional per-command timeout.
  final Duration? timeout;

  /// Creates a queued pipeline item.
  PipelineItem(this.command, this.timeout);
}
