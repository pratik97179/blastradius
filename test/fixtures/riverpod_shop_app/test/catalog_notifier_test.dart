import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_shop_app/providers/catalog_notifier.dart';

void main() {
  test('CatalogNotifier refresh loads catalog items', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(catalogProvider.notifier).refresh();
    expect(container.read(catalogProvider), ['sku-1', 'sku-2']);
  });
}
