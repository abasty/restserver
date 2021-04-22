import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'package:courses_sse_client/courses_sse_client.dart' show SseClient;

const host = 'localhost:8067';

Future<Object> fetchData(String uri) async {
  var response = await http.get(Uri.http(host, uri));
  if (response.statusCode == 200) {
    return json.decode(response.body) as Object;
  } else {
    throw Exception('Failed to fetch URI');
  }
}

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

  test('SseClient notifications', () async {
    const sse_url = 'http://$host/sync';
    var produit = {};
    SseClient? client;
    SseClient? client2;
    SseClient? client3;
    var notifs = <String>[];
    var quantite = 0;
    try {
      client = SseClient.fromUrl(sse_url)
        ..stream.listen((event) => notifs.add(event), cancelOnError: true);
      await client.onConnected;

      client2 = SseClient.fromUrl(sse_url)
        ..stream.listen((event) => notifs.add(event), cancelOnError: true);
      await client2.onConnected;

      client3 = SseClient.fromUrl(sse_url)
        ..stream.listen((event) => notifs.add(event), cancelOnError: true);
      await client3.onConnected;

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
    } on Exception {
      print('Connexion impossible');
      assert(false);
    }

    if (client != null && client2 != null && client3 != null) {
      /// Poste le produit sélectionné avec sa quantité modifiée depuis le
      /// premier client.
      var response = await http.post(
        Uri.http(host, 'courses/produit', {'sseClientId': client.clientId}),
        body: json.encode(produit),
      );
      assert(response.statusCode == 200);

      /// Attend un peu pour être sûr que le serveur a envoyé les mise à jour.
      await Future.delayed(Duration(milliseconds: 150));

      /// On a trois clients, l'initiateur ne reçoit pas la mise à jour donc
      /// seuls deux clients doivent être notifiés.
      assert(notifs.length == 2);

      client.close();
      client2.close();
      client3.close();
    }
  });
}
