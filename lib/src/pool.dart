import 'dart:async';
import 'dart:collection';

import 'exceptions.dart';

typedef PoolFactory<T> = Future<T> Function();
typedef PoolDisposer<T> = Future<void> Function(T item);
typedef PoolValidator<T> = Future<bool> Function(T item);

/// 连接池配置，参考 Jedis 的配置项
class PoolConfig {
  /// 连接池允许的最大连接数
  final int maxSize;

  /// 最大空闲连接数（默认等于 maxSize）
  final int maxIdle;

  /// 最小空闲连接数
  final int minIdle;

  /// 最大等待队列长度，null 表示不限制
  final int? maxWaiters;

  /// 获取连接时的默认超时时间
  final Duration? acquireTimeout;

  /// 空闲连接的超时时间，超过此时间可能会被回收
  final Duration? idleTimeout;

  /// 后台清理任务运行的时间间隔
  final Duration? evictionInterval;

  /// 借用连接时是否进行有效性检查
  final bool testOnBorrow;

  /// 归还连接时是否进行有效性检查
  final bool testOnReturn;

  /// 是否开启空闲检查
  final bool testWhileIdle;

  PoolConfig({
    this.maxSize = 8,
    int? maxIdle,
    this.minIdle = 0,
    this.maxWaiters,
    this.acquireTimeout,
    this.idleTimeout,
    this.evictionInterval,
    this.testOnBorrow = true,
    this.testOnReturn = false,
    this.testWhileIdle = true,
  }) : maxIdle = maxIdle ?? maxSize,
       assert(maxSize > 0, 'maxSize must be > 0'),
       assert(minIdle >= 0, 'minIdle must be >= 0'),
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
  final PoolConfig config;
  final PoolFactory<T> _create;
  final PoolDisposer<T>? _dispose;
  final PoolValidator<T>? _validate;

  final ListQueue<_IdleItem<T>> _idle = ListQueue();
  final ListQueue<_PoolWaiter<T>> _waiters = ListQueue();

  /// 记录当前正在创建的连接数量，防止超过 maxSize
  int _creating = 0;

  /// 已经创建并管理的连接总数（包括 idle 和 inUse 以及正在创建中的）
  int _total = 0;
  bool _closed = false;
  Timer? _evictionTimer;

  /// 连接池统计信息
  PoolStats get stats => PoolStats(
    total: _total,
    idle: _idle.length,
    inUse: inUseCount,
    waiters: _waiters.length,
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
    _ensureMinIdle();
  }

  bool get isClosed => _closed;

  int get totalCount => _total;

  int get idleCount => _idle.length;

  int get inUseCount => _total - _idle.length - _creating;

  int get waiterCount => _waiters.length;

  /// 获取一个资源
  Future<T> acquire({Duration? timeout}) async {
    if (_closed) {
      throw DaredisStateException('Pool is closed');
    }

    // 1. 尝试从空闲队列获取
    while (_idle.isNotEmpty) {
      final idleItem = _idle.removeFirst();
      if (await _isValid(idleItem.item, config.testOnBorrow)) {
        return idleItem.item;
      }
      _disposeItem(idleItem.item); // 不等待销毁，继续尝试
    }

    // 2. 尝试创建新连接
    if (_total < config.maxSize) {
      return await _createNewItem();
    }

    // 3. 队列已满，进入等待
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

  /// 归还资源
  Future<void> release(T item) async {
    if (_closed) {
      _disposeItem(item);
      return;
    }

    if (!await _isValid(item, config.testOnReturn)) {
      _disposeItem(item);
      _serveWaiters(); // 补位
      return;
    }

    // 如果有等待者，直接交给等待者
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete(item);
      return;
    }

    // 否则放入空闲队列
    if (_idle.length < config.maxIdle) {
      _idle.addLast(_IdleItem(item));
      _ensureMinIdle();
    } else {
      _disposeItem(item);
    }
  }

  /// 在资源池中执行操作，并确保资源归还
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

  /// 关闭连接池
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
      _disposeItem(item);
    }
    // 注意：正在使用的连接由使用者在使用完 release 时发现 pool 已关闭而销毁
  }

  Future<T> _createNewItem() async {
    _total++;
    _creating++;
    try {
      final item = await _create();
      _creating--;
      return item;
    } catch (e) {
      _total--;
      _creating--;
      rethrow;
    }
  }

  void _serveWaiters() async {
    if (_closed || _waiters.isEmpty) return;

    // 尝试用空闲资源满足等待者
    while (_waiters.isNotEmpty && _idle.isNotEmpty) {
      final idleItem = _idle.removeFirst();
      if (await _isValid(idleItem.item, config.testOnBorrow)) {
        _waiters.removeFirst().complete(idleItem.item);
      } else {
        _disposeItem(idleItem.item);
      }
    }

    // 如果还有等待者且没到上限，创建新资源
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
  }

  Future<void> _disposeItem(T item) async {
    _total--;
    try {
      if (_dispose != null) {
        await _dispose(item);
      }
    } catch (_) {
      // 忽略销毁异常，避免影响连接池主流程
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

  void _ensureMinIdle() async {
    if (_closed || _total >= config.maxSize || _idle.length >= config.minIdle)
      return;

    while (_total < config.maxSize && _idle.length < config.minIdle) {
      try {
        final item = await _createNewItem();
        _idle.addLast(_IdleItem(item));
      } catch (_) {
        break; // 创建失败则停止补足
      }
    }
  }

  void _startEvictionTimer() {
    if (config.evictionInterval == null) return;

    _evictionTimer = Timer.periodic(config.evictionInterval!, (_) async {
      if (_closed) return;

      final now = DateTime.now();
      final toRemove = <_IdleItem<T>>[];

      for (final idleItem in _idle) {
        // 1. 检查超时
        if (config.idleTimeout != null) {
          if (now.difference(idleItem.lastActive) > config.idleTimeout!) {
            toRemove.add(idleItem);
            continue;
          }
        }

        // 2. 检查有效性
        if (config.testWhileIdle && _validate != null) {
          if (!await _isValid(idleItem.item, true)) {
            toRemove.add(idleItem);
          }
        }
      }

      for (final idleItem in toRemove) {
        if (_idle.remove(idleItem)) {
          _disposeItem(idleItem.item);
        }
      }

      _ensureMinIdle();
      _serveWaiters();
    });
  }
}

/// 连接池统计信息
class PoolStats {
  final int total;
  final int idle;
  final int inUse;
  final int waiters;
  final bool isClosed;

  const PoolStats({
    required this.total,
    required this.idle,
    required this.inUse,
    required this.waiters,
    required this.isClosed,
  });

  @override
  String toString() =>
      'PoolStats(total: $total, idle: $idle, inUse: $inUse, waiters: $waiters, isClosed: $isClosed)';
}
