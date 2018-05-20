library jaguar_mongo.interceptor;

import 'dart:async';

import 'package:jaguar/jaguar.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:connection_pool/connection_pool.dart';

import 'pool.dart';

/// Interceptor to connect to MongoDb and manage connection pool
///
/// Creates new MongoDb connection on [pre] and closes the connection on [post]
/// or [onException].
///
/// Parameters:
///   [mongoUri]: URI of mongo server
///   [poolSize]: size of the connection pool
///   [writeConcern]: write concern used when connecting to the db
///
///     @Api(path: '/api')
///     class TodoApi {
///       // Mongo interceptor
///       MongoDb mongoDb(Context ctx) => new MongoDb('mongodb://localhost:27017/test');
///
///       @Get()
///       @WrapOne(#mongoDb)  // Wrap the mongo interceptor around a route
///       Future<String> fetchAll(Context ctx) async {
///         // Get the Db instance from the interceptor
///         final Db db = ctx.getInput(MongoDb);
///     	  // Use Db to fetch Todo items
///     	  final res = await (await db.collection('todo').find()).toList();
///     	  return await JSON.encode(res);
///       }
///
///       @Post()
///       @WrapOne(#mongoDb)
///       Future<String> add(Context ctx) async {
///         final Db db = ctx.getInput(MongoDb);
///         await db.collection('todo').insert(await ctx.req.bodyAsJsonMap());
///     	  // Use Db to fetch Todo items
///     	  final res = await (await db.collection('todo').find()).toList();
///     	  return await JSON.encode(res);
///       }
///     }
class MongoDb extends FullInterceptor {
  /// URI of mongo server to connect to
  final String mongoUri;

  /// size of the connection pool
  final int poolSize;

  /// write concern used when connecting to the db
  final mongo.WriteConcern writeConcern;

  /// The connection pool
  MongoDbPool _pool;

  /// The connection
  ManagedConnection<mongo.Db> _managedConnection;

  /// Returns the mongodb connection
  mongo.Db get conn => _managedConnection?.conn;

  MongoDb(this.mongoUri,
      {this.writeConcern: mongo.WriteConcern.ACKNOWLEDGED, this.poolSize: 10});

  mongo.Db output;

  /// Establishes a connection to mongodb server on route entry
  Future before(Context ctx) async {
    _pool = new MongoDbPool.Named(mongoUri,
        poolSize: poolSize, writeConcern: writeConcern);
    _managedConnection = await _pool.getConnection();
    output = conn;
    ctx.addInterceptor(MongoDb, id, this);
  }

  /// Closes the connection on route exit
  FutureOr<Response> after(Context ctx, Response resp) {
    _releaseConn();
    return resp;
  }

  /// Closes the connection in case an exception occurs in route chain before
  /// [post] is called
  void onException() {
    _releaseConn();
    return null;
  }

  /// Releases connection
  void _releaseConn() {
    if (_managedConnection != null) {
      _pool.releaseConnection(_managedConnection);
      _managedConnection = null;
    }
  }
}
