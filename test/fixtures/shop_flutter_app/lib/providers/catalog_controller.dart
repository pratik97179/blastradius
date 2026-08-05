import 'package:flutter/foundation.dart';

import '../repositories/catalog_repository.dart';

class CatalogController extends ChangeNotifier {
  CatalogController(this._repository);

  final CatalogRepository _repository;

  List<String> items = const [];
  bool loading = false;

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    items = await _repository.loadCatalog();
    loading = false;
    notifyListeners();
  }
}
