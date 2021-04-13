import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

const host = 'localhost:8067';

Future<Map<String, dynamic>> fetchMap(String uri) async {
  var response = await http.get(Uri.http(host, uri));
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception('Failed to fetch URI');
  }
}

Future<Stream<http.StreamedResponse>> subscribeSse(
    http.Client client, int id) async {
  print('Subscribing to SSE with sseClientId: $id.');
  // Cannot use _client.get because of `fromStream` in _sendUnstreamed (hangs)
  // return Response.fromStream(await send(request));
  var request =
      http.Request('GET', Uri.http(host, '/sync', {'sseClientId': '$id'}));
  request.headers['Cache-Control'] = 'no-cache';
  request.headers['Accept'] = 'text/event-stream';
  return client.send(request).asStream();
}

void handleSse(Stream<http.StreamedResponse> sse) async {
  await for (var response in sse) {
    print('Received statusCode: ${response.statusCode}');
    if (response.statusCode != 200) return;
    // Here handle server sent event
  }
}

void main() {
  test('GET /courses/rayons', () async {
    try {
      var map = await fetchMap('courses/all');
      print(map);
    } on Exception {
      print('Connexion impossible');
      assert(false);
    }
  });

  test('Sync', () async {
    final client = http.Client();
    try {
      handleSse(await subscribeSse(client, 0));
      handleSse(await subscribeSse(client, 1));
      await Future.delayed(Duration(milliseconds: 500));
    } on Exception {
      print('Connexion impossible');
      assert(false);
    }
  });
}
