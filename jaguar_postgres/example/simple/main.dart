/// File: main.dart
library jaguar.example.silly;

import 'dart:async';
import 'package:jaguar_reflect/jaguar_reflect.dart';
import 'package:jaguar/jaguar.dart';
import 'package:postgres/postgres.dart';

import 'package:jaguar_postgres/jaguar_postgres.dart';

@Api(path: '/api')
class PostgresExampleApi {
  @Get(path: '/post')
  // NOTE: This is how postgre interceptor is wrapped
  // around a route.
  @WrapOne(#postgresDb)
  Future<Response<String>> mongoTest(Context ctx) async {
    // NOTE: This is how the opened postgres connection is injected
    // into routes
    PostgreSQLConnection db = ctx.getInput(PostgresDb);
    await db.execute("delete FROM posts");
    await db.execute("insert into posts values (1, 'holla', 'jon')");
    List value = (await db.query("select * from posts WHERE _id = 1")).first;
    return Response.json({"Columns": value});
  }

  PostgresDb postgresDb(Context ctx) =>
      new PostgresDb('localhost', 5432, 'postgres',
          username: 'postgres', password: 'dart_jaguar');
}

Future<Null> main(List<String> args) async {
  final api = new PostgresExampleApi();

  Jaguar server = new Jaguar(multiThread: false);
  server.addApi(reflectJaguar(api));

  await server.serve();
}
