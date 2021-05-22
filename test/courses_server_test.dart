import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'package:courses_sse_client/courses_sse_client.dart' show SseClient;

import '../bin/courses_server.dart' as server;

const port = '8026';
const host = 'localhost';
const host_url = '$host:$port';
const sse_url = 'https://$host_url/sync';

// HttpOverrides
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<Object> fetchData(String uri) async {
  var response = await http.get(Uri.https(host_url, uri));
  if (response.statusCode == 200) {
    return json.decode(response.body) as Object;
  } else {
    throw Exception('Failed to fetch URI');
  }
}

void main() async {
  HttpOverrides.global = DevHttpOverrides();
  await server.main(['--host', host, '--port', port, '--pem', 'bin']);

  test('API GET /courses/all', () async {
    try {
      var map = await fetchData('courses/all');
      assert(map is Map<String, dynamic>);
      map = map as Map<String, dynamic>;
      // print(map);
      assert(map.keys.length == 2);
      assert(map['rayons'] is List);
      assert(map['produits'] is List);
    } catch (e) {
      expect(true, false, reason: 'Connexion impossible');
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
    } catch (e) {
      expect(true, false, reason: 'Connexion impossible');
    }
  });

  test('API POST /courses/produit', () async {
    try {
      var produit = {
        'nom': 'TEST 3',
        'rayon': {'nom': 'Rayon 3'},
        'quantite': 42,
        'fait': false
      };
      var client = SseClient.fromUrl(sse_url);
      await client.onConnected;
      var response = await http.post(
        Uri.https(
            host_url, 'courses/produit', {'sseClientId': client.clientId}),
        body: json.encode(produit),
      );
      assert(response.statusCode == 200);
      produit['update'] = produit['nom']!;
      produit['nom'] = 'TEST 3->4';
      response = await http.post(
        Uri.https(
            host_url, 'courses/produit', {'sseClientId': client.clientId}),
        body: json.encode(produit),
      );
      assert(response.statusCode == 200);
      client.close();
    } catch (e) {
      expect(true, false, reason: 'Connexion impossible');
    }
  });

  test('SseClient notifications', () async {
    var produit = {};
    var client = SseClient.fromUrl(sse_url);
    var client2 = SseClient.fromUrl(sse_url);
    var client3 = SseClient.fromUrl(sse_url);
    var notifs = <String>[];
    var quantite = 0;
    try {
      await client.onConnected;
      client.stream.listen((event) => notifs.add(event), cancelOnError: true);

      await client2.onConnected;
      client2.stream.listen((event) => notifs.add(event), cancelOnError: true);

      await client3.onConnected;
      client3.stream.listen((event) => notifs.add(event), cancelOnError: true);

      /// Demande au serveur la liste de produits et on sélectionne le premier.
      var produits = await fetchData('courses/produits');
      assert(produits is List);
      produits = produits as List;
      assert(produits.isNotEmpty);
      assert(produits[0] is Map<String, dynamic>);

      /// [produit] contient le premier produit, on fixe sa quantité.
      produit = produits[0] as Map<String, dynamic>;
      quantite = Random().nextInt(100);
      produit['quantite'] = quantite;
    } catch (e) {
      expect(true, false, reason: 'Connexion impossible');
    }

    /// Poste le produit sélectionné avec sa quantité modifiée depuis le
    /// premier client.
    var response = await http.post(
      Uri.https(host_url, 'courses/produit', {'sseClientId': client.clientId}),
      body: json.encode(produit),
    );
    assert(response.statusCode == 200);

    /// Attend un peu pour être sûr que le serveur a envoyé les mises à jour.
    await Future.delayed(Duration(milliseconds: 150));

    /// On a trois clients, l'initiateur ne reçoit pas la mise à jour donc
    /// seuls deux clients doivent être notifiés.
    assert(notifs.length == 2);

    client.close();
    client2.close();
    client3.close();
  });
}
