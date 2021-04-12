// @dart=2.9

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sse/server/sse_handler.dart';

import 'package:restserver/courses_api.dart';
import 'package:restserver/mapdb.dart';

Future<void> main() async {
  db = MapDb('assets/courses.json');
  final api = Router();
  api.mount('/courses/', CoursesApi().router);
  final sse = SseHandler(Uri.parse('/sync'));
  var cascade = Cascade().add(sse.handler).add(api).handler;
  // ignore: todo
  // TODO: Add CorsHeaders in Pipeline
  var pipeline =
      const Pipeline().addMiddleware(logRequests()).addHandler(cascade);

  print('Launching API server');
  var server = await io.serve(pipeline, 'localhost', 8067);
  print('Server launched on ${server.address.address}:${server.port}');
  var connections = sse.connections;
  while (await connections.hasNext) {
    var connection = await connections.next;
    print('Connection (sse): $connection.');
  }
}

// void addCorsHeaders(HttpResponse response) {
//   response.headers.add('Access-Control-Allow-Origin', '*');
//   response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS, GET');
//   response.headers.add('Access-Control-Allow-Headers',
//       'Origin, X-Requested-With, Content-Type, Accept');
// }
