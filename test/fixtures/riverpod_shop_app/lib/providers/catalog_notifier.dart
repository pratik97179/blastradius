import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/catalog_repository.dart';
import '../services/catalog_service.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(CatalogService());
});

final catalogProvider =
    NotifierProvider<CatalogNotifier, List<String>>(CatalogNotifier.new);

class CatalogNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  Future<void> refresh() async {
    final items = await ref.read(catalogRepositoryProvider).loadCatalog();
    state = items;
  }
}
