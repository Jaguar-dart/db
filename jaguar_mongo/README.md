# jaguar_mongo

Mongo interceptor for Jaguar

`MongoDb` interceptor can be wrapped around routes to automatically connect and 
release connection to a mongodb server every request. 
 
Note: `MongoDb` interceptor does not create and destroy new connection every request. 
It just uses one from a pool of  connections. This way, you wont be over-loading mongodb 
server with infinite connections.

```dart
/// Mongo interceptor
MongoDb mongoDb(Context ctx) => new MongoDb('mongodb://localhost:27017/test');

@Api(path: '/api')
  @WrapOne(mongoDb)  // Wrap the mongo interceptor around a route
class TodoApi {
  @Get()
  Future<String> fetchAll(Context ctx) async {
    // ...
  }
  
  @Post()
  Future<String> add(Context ctx) async {
    // ...
  }
}
```

`MongoDb` interceptor injects the per-request `Db` connection into the interceptor inputs of `Context`.

The per-request `Db` connection can be obtained using `getInterceptorResult` method of the `Context`.

```dart
  @Get()
  Future<String> fetchAll(Context ctx) async {
    // Get the Db instance from the interceptor
    final Db db = ctx.getInterceptorResult(MongoDb);
    // Use Db to fetch Todo items
    final res = await (await db.collection('todo').find()).toList();
    return await JSON.encode(res);
  }
```

# A complete example

# Server

```dart
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
  final server = new Jaguar();
  server.addApi(reflect(new TodoApi()));
  await server.serve();
}
```

## Client

```dart
Future doClient() async {
  final url = 'http://localhost:8080/api/todo';
  final jClient = new JsonClient(client);

  final res = (await jClient.get(url)).deserialize();
  print(res);
  print((await jClient.post(url, body: {'text': 'Laundry', 'time': 'Today'}))
      .deserialize());
  print((await jClient.get(url)).deserialize());
}
```