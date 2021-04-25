import 'dart:convert';
import 'dart:io';

import 'package:mongo_dart/mongo_dart.dart';

abstract class DbStorageStrategy {
  Map<String, dynamic> load();
}

class DbFileStorageStrategy implements DbStorageStrategy {
  final String _name;

  DbFileStorageStrategy(this._name);

  @override
  Map<String, dynamic> load() {
    // TODO: Add try / on
    var str = File(_name).readAsStringSync();
    var map = json.decode(str) as Map<String, dynamic>;
    str = map['modele'] as String;
    return json.decode(str) as Map<String, dynamic>;
  }
}

class DbMongoStorageStrategy implements DbStorageStrategy {
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

  @override
  Map<String, dynamic> load() {
    // TODO: implement load
    throw UnimplementedError();
  }
}
