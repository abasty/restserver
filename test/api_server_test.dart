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

Future<void> subscribe() async {
  print('Subscribing..');
  try {
    var request = http.Request('GET', Uri.http(host, 'sync'));
    request.headers['Cache-Control'] = 'no-cache';
    request.headers['Accept'] = 'text/event-stream';
    //var response = _client.send(request);
    var response = await _client.send(request).asStream().first;
    //var status = response.stream.first

    //var response = await http.Response.fromStream(await _client.send(request));
    print('Received statusCode: ${response.statusCode}');
  } catch (e) {
    print('Caught $e');
  }
}

void main() {
  test('GET rayons', () async {
    var map = await fetchMap('courses/all');
    print(map);
  });
  test('Sync', () async {
    await subscribe();
    _client.close();
  });
}
