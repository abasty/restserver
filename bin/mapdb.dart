import 'dart:convert';

import 'dart:io';

class MapDb {
  final String _name;
  final Map<String, dynamic> data = {};
  MapDb(this._name) {
    data.addAll(
        json.decode(File(_name).readAsStringSync()) as Map<String, dynamic>);
  }
}

late MapDb db;
