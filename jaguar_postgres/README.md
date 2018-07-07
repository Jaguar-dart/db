# jaguar_postgres

A Postgres interceptor for Jaguar. 

# Usage

## Creating the pool

Create an instance of `PostgresPool`. Supply essential database configuration. By default,
`PostgresPool` builds on a `SharedPool`. Supply `minPoolSize` and `maxPoolSize` to control
pool size.

```dart
final postgresPool = PostgresPool('jaguar_learn',
    password: 'dart_jaguar', minPoolSize: 5, maxPoolSize: 10);
```

## Declaring the interceptor

`PostgresPool` exposes `injectInterceptor` method to interceptor a route and add `PostgreSQLConnection`
instance to it.

```dart
Future<void> pgInterceptor(Context ctx) => postgresPool.injectInterceptor(ctx);
```

## Intercepting routes

Add the `pgInterceptor` interceptor to the route chain.

```dart
@Controller()
@Intercept(const [pgInterceptor])
class PostgresExampleApi {
  // TODO Add routes ...
}
```

## Getting and using connection

In the route handler, get `PostgreSQLConnection` using `getVariable<pg.PostgreSQLConnection>` method
of route `Context`.

```dart
  @GetJson()
  Future<List<Map>> readAll(Context ctx) async {
    pg.PostgreSQLConnection db = ctx.getVariable<pg.PostgreSQLConnection>();
    List<Map<String, Map<String, dynamic>>> values =
        await db.mappedResultsQuery("SELECT * FROM posts;");
    return values.map((m) => m.values.first).toList();
  }
```