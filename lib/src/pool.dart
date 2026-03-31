import 'dart:async';
import 'dart:collection';

import 'exceptions.dart';

typedef PoolFactory<T> = Future<T> Function();
typedef PoolDisposer<T> = Future<void> Function(T item);
typedef PoolValidator<T> = Future<bool> Function(T item);

/// Configuration for a generic resource pool.
class PoolConfig {
  /// Maximum number of managed resources.
  final int maxSize;

  /// Maximum number of idle resources kept in the pool.
  final int maxIdle;

  /// Minimum number of idle resources to keep warm.
  final int minIdle;

  /// Maximum number of waiters, or `null` for no limit.
  final int? maxWaiters;

  /// Default timeout while waiting to acquire a resource.
  final Duration? acquireTimeout;

  /// Idle timeout after which resources may be evicted.
  final Duration? idleTimeout;

  /// Interval for background eviction checks.
  final Duration? evictionInterval;

  /// Maximum number of idle items processed per eviction run.
  final int? evictionMaxItems;

  /// Maximum creation attempts, including the first try.
  final int createMaxAttempts;

  /// Delay between creation retries.
  final Duration createRetryDelay;

  /// Whether to validate items when borrowing them.
  final bool testOnBorrow;

  /// Whether to validate items when returning them.
  final bool testOnReturn;

  /// Whether idle items are validated during eviction.
  final bool testWhileIdle;

  /// Whether recently returned items are reused first.
  final bool useLifo;

  /// Creates pool configuration.
  PoolConfig({
    this.maxSize = 8,
    int? maxIdle,
    this.minIdle = 0,
    this.maxWaiters,
    this.acquireTimeout,
    this.idleTimeout,
    this.evictionInterval,
    this.evictionMaxItems,
    this.createMaxAttempts = 1,
    this.createRetryDelay = const Duration(milliseconds: 50),
    this.testOnBorrow = true,
    this.testOnReturn = false,
    this.testWhileIdle = true,
    this.useLifo = false,
  }) : maxIdle = maxIdle ?? maxSize,
       assert(maxSize > 0, 'maxSize must be > 0'),
       assert(minIdle >= 0, 'minIdle must be >= 0'),
       assert(createMaxAttempts > 0, 'createMaxAttempts must be > 0'),
       assert(
         evictionMaxItems == null || evictionMaxItems > 0,
         'evictionMaxItems must be > 0',
       ),
       assert(maxWaiters == null || maxWaiters >= 0, 'maxWaiters must be >= 0'),
       assert(
         acquireTimeout == null || !acquireTimeout.isNegative,
         'acquireTimeout must be >= 0',
       ),
       assert(
         idleTimeout == null || !idleTimeout.isNegative,
         'idleTimeout must be >= 0',
       ),
       assert(
         evictionInterval == null || !evictionInterval.isNegative,
         'evictionInterval must be >= 0',
       ),
       assert(
         !createRetryDelay.isNegative,
         'createRetryDelay must be >= 0',
       ) {
    assert(maxIdle == null || (this.maxIdle >= 0 && this.maxIdle <= maxSize),
        'maxIdle must be >= 0 and <= maxSize');
    assert(minIdle <= this.maxIdle, 'minIdle must be <= maxIdle');
  }
}

class _PoolWaiter<T> {
  final Completer<T> completer;
  Timer? timer;

  _PoolWaiter(this.completer);

  void complete(T item) {
    timer?.cancel();
    if (!completer.isCompleted) {
      completer.complete(item);
    }
  }

  void completeError(Object error, [StackTrace? stackTrace]) {
    timer?.cancel();
    if (!completer.isCompleted) {
      completer.completeError(error, stackTrace);
    }
  }
}

class _IdleItem<T> {
  final T item;
  final DateTime lastActive;

  _IdleItem(this.item) : lastActive = DateTime.now();
}

class Pool<T> {
  /// Effective pool configuration.
  final PoolConfig config;
  final PoolFactory<T> _create;
  final PoolDisposer<T>? _dispose;
  final PoolValidator<T>? _validate;

