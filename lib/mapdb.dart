import 'courses_db_storage.dart';

// FileDB
// MongoDB

late MapDb db;

class MapDb {
  final DbStorageStrategy _storage;

  final Map<String, dynamic> data = {};
  MapDb(this._storage) {
    data.addAll(_storage.load());
  }

  Future<Map<String, dynamic>> majProduit(Map<String, dynamic> produit) async {
    return produit;
  }
}
