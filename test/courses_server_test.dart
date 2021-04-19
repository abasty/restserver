import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

import 'courses_sse_client.dart' show SseClient;

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

  test('SseClient', () async {
    const sse_url = 'http://$host/sync';
    var produit = {};
    var client;
    var client2;
    var data = <String>[];
    var quantite = 0;
    try {
      /// Création de deux clients SSE
      client = SseClient(sse_url)
        ..stream.listen((event) => data.add(event), cancelOnError: true);
      await client.onConnected;
      client2 = SseClient(sse_url)
        ..stream.listen((event) => data.add(event), cancelOnError: true);
      await client2.onConnected;

      /// Demande au serveur la liste de produits et on sélectionne le premier
      var produits = await fetchData('courses/produits');
      assert(produits is List);
      produits = produits as List;
      assert(produits.isNotEmpty);
      assert(produits[0] is Map<String, dynamic>);

      /// [produit] contient le premier produit, on fixe sa quantité
      produit = produits[0] as Map<String, dynamic>;
      quantite = Random().nextInt(100);
      produit['quantite'] = quantite;
    } on Exception {
      print('Connexion impossible');
      assert(false);
    }

    /// Poste le produit sélectionné avec sa quantité modifiée
    var response = await http.post(
      Uri.http(host, 'courses/produit'),
      body: json.encode(produit),
    );
    assert(response.statusCode == 200);

    /// Les clients SSe doivent avoir reçu le produit modifié
    var count = 0;
    data.forEach((str) {
      if (str.startsWith('data: ')) {
        var produit_ret = json
            .decode(str.substring(7, str.length - 1).replaceAll('\\"', '"'));
        assert(produit_ret is Map<String, dynamic>);
        produit_ret = produit_ret as Map<String, dynamic>;

        /// Vérifie que le produit retourné a le même nom et que sa quantité a
        /// été modifiée
        assert(produit_ret['nom'] == produit['nom']);
        assert(produit_ret['quantite'] == quantite);
        count++;
      }
    });

    /// Les deux clients doivent avoir reçu un message SSE
    assert(count == 2);
  });
}