  final ListQueue<_IdleItem<T>> _idle = ListQueue();
  final ListQueue<_PoolWaiter<T>> _waiters = ListQueue();

  /// Number of items currently being created.
  int _creating = 0;

  /// Total managed items, including idle, in-use, and creating items.
  int _total = 0;
  bool _closed = false;
  Timer? _evictionTimer;
  bool _isServingWaiters = false;
  bool _isEnsuringMinIdle = false;
  DateTime? _lastEvictionAt;
  DateTime? _lastCreateFailureAt;
  int _createdCount = 0;
  int _disposedCount = 0;
  int _createFailureCount = 0;

  /// Snapshot of current pool metrics.
  PoolStats get stats => PoolStats(
    total: _total,
    idle: _idle.length,
    inUse: inUseCount,
    creating: _creating,
    waiters: _waiters.length,
    maxSize: config.maxSize,
    maxIdle: config.maxIdle,
    minIdle: config.minIdle,
    createdCount: _createdCount,
    disposedCount: _disposedCount,
    createFailureCount: _createFailureCount,
    lastEvictionAt: _lastEvictionAt,
    lastCreateFailureAt: _lastCreateFailureAt,
    isClosed: _closed,
  );

  Pool({
    required PoolFactory<T> create,
    PoolConfig? config,
    PoolDisposer<T>? dispose,
    PoolValidator<T>? validate,
  }) : _create = create,
       _dispose = dispose,
       _validate = validate,
       config = config ?? PoolConfig() {
    _startEvictionTimer();
    _scheduleMaintenance(_ensureMinIdle());
  }

  /// Whether the pool has been closed.
  bool get isClosed => _closed;

  /// Total number of managed items, including idle, in-use, and creating.
  int get totalCount => _total;

  /// Number of idle items currently available.
  int get idleCount => _idle.length;

  /// Number of items currently checked out.
  int get inUseCount => _total - _idle.length - _creating;

  /// Number of callers waiting in the acquire queue.
  int get waiterCount => _waiters.length;

  /// Acquires an item from the pool or creates one if capacity allows.
  Future<T> acquire({Duration? timeout}) async {
    if (_closed) {
      throw DaredisStateException('Pool is closed');
    }

    // 1. Try to reuse an idle item first.
    while (_idle.isNotEmpty) {
      final idleItem = _takeIdleItem();
      if (idleItem == null) {
        break;
      }
      if (_isIdleExpired(idleItem)) {
        await _disposeItem(idleItem.item);
        continue;
      }
      if (await _isValid(idleItem.item, config.testOnBorrow)) {
        return idleItem.item;
      }
      await _disposeItem(idleItem.item);
    }

    // 2. Create a new item if the pool has spare capacity.
    if (_total < config.maxSize) {
      return await _createNewItem();
    }

    // 3. Otherwise wait in the acquire queue.
    if (config.maxWaiters != null && _waiters.length >= config.maxWaiters!) {
      throw DaredisStateException('Pool wait queue is full');
    }

    final completer = Completer<T>();
    final waiter = _PoolWaiter<T>(completer);
    _waiters.add(waiter);

    final effectiveTimeout = timeout ?? config.acquireTimeout;
    if (effectiveTimeout != null) {
      waiter.timer = Timer(effectiveTimeout, () {
        if (_waiters.remove(waiter)) {
          waiter.completeError(
            DaredisTimeoutException('Pool acquire timed out'),
          );
        }
      });
    }

    return completer.future;
  }

  /// Returns a previously acquired item to the pool.
  Future<void> release(T item) async {
    if (_closed) {
      await _disposeItem(item);
      return;
    }

    if (!await _isValid(item, config.testOnReturn)) {
      await _disposeItem(item);
      _scheduleMaintenance(_serveWaiters()); // Backfill capacity for queued waiters.
      return;
    }

    // Hand the item directly to a waiter when one exists.
    if (_waiters.isNotEmpty) {
      if (await _isValid(item, config.testOnBorrow)) {
        _waiters.removeFirst().complete(item);
        return;
      }
      await _disposeItem(item);
      _scheduleMaintenance(_serveWaiters());
      return;
    }

    // Otherwise return the item to the idle queue.
    if (_idle.length < config.maxIdle) {
      // Idle timeout starts when the item is returned to the idle queue.
      _idle.addLast(_IdleItem(item));
      _scheduleMaintenance(_ensureMinIdle());
    } else {
      await _disposeItem(item);
    }
  }

