import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sse/server/sse_handler.dart';

import 'package:restserver/courses_api.dart';
import 'package:restserver/courses_sse.dart';
import 'package:restserver/mapdb.dart';

const cors_headers = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': '*',
};

final corsHeaders = createMiddleware(
    requestHandler: (request) => request.method == 'OPTIONS'
        ? Response.ok(null, headers: cors_headers)
        : null,
    responseHandler: (response) => response.change(headers: cors_headers));

Future<void> main() async {
  db = MapDb('assets/courses.json');

  final courses_api = Router();
  courses_api.mount('/courses/', CoursesApi().router);

  final sse = SseHandler(Uri.parse('/sync'));
  courses_sse.listen(sse);

  final cascade = Cascade().add(courses_api).add(courses_sse).add(sse.handler);

  final pipeline = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders)
      .addHandler(cascade.handler);

  final server = await io.serve(pipeline, 'localhost', 8067);
  print('Server launched on ${server.address.address}:${server.port}');
}
