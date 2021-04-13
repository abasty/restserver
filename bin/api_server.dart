// @dart=2.9

import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sse/server/sse_handler.dart';

import 'package:restserver/courses_api.dart';
import 'package:restserver/mapdb.dart';

final List<SseConnection> clients = [];

void closeSseClient(SseConnection client) {
  var ok = clients.remove(client);
  print('Unregister Sync Client [${client.hashCode}, OK: $ok]');
  clients.remove(client);
}

void acceptSseClient(SseConnection client) {
  // On place les clients dans un tableau, sur error ou done on les vire. Sur
  // data on propage la data sur les autres.
  print('Registered new Sync Client [${client.hashCode}]');
  clients.add(client);
  client.stream.listen(print, onDone: () {
    closeSseClient(client);
  }, onError: (Object e) {
    closeSseClient(client);
  }, cancelOnError: true);
}

void listenSseClients(SseHandler sse) async {
  print('Listen SSE clients');
  while (await sse.connections.hasNext) {
    var client = await sse.connections.next;
    acceptSseClient(client);
  }
}

Future<void> main() async {
  db = MapDb('assets/courses.json');

  final api = Router();
  api.mount('/courses/', CoursesApi().router);

  final sse = SseHandler(Uri.parse('/sync'));
  listenSseClients(sse);

  var cascade = Cascade().add(api).add(checkSseClientId).add(sse.handler);

  // ignore: todo
  // TODO: Add CorsHeaders on Response in Pipeline
  var pipeline = const Pipeline()
      .addMiddleware(logRequests())
      // .addMiddleware(addClientId)
      .addHandler(cascade.handler);

  var server = await io.serve(pipeline, 'localhost', 8067);
  print('Server launched on ${server.address.address}:${server.port}');
}

FutureOr<Response> checkSseClientId(request) {
  // Check if sseClientId is valid in sync request (or else send back a
  // forbidden error response)
  if (request.url.path == 'sync') {
    var sseClientIdStr = request.url.queryParameters['sseClientId'];
    var sseClientId = int.tryParse(sseClientIdStr ?? '-1');
    if (sseClientId <= 0) {
      return Response.forbidden('Invalid sseClientId value');
    }
  }
  return Response.notFound('not found');
}

int sseClientId = 0;

// Was not able to add parameter sseClientId to the request as query is
// read-only when created with request.change => ask question to shelf
Handler addClientId(innerHandler) {
  return (request) async {
    // var updatedRequest = request.change(
    //   headers: {'mon-header': 'ma-valeur'},
    //   // path: '/',
    // );
    var updatedRequest = request;
    if (request.url.path == 'sync') {
      updatedRequest = Request(
        'GET',
        Uri.http('localhost', '/sync', {'sseClientId': '${sseClientId++}'}),
        headers: request.headers,
        context: request.context,
        // onHijack: request.
      );

      print('request: ${request.requestedUri}');
      print('request: ${updatedRequest.requestedUri}');
    }
    return await innerHandler(updatedRequest);
  };
}

// void addCorsHeaders(HttpResponse response) {
//   response.headers.add('Access-Control-Allow-Origin', '*');
//   response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS, GET');
//   response.headers.add('Access-Control-Allow-Headers',
//       'Origin, X-Requested-With, Content-Type, Accept');
// }
