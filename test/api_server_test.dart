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

var _client;

Future<void> subscribe() async {
  print('Subscribing..');
  try {
    _client = http.Client();

    var request = http.Request('GET', Uri.parse('http://$host/sync'));
    request.headers['Cache-Control'] = 'no-cache';
    request.headers['Accept'] = 'text/event-stream';

    Future<http.StreamedResponse> response = _client.send(request);

    response.asStream().listen((streamedResponse) {
      print(
          'Received streamedResponse.statusCode:${streamedResponse.statusCode}');
      streamedResponse.stream.listen((data) {
        print('Received data:$data');
      });
    });
  } catch (e) {
    print('Caught $e');
  }
}

void unsubscribe() {
  _client.close();
}

void main() {
  test('GET rayons', () async {
    var map = await fetchMap('courses/all');
    print(map);
  });
  test('Sync', () async {
    await subscribe();
  });
}
