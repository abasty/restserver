import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:restserver/courses_api.dart';
import 'package:restserver/courses_db_storage.dart';
import 'package:restserver/courses_sse.dart';
import 'package:restserver/mapdb.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sse/server/sse_handler.dart';

const cors_headers = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': '*',
};

final cors = createMiddleware(
    requestHandler: (request) => request.method == 'OPTIONS'
        ? Response.ok(null, headers: cors_headers)
        : null,
    responseHandler: (response) => response.change(headers: cors_headers));

String certificateChain = 'server_chain.pem';
String serverKey = 'server_key.pem';

Future<void> main(List<String> args) async {
  var parser = ArgParser();
  parser.addOption('mode', allowed: ['file', 'mongodb'], defaultsTo: 'file');
  parser.addOption('mongodb-url', defaultsTo: 'mongodb://localhost/courses');
  parser.addOption('file-path', defaultsTo: 'assets/courses.json');
  parser.addOption('host', defaultsTo: '0.0.0.0');
  parser.addOption('port', defaultsTo: '8067');
  parser.addOption('pem', defaultsTo: '');

  var options;
  int port;
  try {
    options = parser.parse(args);
    port = int.parse(options['port'] as String);
  } catch (e) {
    print(parser.usage);
    exit(1);
  }

  if (options['mode'] == 'file') {
    db = CacheDb(DbFileReadOnlyAdaptor(options['file-path'] as String));
  } else {
    db = CacheDb(DbMongoAdaptor(options['mongodb-url'] as String));
  }
  await db.isLoaded;
  print('Loaded data from ${options["mode"]}');

  final courses_api = Router();
  courses_api.mount('/courses/', CoursesApi().router);

  final sse = SseHandler(Uri.parse('/sync'));
  courses_sse.listen(sse);

  final cascade = Cascade().add(courses_api).add(courses_sse).add(sse.handler);

  final pipeline = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(cors)
      .addHandler(cascade.handler);

  var pemdir = options['pem'];
  HttpServer server;
  if (pemdir != '') {
    var serverContext = SecurityContext();
    serverContext.useCertificateChain('$pemdir/$certificateChain');
    serverContext.usePrivateKey('$pemdir/$serverKey', password: 'dartdart');
    server = await io.serve(pipeline, options['host'], port,
        securityContext: serverContext);
  } else {
    server = await io.serve(pipeline, options['host'], port);
  }
  print('Server launched on '
      'http${pemdir == '' ? '' : 's'}://'
      '${server.address.address}:${server.port}');
}
