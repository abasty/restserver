import 'dart:convert';
import 'dart:io';

import 'package:mongo_dart/mongo_dart.dart';

const IDKey = 'nom';

abstract class DbAdaptor {
  Future<Map<String, dynamic>> loadAll();

  void update(String collection, String ID, Map<String, dynamic> value);
}

class DbFileReadOnlyAdaptor implements DbAdaptor {
  final String _name;

  DbFileReadOnlyAdaptor(this._name);

  @override
  Future<Map<String, dynamic>> loadAll() async {
    var str = File(_name).readAsStringSync();
    var map = json.decode(str) as Map<String, dynamic>;
    str = map['modele'] as String;
    return json.decode(str) as Map<String, dynamic>;
  }

  @override
  void update(String collection, String ID, Map<String, dynamic> value) {
    // Ne rien faire (read only)
  }
}

class DbMongoAdaptor implements DbAdaptor {
  final Db _db;
  late final DbCollection _rayons;
  late final DbCollection _produits;

  DbMongoAdaptor(String Uri) : _db = Db(Uri);

  @override
  Future<Map<String, dynamic>> loadAll() async {
    var map = <String, dynamic>{};

    if (!_db.isConnected) await _db.open();

    if (_db.isConnected) {
      // TODO: parler de la logique métier, on pourrait faire un select sur le
      // stock. Montrer comment avec compass on peut rajouter des rayons ou
      // supprimer des produits
      _produits = _db.collection('produits');
      _rayons = _db.collection('rayons');
      map.addAll({
        'rayons': await _rayons.find().toList(),
        'produits': await _produits.find().toList(),
      });
    }

    return map;
  }

  @override
  void update(String collection, String ID, Map<String, dynamic> value) async {
    await _produits.deleteOne({IDKey: ID});
    await _produits.deleteOne({IDKey: value[IDKey]});
    await _produits.insertOne({
      IDKey: ID,
      'rayon': {
        'nom': value['rayon']['nom'],
      },
      'quantite': value['quantite'],
      'fait': value['fait'],
    });
  }
}
