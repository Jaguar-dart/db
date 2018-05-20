import 'dart:async';

import 'package:connection_pool/connection_pool.dart';
import 'package:postgres/postgres.dart';

class PostgresDbPool extends ConnectionPool<PostgreSQLConnection> {
  String host;

  int port;

  String databaseName;

  String username;

  String password;

  bool useSsl;

  PostgresDbPool(this.host, this.port, this.databaseName,
      {this.username, this.password, this.useSsl: false, int poolSize: 10})
      : super(poolSize);

  @override
  void closeConnection(PostgreSQLConnection connection) {
    connection.close();
  }

  @override
  Future<PostgreSQLConnection> openNewConnection() async {
    PostgreSQLConnection conn = new PostgreSQLConnection(
        host, port, databaseName,
        username: username, password: password, useSSL: useSsl);
    await conn.open();
    return conn;
  }

  /// Collection of named pools
  static Map<String, PostgresDbPool> _pools = {};

  /// Creates a named pool or returns an existing one if the pool with given
  /// name already exists
  factory PostgresDbPool.Named(String host, int port, String databaseName,
      {String username,
      String password,
      bool useSSL: false,
      int poolSize: 10}) {
    final String name =
        '$username:$password@$host:$port/$databaseName/$poolSize/$useSSL';
    if (_pools[name] == null) {
      _pools[name] = new PostgresDbPool(host, port, databaseName,
          username: username,
          password: password,
          useSsl: useSSL,
          poolSize: poolSize);
    }

    return _pools[name];
  }
}
