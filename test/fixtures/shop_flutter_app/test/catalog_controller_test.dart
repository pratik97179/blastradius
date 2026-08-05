import 'package:flutter_test/flutter_test.dart';
import 'package:shop_flutter_app/providers/catalog_controller.dart';
import 'package:shop_flutter_app/repositories/catalog_repository.dart';
import 'package:shop_flutter_app/services/catalog_service.dart';

void main() {
  test('refresh loads catalog items', () async {
    final controller = CatalogController(
      CatalogRepository(CatalogService()),
    );
    await controller.refresh();
    expect(controller.items, isNotEmpty);
  });
}
