import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'produit_api.dart';

Future<void> main() async {
  final api = Router();
  api.mount('/films/', FilmApi().router);
  api.get('/<name|.*>', (Request request, String name) {
    final param = name.isNotEmpty ? name : 'World';
    return Response.ok('Hello $param!\r\n');
  });

  // TODO: Add CorsHeaders with a middleware
  var handler = const Pipeline().addMiddleware(logRequests()).addHandler(api);

  print('Launching API server');
  await io.serve(handler, 'localhost', 8083);
}

// void addCorsHeaders(HttpResponse response) {
//   response.headers.add('Access-Control-Allow-Origin', '*');
//   response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS, GET');
//   response.headers.add('Access-Control-Allow-Headers',
//       'Origin, X-Requested-With, Content-Type, Accept');
// }
