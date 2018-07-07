import 'dart:async';
import 'counted_set.dart';

class SharedPool<T> implements Pool<T> {
  final ConnectionManager<T> manager;

  final int minSize;
  final int maxSize;
  final _pool = CountedSet<Connection<T>>();

  SharedPool(this.manager, {int minSize: 10, int maxSize: 10})
      : minSize = minSize,
        maxSize = maxSize,
        _d = maxSize - minSize;

  Future<Connection<T>> _createNew() async {
    var conn = Connection._(this);
    _pool.add(1, conn);
    T n = await manager.open();
    conn._connection = n;
    return conn;
  }

  Future<Connection<T>> get() async {
    if (_pool.numAt(0) > 0 || _pool.length >= maxSize) {
      var conn = _pool.leastUsed;
      _pool.inc(conn);
      return conn;
    }
    return _createNew();
  }

  final int _d;

  void release(Connection<T> conn) {
    int count = _pool.countOf(conn);
    if (count == null || count == 0) return;
    _pool.dec(conn);
    if (_pool.length != maxSize) return;
    if (_pool.numAt(0) < _d) return;
    var removes = _pool.removeAllAt(0);
    for (var r in removes) {
      try {
        if (r.isReleased) continue;
        r.isReleased = true;
        manager.close(r.connection);
      } catch (_) {}
    }
  }
}

class Connection<T> {
  /// The connection pool this connection belongs to.
  final Pool<T> pool;

  /// The underlying connection
  T _connection;

  bool isReleased = false;

  Connection._(this.pool);

  T get connection => _connection;

  Future<void> release() => pool.release(this);
}

/// Interface to open and close the connection [C]
abstract class ConnectionManager<C> {
  /// Establishes and returns a new connection
  Future<C> open();

  /// Closes provided[connection]
  void close(C connection);
}

abstract class Pool<T> {
  ConnectionManager<T> get manager;

  Future<Connection<T>> get();

  FutureOr<void> release(Connection<T> connection);
}

// TODO class ExclusivePool<T> implements Pool<T> {}