  /// Runs [action] with an acquired item and always releases it afterwards.
  Future<R> withResource<R>(
    Future<R> Function(T item) action, {
    Duration? acquireTimeout,
  }) async {
    final item = await acquire(timeout: acquireTimeout);
    try {
      return await action(item);
    } finally {
      await release(item);
    }
  }

  /// Closes the pool and disposes all idle items.
  Future<void> close() async {
    _closed = true;
    _evictionTimer?.cancel();

    while (_waiters.isNotEmpty) {
      _waiters.removeFirst().completeError(
        DaredisStateException('Pool is closed'),
      );
    }

    final itemsToDispose = _idle.map((e) => e.item).toList();
    _idle.clear();

    for (final item in itemsToDispose) {
      await _disposeItem(item);
    }
    // In-use items are disposed later when their caller releases them.
  }

  Future<T> _createNewItem() async {
    _total++;
    _creating++;
    try {
      final item = await _createWithRetry();
      _creating--;
      _createdCount++;
      return item;
    } catch (e) {
      _total--;
      _creating--;
      rethrow;
    }
  }

  Future<void> _serveWaiters() async {
    if (_closed || _waiters.isEmpty || _isServingWaiters) return;

    _isServingWaiters = true;
    try {
      // Try to satisfy waiters from idle items first.
      while (_waiters.isNotEmpty && _idle.isNotEmpty) {
        final idleItem = _takeIdleItem();
        if (idleItem == null) {
          break;
        }
        if (_isIdleExpired(idleItem)) {
          await _disposeItem(idleItem.item);
          continue;
        }
        if (await _isValid(idleItem.item, config.testOnBorrow)) {
          _waiters.removeFirst().complete(idleItem.item);
        } else {
          await _disposeItem(idleItem.item);
        }
      }

      // Create new items for remaining waiters while capacity allows.
      while (_waiters.isNotEmpty && _total < config.maxSize) {
        try {
          final item = await _createNewItem();
          if (_waiters.isNotEmpty) {
            _waiters.removeFirst().complete(item);
          } else {
            await release(item);
          }
        } catch (e, stack) {
          if (_waiters.isNotEmpty) {
            _waiters.removeFirst().completeError(e, stack);
          }
        }
      }
    } finally {
      _isServingWaiters = false;
    }
  }

  Future<void> _disposeItem(T item) async {
    _total--;
    _disposedCount++;
    try {
      if (_dispose != null) {
        await _dispose(item);
      }
    } catch (_) {
      // Ignore disposal failures so pool shutdown and recycling can continue.
    }
  }

  Future<bool> _isValid(T item, bool enabled) async {
    if (!enabled || _validate == null) return true;
    try {
      return await _validate(item);
    } catch (_) {
      return false;
    }
  }

  bool _isIdleExpired(_IdleItem<T> idleItem) {
    if (config.idleTimeout == null) return false;
    final now = DateTime.now();
    return now.difference(idleItem.lastActive) > config.idleTimeout!;
  }

  _IdleItem<T>? _takeIdleItem() {
    if (_idle.isEmpty) {
      return null;
    }
    return config.useLifo ? _idle.removeLast() : _idle.removeFirst();
  }

  Future<T> _createWithRetry() async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (var attempt = 0; attempt < config.createMaxAttempts; attempt++) {
      try {
        return await _create();
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        _lastCreateFailureAt = DateTime.now();
        _createFailureCount++;
        final hasMoreAttempts = attempt + 1 < config.createMaxAttempts;
        if (hasMoreAttempts) {
          await Future.delayed(config.createRetryDelay);
        }
      }
    }

