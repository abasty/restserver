import 'courses_db_storage.dart';

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
    var list = data[collection] as List;
    list.removeWhere(
        (item) => item[IDKey] == ID || item[IDKey] == value[IDKey]);
    if (value['deleted'] == null) list.add(value);

    /// Met à jour [_storage]
    _storage.update(collection, ID, value);
  }
}
