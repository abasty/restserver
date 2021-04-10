import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'courses_api.dart';
import 'mapdb.dart';

Future<void> main() async {
  db = MapDb('bin/courses.json');
  final api = Router();
  api.mount('/courses/', CoursesApi().router);

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
