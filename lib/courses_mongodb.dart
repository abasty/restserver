import 'package:mongo_dart/mongo_dart.dart';

abstract class CoursesDb {}

class CoursesFileDb implements CoursesDb {}

class CoursesMongoDB extends CoursesDb {
  final Db _db = Db('mongodb://localhost/courses');
  Future<void> writeAll(Map<String, dynamic> json) async {}

  Future<Map<String, dynamic>> readAll() async {
    var map = {'rayons': [], 'produits': []};

    if (!_db.isConnected) await _db.open();

    if (_db.isConnected) {
      var produits = _db.collection('produits');
      var rayons = _db.collection('rayons');

      map = {
        'rayons': await rayons.find().toList(),
        'produits': await produits.find().toList(),
      };
    }

    return map;
  }
}
