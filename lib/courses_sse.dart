// @dart=2.9

import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:sse/server/sse_handler.dart';

class CoursesSee {
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
    clients.removeWhere((key, value) {
      if (value == client) {
        print('Close SSE Client [$key]');
        return true;
      }
      return false;
    });
  }

  void acceptSseClient(SseConnection client) {
    print('Accepted SSE client [${incomings.first}]');
    clients[incomings.first] = client;
    incomings.remove(incomings.first);
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

  void advertiseOthers(String payload) {
    clients.forEach((id, client) {
      client.sink.add(payload);
    });
  }
}

var courses_sse = CoursesSee();
