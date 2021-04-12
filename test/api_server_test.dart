import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
// ignore: import_of_legacy_library_into_null_safe
// import 'package:sse/client/sse_client.dart';

const host = 'localhost:8067';

Future<Map<String, dynamic>> fetchMap(String uri) async {
  var response = await http.get(Uri.http(host, uri));
  if (response.statusCode == 200) {
    return json.decode(response.body) as Map<String, dynamic>;
  } else {
    throw Exception('Failed to fetch URI');
  }
}

final _client = http.Client();

Future<Stream<http.StreamedResponse>> subscribe() async {
  print('Subscribing..');
  // Cannot use _client.get because of `fromStream` in _sendUnstreamed (hangs)
  // return Response.fromStream(await send(request));
  var request = http.Request('GET', Uri.http(host, 'sync'));
  request.headers['Cache-Control'] = 'no-cache';
  request.headers['Accept'] = 'text/event-stream';
  // return _client.send(request).asStream();
  return _client.send(request).asStream();
}

void handleSse(Stream<http.StreamedResponse> sse) async {
  await for (var response in sse) {
    // Here call a callback
    print('Received statusCode: ${response.statusCode}');
  }
}

void main() {
  test('GET rayons', () async {
    try {
      var map = await fetchMap('courses/all');
      print(map);
    } on Exception {
      print('Connexion impossible');
      assert(false);
    }
  });
  test('Sync', () async {
    var stream = await subscribe();
    try {
      handleSse(stream);
      await Future.delayed(Duration(milliseconds: 100));
    } on Exception {
      print('Connexion impossible');
      assert(false);
    }
    _client.close();
  });
}
