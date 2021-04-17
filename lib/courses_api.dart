// @dart=2.9

import 'dart:convert';

import 'package:restserver/courses_sse.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'mapdb.dart';

class CoursesApi {
  Router get router {
    final router = Router();

    router.get('/all', (Request request) {
      // print(request.headers['mon-header']);
      return Response.ok(json.encode(db.data),
          headers: {'Content-Type': 'application/json'});
    });

    router.get('/rayons', (Request request) {
      return Response.ok(json.encode(db.data['rayons']),
          headers: {'Content-Type': 'application/json'});
    });

    router.get('/produits', (Request request) {
      return Response.ok(json.encode(db.data['produits']),
          headers: {'Content-Type': 'application/json'});
    });

    router.post('/produit', (Request request) async {
      final payload = await request.readAsString();
      print('payload: $payload');
      // data.add(json.decode(payload));
      courses_sse.advertiseOthers(0);
      return Response.ok(payload,
          headers: {'Content-Type': 'application/json'});
    });

    router.delete('/<id>', (Request request, String id) {
      // final parsedId = int.tryParse(id);
      // data.removeWhere((film) => film['id'] == parsedId);
      return Response.ok('Deleted.');
    });

    print('Registered Courses REST API');
    return router;
  }
}
