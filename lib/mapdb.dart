import 'courses_db_storage.dart';

const IDKey = 'nom';

late CacheDb db;

class CacheDb {
  final DbAdaptor _storage;
  final Map<String, dynamic> data = {};
  late Future<void> _isLoaded;

  CacheDb(this._storage) {
    _isLoaded = loadAll();
  }

  /// [isLoaded] se réalise quand le [loadAll()] initial est terminé.
  Future<void> get isLoaded => _isLoaded;

  Future<void> loadAll() async {
    data.addAll(await _storage.loadAll());
  }

  void update(String collection, String ID, Map<String, dynamic> value) {
    /// Met à jour le cache
    List list = data[collection];
    list.removeWhere(
        (item) => item[IDKey] == ID || item[IDKey] == value[IDKey]);
    list.add(value);

    /// Met à jour [_storage]
    _storage.update(collection, ID, value);
  }
}
