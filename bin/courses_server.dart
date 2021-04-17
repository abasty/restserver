// @dart=2.9

import 'dart:async';
import 'package:restserver/courses_sse.dart';
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
  courses_sse.listenSseClients(sse);

  final cascade =
      Cascade().add(api).add(courses_sse.checkSseClientId).add(sse.handler);

  // ignore: todo
  // TODO: Add CorsHeaders on Response in Pipeline
  final pipeline = const Pipeline()
      .addMiddleware(logRequests())
      // .addMiddleware(addMonHeader)
      .addHandler(cascade.handler);

  final server = await io.serve(pipeline, 'localhost', 8067);
  print('Server launched on ${server.address.address}:${server.port}');
}

int sseClientId = 0;

// Was not able to add parameter sseClientId to the request as query is
// read-only when created with request.change => ask question to shelf
Handler addMonHeader(innerHandler) {
  return (request) async {
    var updatedRequest = request.change(
      headers: {'mon-header': 'ma-valeur'},
    );
    return await innerHandler(updatedRequest);
  };
}

// void addCorsHeaders(HttpResponse response) {
//   response.headers.add('Access-Control-Allow-Origin', '*');
//   response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS, GET');
//   response.headers.add('Access-Control-Allow-Headers',
//       'Origin, X-Requested-With, Content-Type, Accept');
// }