    Error.throwWithStackTrace(
      lastError ?? DaredisConnectionException('Pool create failed'),
      lastStackTrace ?? StackTrace.current,
    );
  }

  Future<void> _ensureMinIdle() async {
    if (_isEnsuringMinIdle ||
        _closed ||
        _total >= config.maxSize ||
        _idle.length >= config.minIdle) {
      return;
    }

    _isEnsuringMinIdle = true;
    try {
      while (_total < config.maxSize && _idle.length < config.minIdle) {
        try {
          final item = await _createNewItem();
          _idle.addLast(_IdleItem(item));
        } catch (_) {
          break; // Stop warming when item creation keeps failing.
        }
      }
    } finally {
      _isEnsuringMinIdle = false;
    }
  }

  void _startEvictionTimer() {
    if (config.evictionInterval == null) return;

    _evictionTimer = Timer.periodic(config.evictionInterval!, (_) {
      _scheduleMaintenance(_runEvictionCycle());
    });
  }

  Future<void> _runEvictionCycle() async {
      if (_closed) return;

      final now = DateTime.now();
      _lastEvictionAt = now;
      final toRemove = <_IdleItem<T>>[];
      final maxItems = config.evictionMaxItems ?? _idle.length;
      final itemsToInspect = _idle.take(maxItems).toList();

      for (final idleItem in itemsToInspect) {
        // 1. Evict expired items.
        if (config.idleTimeout != null) {
          if (now.difference(idleItem.lastActive) > config.idleTimeout!) {
            toRemove.add(idleItem);
            continue;
          }
        }

        // 2. Validate remaining idle items when configured.
        if (config.testWhileIdle && _validate != null) {
          if (!await _isValid(idleItem.item, true)) {
            toRemove.add(idleItem);
          }
        }
      }

      for (final idleItem in toRemove) {
        if (_idle.remove(idleItem)) {
          await _disposeItem(idleItem.item);
        }
      }

      await _ensureMinIdle();
      await _serveWaiters();
  }

  void _scheduleMaintenance(Future<void> future) {
    unawaited(
      future.catchError((Object error, StackTrace stackTrace) {
        Zone.current.handleUncaughtError(error, stackTrace);
        return null;
      }),
    );
  }
}

/// Snapshot of pool counters and recent maintenance timestamps.
class PoolStats {
  /// Total managed items.
  final int total;

  /// Idle items currently available.
  final int idle;

  /// Items currently checked out.
  final int inUse;

  /// Items in the middle of asynchronous creation.
  final int creating;

  /// Callers currently waiting to acquire an item.
  final int waiters;

  /// Configured maximum number of managed items.
  final int maxSize;

  /// Configured maximum idle items.
  final int maxIdle;

  /// Configured minimum idle items.
  final int minIdle;

  /// Total number of successfully created items.
  final int createdCount;

  /// Total number of disposed items.
  final int disposedCount;

  /// Total number of failed item creation attempts.
  final int createFailureCount;

  /// Timestamp of the most recent eviction run, if any.
  final DateTime? lastEvictionAt;

  /// Timestamp of the most recent creation failure, if any.
  final DateTime? lastCreateFailureAt;

  /// Whether the pool has been closed.
  final bool isClosed;

  const PoolStats({
    required this.total,
    required this.idle,
    required this.inUse,
    required this.creating,
    required this.waiters,
    required this.maxSize,
    required this.maxIdle,
    required this.minIdle,
    required this.createdCount,
    required this.disposedCount,
    required this.createFailureCount,
    required this.lastEvictionAt,
    required this.lastCreateFailureAt,
    required this.isClosed,
  });

  @override
  String toString() =>
      'PoolStats(total: $total, idle: $idle, inUse: $inUse, creating: $creating, waiters: $waiters, maxSize: $maxSize, maxIdle: $maxIdle, minIdle: $minIdle, createdCount: $createdCount, disposedCount: $disposedCount, createFailureCount: $createFailureCount, lastEvictionAt: $lastEvictionAt, lastCreateFailureAt: $lastCreateFailureAt, isClosed: $isClosed)';
}
