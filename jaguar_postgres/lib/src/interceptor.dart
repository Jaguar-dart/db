library jaguar_postgres.src.interceptor;

import 'dart:async';

import 'package:jaguar/jaguar.dart';
import 'package:postgres/postgres.dart';
import 'package:conn_pool/conn_pool.dart';

import 'pool.dart';

class PostgresPool {
  /// The connection pool
  final Pool<PostgreSQLConnection> pool;

  PostgresPool(String databaseName,
      {String host: 'localhost',
      int port: 5432,
      String username: 'postgres',
      String password,
      bool useSsl: false,
      int timeoutInSeconds: 30,
      String timeZone: "UTC",
      int minPoolSize: 10,
      int maxPoolSize: 10})
      : pool = SharedPool(
            PostgresManager(databaseName,
                host: host,
                port: port,
                username: username,
                password: password,
                useSsl: useSsl,
                timeoutInSeconds: timeoutInSeconds,
                timeZone: timeZone),
            minSize: minPoolSize,
            maxSize: maxPoolSize);

  PostgresPool.fromPool({this.pool});

  PostgresPool.fromManager({PostgresManager manager})
      : pool = SharedPool(manager);

  Future<PostgreSQLConnection> newInterceptor(Context ctx) async {
    Connection<PostgreSQLConnection> conn = await pool.get();
    ctx.addVariable(conn.connection);
    ctx.after.add((_) => _releaseConn(conn));
    ctx.onException.add((Context ctx, _1, _2) => _releaseConn(conn));
    return conn.connection;
  }

  /// Releases connection
  Future<void> _releaseConn(Connection<PostgreSQLConnection> conn) async {
    if (!conn.isReleased) await conn.release();
  }
}
