import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:sse/server/sse_handler.dart';

class CoursesSse {
  final Map<int, SseConnection> clients = {};
  final Set<int> incomings = {};

  /// shelf handler to check sseClientId parameter in /sync requests
  FutureOr<Response> call(Request request) {
    // Check if sseClientId is valid in sync request (or else send back a
    // forbidden error response)
    if (request.url.path == 'sync' && request.method == 'GET') {
      var sseClientIdStr = request.url.queryParameters['sseClientId'];
      var sseClientId = int.tryParse(sseClientIdStr ?? '-1') ?? 0;
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
  void close(SseConnection client) {
    clients.removeWhere((key, value) {
      if (value == client) {
        print('Close SSE Client [$key]');
        return true;
      }
      return false;
    });
  }

  void _accept(SseConnection client) {
    print('Accepted SSE client [${incomings.first}]');
    clients[incomings.first] = client;
    incomings.remove(incomings.first);
    client.stream.listen(print, onDone: () {
      close(client);
    }, onError: (Object e) {
      close(client);
    }, cancelOnError: true);
  }

  void listen(SseHandler sse) async {
    // TODO: convert to logger
    print('Listen SSE clients');
    while (await sse.connections.hasNext) {
      _accept(await sse.connections.next);
    }
  }

  void push(Request request) async {
    final payload = await request.readAsString();
    final clientIdStr = request.requestedUri.queryParameters['sseClientId'];
    final clientId = int.tryParse(clientIdStr ?? '-1') ?? 0;
    clients.forEach((id, client) {
      if (clientId != id) {
        client.sink.add(payload);
        print('from: $clientId, to: $id');
      }
    });
  }
}

final courses_sse = CoursesSse();
