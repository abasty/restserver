import 'dart:convert';

import 'dart:io';

class MapDb {
  final String _name;
  final Map<String, dynamic> data = {};
  MapDb(this._name) {
    var str = File(_name).readAsStringSync();
    final map = json.decode(str) as Map<String, dynamic>;
    str = map['modele'] as String;
    data.addAll(json.decode(str) as Map<String, dynamic>);
  }
}

late MapDb db;
