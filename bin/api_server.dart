// @dart=2.9

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sse/server/sse_handler.dart';

import 'package:restserver/courses_api.dart';
import 'package:restserver/mapdb.dart';

final List<SseConnection> clients = [];

void registerSse(SseConnection client) {
  // On place les clients dans un tableau, sur error ou done on les vire. Sur
  // data on propage la data sur les autres.
  clients.add(client);
  print('Connection (sse): ${client.hashCode}.');
  client.stream.listen(print, onDone: () {
    var ok = clients.remove(client);
    print('Removed ${client.hashCode} OK: $ok');
    print('Clients: ${clients.length}');
  }, onError: (Object e) {
    var ok = clients.remove(client);
    print('Removed ${client.hashCode} OK: $ok');
    clients.remove(client);
  }, cancelOnError: true);
}

Future<void> main() async {
  db = MapDb('assets/courses.json');

  final api = Router();
  api.mount('/courses/', CoursesApi().router);

  final sse = SseHandler(Uri.parse('/sync'));

  var cascade = Cascade().add(api).add(sse.handler);

  // ignore: todo
  // TODO: Add CorsHeaders on Response in Pipeline
  // ignore: todo
  // TODO: Add sseClientId on Request in Pipeline
  var pipeline =
      const Pipeline().addMiddleware(logRequests()).addHandler(cascade.handler);

  print('Launching API server');
  var server = await io.serve(pipeline, 'localhost', 8067);
  print('Server launched on ${server.address.address}:${server.port}');

  // ignore: todo
  // TODO: Move this loop in an async function
  while (await sse.connections.hasNext) {
    var client = await sse.connections.next;
    registerSse(client);
    print('Clients: ${sse.numberOfClients}');
  }
  print('main end');
}

// void addCorsHeaders(HttpResponse response) {
//   response.headers.add('Access-Control-Allow-Origin', '*');
//   response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS, GET');
//   response.headers.add('Access-Control-Allow-Headers',
//       'Origin, X-Requested-With, Content-Type, Accept');
// }
