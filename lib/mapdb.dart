import 'courses_db_storage.dart';

// FileDB
// MongoDB

late MapDb db;

class MapDb {
  final DbStorageStrategy _storage;
  final Map<String, dynamic> data = {};

  MapDb(this._storage) {
    data.addAll(_storage.loadAll());
  }

  void update(String collection, String nom, Map<String, dynamic> value) {
    List list = data[collection];
    list.removeWhere((item) => item[nom] == nom);
    list.add(value);
  }
}
