import 'courses_db_storage.dart';

const IDKey = 'nom';

late MapDb db;

class MapDb {
  final DbStorageStrategy _storage;
  final Map<String, dynamic> data = {};
  late Future<void> _isLoaded;

  MapDb(this._storage) {
    _isLoaded = loadAll();
  }

  /// [isLoaded] se réalise quand le [loadAll()] initial est terminé.
  Future<void> get isLoaded => _isLoaded;

  Future<void> loadAll() async {
    data.addAll(await _storage.loadAll());
  }

  void update(String collection, String ID, Map<String, dynamic> value) {
    List list = data[collection];
    list.removeWhere(
        (item) => item[IDKey] == ID || item[IDKey] == value[IDKey]);
    list.add(value);
  }
}
