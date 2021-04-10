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

void main() {
  test('GET rayons', () async {
    var map = await fetchMap('courses/all');
    print(map);
  });
}
