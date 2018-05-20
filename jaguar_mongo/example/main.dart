library jaguar_mongo.example;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:jaguar_client/jaguar_client.dart';
import 'package:jaguar/jaguar.dart';
import 'package:jaguar_reflect/jaguar_reflect.dart';
import 'package:mongo_dart/mongo_dart.dart';

import 'package:jaguar_mongo/jaguar_mongo.dart';

final client = new Client();

/// Mongo interceptor
MongoDb mongoDb(Context ctx) => new MongoDb('mongodb://localhost:27017/test');

@Api(path: '/api/todo')
@WrapOne(mongoDb) // Wrap the mongo interceptor around a route
class TodoApi {
  @Get()
  Future<String> fetchAll(Context ctx) async {
    // Get the Db instance from the interceptor
    final Db db = ctx.getInterceptorResult(MongoDb);
    // Use Db to fetch Todo items
    final res = await (await db.collection('todo').find()).toList();
    return await JSON.encode(res);
  }

  @Post()
  Future<String> add(Context ctx) async {
    final Map body = await ctx.req.bodyAsJsonMap();
    final Db db = ctx.getInterceptorResult(MongoDb);
    await db.collection('todo').insert(body);
    // Use Db to fetch Todo items
    final res = await (await db.collection('todo').find()).toList();
    return await JSON.encode(res);
  }
}

Future server() async {
  final server = new Jaguar(port: 10000);
  server.addApi(reflect(new TodoApi()));
  await server.serve();
}

Future doClient() async {
  final url = 'http://localhost:10000/api/todo';
  final jClient = new JsonClient(client);

  final res = (await jClient.get(url)).deserialize();
  print(res);
  print((await jClient.post(url, body: {'text': 'Laundry', 'time': 'Today'}))
      .deserialize());
  print((await jClient.get(url)).deserialize());
}

main(List<String> args) async {
  await Future.wait([server(), doClient()]);
  exit(0);
}
