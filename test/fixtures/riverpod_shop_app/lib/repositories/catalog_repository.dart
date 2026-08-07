import '../services/catalog_service.dart';

class CatalogRepository {
  CatalogRepository(this._service);

  final CatalogService _service;

  Future<List<String>> loadCatalog() => _service.fetchItems();
}
