import 'dart:convert';

import 'dart:io';

// FileStorage
// MongoDBStorage

class MapDb {
  final String _name;
  final Map<String, dynamic> data = {};
  MapDb(this._name) {
    var str = File(_name).readAsStringSync();
    final map = json.decode(str) as Map<String, dynamic>;
    str = map['modele'] as String;
    data.addAll(json.decode(str) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> majProduit(Map<String, dynamic> produit) async {
    return produit;
  }
}

late MapDb db;
