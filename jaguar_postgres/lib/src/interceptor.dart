library jaguar_postgres.src.interceptor;

import 'dart:async';

import 'package:jaguar/jaguar.dart';
import 'package:postgres/postgres.dart';
import 'package:connection_pool/connection_pool.dart';

import 'pool.dart';

class PostgresDb extends Interceptor {
  /// ID for the interceptor instance
  final String id;

  final String host;

  final int port;

  final String databaseName;

  final String username;

  final String password;

  final bool useSSL;

  final int poolSize;

  /// The connection pool
  PostgresDbPool _pool;

  /// The connection
  ManagedConnection<PostgreSQLConnection> _managedConnection;

  /// Returns the mongodb connection
  PostgreSQLConnection get conn => _managedConnection?.conn;

  PostgresDb(this.host, this.port, this.databaseName,
      {this.username,
      this.password,
      this.useSSL: false,
      this.poolSize: 10,
      this.id});

  Future<PostgreSQLConnection> pre(Context ctx) async {
    _pool = new PostgresDbPool.Named(host, port, databaseName,
        username: username,
        password: password,
        useSSL: useSSL,
        poolSize: poolSize);
    _managedConnection = await _pool.getConnection();
    return conn;
  }

  /// Closes the connection on route exit
  Null post(Context ctx, Response incoming) {
    _releaseConn();
    return null;
  }

  /// Closes the connection in case an exception occurs in route chain before
  /// [post] is called
  Future<Null> onException() async {
    _releaseConn();
  }

  /// Releases connection
  void _releaseConn() {
    if (_managedConnection != null) {
      _pool.releaseConnection(_managedConnection);
      _managedConnection = null;
    }
  }
}
