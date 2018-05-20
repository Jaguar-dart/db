import 'dart:async';

import 'package:connection_pool/connection_pool.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

/// Mongodb pool implementation
class MongoDbPool extends ConnectionPool<mongo.Db> {
  /// URI of mongo server to connect to
  String uri;

  /// write concern used when connecting to the db
  final mongo.WriteConcern writeConcern;

  MongoDbPool(this.uri,
      {int poolSize: 10, this.writeConcern: mongo.WriteConcern.ACKNOWLEDGED})
      : super(poolSize);

  /// Opens a new connection
  @override
  Future<mongo.Db> openNewConnection() async {
    mongo.Db db = new mongo.Db(uri);
    await db.open(writeConcern: writeConcern);
    return db;
  }

  /// Closes the connection
  @override
  void closeConnection(mongo.Db db) {
    db.close();
  }

  /// Collection of named pools
  static Map<String, MongoDbPool> _pools = {};

  /// Creates a named pool or returns an existing one if the pool with given
  /// name already exists
  factory MongoDbPool.Named(String uri,
      {int poolSize,
      mongo.WriteConcern writeConcern: mongo.WriteConcern.ACKNOWLEDGED}) {
    if (_pools[uri] == null) {
      _pools[uri] =
          new MongoDbPool(uri, poolSize: poolSize, writeConcern: writeConcern);
    }

    return _pools[uri];
  }
}
