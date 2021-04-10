import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'mapdb.dart';

class CoursesApi {
  Router get router {
    final router = Router();

    router.get('/', (Request request) {
      return Response.ok(json.encode(db.data),
          headers: {'Content-Type': 'application/json'});
    });

    router.post('/', (Request request) async {
      final payload = await request.readAsString();
      // data.add(json.decode(payload));
      return Response.ok(payload,
          headers: {'Content-Type': 'application/json'});
    });

    router.delete('/<id>', (Request request, String id) {
      // final parsedId = int.tryParse(id);
      // data.removeWhere((film) => film['id'] == parsedId);
      return Response.ok('Deleted.');
    });

    return router;
  }
}
