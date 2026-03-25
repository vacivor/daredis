import 'exceptions.dart';

/// Batches commands on a single connection and awaits all results in order.
class RedisPipeline {
  final Future<List<dynamic>> Function(List<PipelineItem> items) _sender;
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
    final batch = _sender(List<PipelineItem>.unmodifiable(_items));
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
