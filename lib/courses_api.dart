import 'dart:convert';

import 'package:restserver/courses_sse.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'mapdb.dart';

const content_headers = {
  'Content-Type': 'application/json; charset=utf-8',
};

class CoursesApi {
  Router get router {
    final router = Router();

    router.get('/all', (Request request) {
      return Response.ok(
        json.encode(db.data),
        headers: content_headers,
      );
    });

    router.get('/rayons', (Request request) {
      return Response.ok(
        json.encode(db.data['rayons']),
        headers: content_headers,
      );
    });

    router.get('/produits', (Request request) {
      return Response.ok(
        json.encode(db.data['produits']),
        headers: content_headers,
      );
    });

    router.post('/produit', (Request request) async {
      final payload = await request.readAsString();
      // print('payload: $payload');
      // TODO: Protect the decode(), the as int and merge it to database
      var map = json.decode(payload);
      var sseClientId = int.tryParse(map['sseClientId'] ?? '-1') ?? 0;
      courses_sse.push(payload, sseClientId);
      return Response.ok('');
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
