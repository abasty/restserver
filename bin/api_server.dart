// import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:sse/server/sse_handler.dart';

import 'package:restserver/courses_api.dart';
import 'package:restserver/mapdb.dart';

Future<void> main() async {
  db = MapDb('assets/courses.json');
  final api = Router();
  api.mount('/courses/', CoursesApi().router);
  final sse = SseHandler(Uri.parse('/sync'));
  var handler = Cascade().add(sse.handler).add(api).handler;

  // ignore: todo
  // TODO: Add CorsHeaders in Pipeline
  var server =
      const Pipeline().addMiddleware(logRequests()).addHandler(handler);

  print('Launching API server');
  await io.serve(server, 'localhost', 8067);
}

// void addCorsHeaders(HttpResponse response) {
//   response.headers.add('Access-Control-Allow-Origin', '*');
//   response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS, GET');
//   response.headers.add('Access-Control-Allow-Headers',
//       'Origin, X-Requested-With, Content-Type, Accept');
// }
