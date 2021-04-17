import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'package:restserver/courses_sse_client.dart';

const host = 'localhost:8067';

Future<Object> fetchData(String uri) async {
  var response = await http.get(Uri.http(host, uri));
  if (response.statusCode == 200) {
    return json.decode(response.body) as Object;
  } else {
    throw Exception('Failed to fetch URI');
  }
}

/*
Future<Stream<http.StreamedResponse>> subscribeSse(
    http.Client client, int id) async {
  // print('Subscribing to SSE with sseClientId: $id.');
  // Cannot use _client.get because of `fromStream` in _sendUnstreamed (hangs)
  // return Response.fromStream(await send(request));
  var request =
      http.Request('GET', Uri.http(host, '/sync', {'sseClientId': '$id'}));
  request.headers['Cache-Control'] = 'no-cache';
  request.headers['Accept'] = 'text/event-stream';
  return client.send(request).asStream();
}

Future<bool> handleSse(Stream<http.StreamedResponse> sse) async {
  await for (var response in sse) {
    print('Received statusCode: ${response.statusCode}');
    if (response.statusCode != 200) return false;
    // Here handle server sent event
  }
  return true;
}*/

void main() {
  test('API GET /courses/all', () async {
    try {
      var map = await fetchData('courses/all');
      assert(map is Map<String, dynamic>);
      map = map as Map<String, dynamic>;
      // print(map);
      assert(map.keys.length == 2);
      assert(map['rayons'] is List);
      assert(map['produits'] is List);
    } on Exception {
      print('Connexion impossible');
      assert(false);
    }
  });

  test('API GET /courses/rayons', () async {
    try {
      var rayons = await fetchData('courses/rayons');
      assert(rayons is List);
      rayons = rayons as List;
      assert(rayons.length >= 2);
      assert(rayons[1] is Map<String, dynamic>);
      var rayon = rayons[1] as Map<String, dynamic>;
      assert(rayon['nom'] != null);
      assert(rayon['nom'] == 'Boucherie');
    } on Exception {
      print('Connexion impossible');
      assert(false);
    }
  });

  test('SseClient', () async {
    var produit = {};
    var client;
    try {
      client = SseClient('http://localhost:8067/sync')..stream.listen(null);
      await client.onConnected;
      // Demande la liste des produits et sélectionne le premier
      var produits = await fetchData('courses/produits');
      assert(produits is List);
      produits = produits as List;
      assert(produits.isNotEmpty);
      assert(produits[0] is Map<String, dynamic>);
      produit = produits[0] as Map<String, dynamic>;
    } on Exception {
      print('Connexion impossible');
      assert(false);
    }
    // Poste le produit sélectionné
    var response = await http.post(
      Uri.http(host, 'courses/produit'),
      body: json.encode(produit),
    );
    assert(response.statusCode == 200);
    // Vérifie que le produit retourné a le même nom
    var produit_ret = json.decode(response.body);
    assert(produit_ret is Map<String, dynamic>);
    produit_ret = produit_ret as Map<String, dynamic>;
    assert(produit['nom'] == produit_ret['nom']);
  });
}
