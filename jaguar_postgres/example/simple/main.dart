/// File: main.dart
library jaguar.example.silly;

import 'dart:async';
import 'package:jaguar_reflect/jaguar_reflect.dart';
import 'package:jaguar/jaguar.dart';
import 'package:postgres/postgres.dart' as pg;

import 'package:conn_pool/conn_pool.dart';
import 'package:jaguar_postgres/jaguar_postgres.dart';

final postgresPool = PostgresPool('jaguar_learn',
    password: 'dart_jaguar', minPoolSize: 5, maxPoolSize: 10);

Future<void> pgInterceptor(Context ctx) => postgresPool.injectInterceptor(ctx);

@Controller(path: '/post')
// NOTE: This is how Postgres interceptor is wrapped around a route.
@Intercept(const [pgInterceptor])
class PostgresExampleApi {
  Future<Map> _fetchById(pg.PostgreSQLConnection db, int id) async {
    List<Map<String, Map<String, dynamic>>> values =
        await db.mappedResultsQuery("SELECT * FROM posts WHERE id = $id;");
    if (values.isEmpty) return null;
    return values.first.values.first;
  }

  @GetJson(path: '/:id')
  Future<Map> readById(Context ctx) async {
    int id = ctx.pathParams.getInt('id');
    pg.PostgreSQLConnection db = ctx.getVariable<pg.PostgreSQLConnection>();
    return _fetchById(db, id);
  }

  @GetJson()
  Future<List<Map>> readAll(Context ctx) async {
    pg.PostgreSQLConnection db = ctx.getVariable<pg.PostgreSQLConnection>();
    List<Map<String, Map<String, dynamic>>> values =
        await db.mappedResultsQuery("SELECT * FROM posts;");
    return values.map((m) => m.values.first).toList();
  }

  @PostJson()
  Future<Map> create(Context ctx) async {
    Map body = await ctx.bodyAsJsonMap();
    pg.PostgreSQLConnection db = ctx.getVariable<pg.PostgreSQLConnection>();
    List<List<dynamic>> id = await db.query(
        "INSERT INTO posts (name, age) VALUES ('${body['name']}', ${body['age']}) RETURNING id;");
    if (id.isEmpty || id.first.isEmpty) Response.json(null);
    return _fetchById(db, id.first.first);
  }

  @PutJson(path: '/:id')
  Future<void> update(Context ctx) async {
    int id = ctx.pathParams.getInt('id');
    Map body = await ctx.bodyAsJsonMap();
    pg.PostgreSQLConnection db = ctx.getVariable<pg.PostgreSQLConnection>();
    await db.execute(
        "UPDATE posts SET name = '${body['name']}', age = ${body['age']} WHERE id = $id;");
    return _fetchById(db, id);
  }

  @Delete(path: '/:id')
  Future<void> delete(Context ctx) async {
    String id = ctx.pathParams['id'];
    pg.PostgreSQLConnection db = ctx.getVariable<pg.PostgreSQLConnection>();
    await db.execute("DELETE FROM posts WHERE id = $id;");
  }
}

Future<void> setup() async {
  Connection<pg.PostgreSQLConnection> conn;
  conn = await postgresPool.pool.get(); // TODO handle open error
  pg.PostgreSQLConnection db = conn.connection;

  try {
    await db.execute("CREATE DATABSE jaguar_learn;");
  } catch (e) {} finally {}

  try {
    await db.execute("DROP TABLE posts;");
  } catch (e) {} finally {}

  try {
    await db.execute(
        "CREATE TABLE posts (id SERIAL PRIMARY KEY, name VARCHAR(255), age INT);");
  } catch (e) {} finally {
    if (conn != null) await conn.release();
  }
}

Future<Null> main(List<String> args) async {
  await setup();

  final server = new Jaguar(port: 10000);
  server.add(reflect(PostgresExampleApi()));
  server.log.onRecord.listen(print);

  await server.serve(logRequests: true);
}
