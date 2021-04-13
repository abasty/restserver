// @dart=2.9

import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sse/server/sse_handler.dart';

import 'package:restserver/courses_api.dart';
import 'package:restserver/mapdb.dart';

final Map<int, SseConnection> clients = {};
final Set<int> incomings = {};

/// shelf handler to check sseClientId parameter in /sync requests
FutureOr<Response> checkSseClientId(request) {
  // Check if sseClientId is valid in sync request (or else send back a
  // forbidden error response)
  if (request.url.path == 'sync') {
    var sseClientIdStr = request.url.queryParameters['sseClientId'];
    var sseClientId = int.tryParse(sseClientIdStr ?? '-1');
    if (sseClientId <= 0 ||
        incomings.contains(sseClientId) ||
        clients.containsKey(sseClientId)) {
      return Response.forbidden('Invalid sseClientId value');
    }
    incomings.add(sseClientId);
  }
  return Response.notFound('not found');
}

/// close SSE client and remove it from clients list
void closeSseClient(SseConnection client) {
  clients.removeWhere((key, value) => client == value);
  print('Unregister Sync Client [${client.hashCode}]');
}

void acceptSseClient(SseConnection client) {
  // On place les clients dans un tableau, sur error ou done on les vire. Sur
  // data on propage la data sur les autres.
  print('Accepted new SSE client [${client.hashCode}]');
  clients[incomings.first] = client;
  incomings.remove(incomings.first);
  print(incomings);
  print(clients);
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
      // .addMiddleware(addMonHeader)
      .addHandler(cascade.handler);

  var server = await io.serve(pipeline, 'localhost', 8067);
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
