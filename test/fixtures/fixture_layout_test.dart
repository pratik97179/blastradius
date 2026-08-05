import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('portfolio Flutter fixture keeps the MVP dependency chain on disk', () {
    final root = p.join('test', 'fixtures', 'sample_flutter_app');
    final requiredPaths = [
      'lib/services/portfolio_service.dart',
      'lib/repositories/portfolio_repository.dart',
      'lib/bloc/portfolio_bloc.dart',
      'lib/screens/portfolio_screen.dart',
      'lib/screens/dashboard_screen.dart',
      'lib/screens/stock_details_screen.dart',
      'lib/router/app_router.dart',
      'test/portfolio_bloc_test.dart',
      'test/portfolio_screen_test.dart',
      'lib/generated/example.g.dart',
    ];

    for (final relative in requiredPaths) {
      expect(
        File(p.join(root, relative)).existsSync(),
        isTrue,
        reason: 'missing $relative',
      );
    }

    final service = File(p.join(root, 'lib/services/portfolio_service.dart'))
        .readAsStringSync();
    expect(service, contains('getPortfolio'));

    final repository =
        File(p.join(root, 'lib/repositories/portfolio_repository.dart'))
            .readAsStringSync();
    expect(repository, contains('PortfolioService'));
    expect(repository, contains('getPortfolio'));

    final bloc =
        File(p.join(root, 'lib/bloc/portfolio_bloc.dart')).readAsStringSync();
    expect(bloc, contains('PortfolioRepository'));

    final router =
        File(p.join(root, 'lib/router/app_router.dart')).readAsStringSync();
    expect(router, contains('PortfolioScreen'));
    expect(router, contains('DashboardScreen'));
    expect(router, contains('StockDetailsScreen'));
    expect(router, contains('GoRouter'));
    expect(router, contains('MaterialPageRoute'));
  });

  test('shop Flutter fixture keeps a ChangeNotifier pages chain on disk', () {
    final root = p.join('test', 'fixtures', 'shop_flutter_app');
    final requiredPaths = [
      'lib/services/catalog_service.dart',
      'lib/repositories/catalog_repository.dart',
      'lib/providers/catalog_controller.dart',
      'lib/pages/catalog_page.dart',
      'lib/pages/cart_page.dart',
      'lib/router/app_router.dart',
      'test/catalog_controller_test.dart',
    ];

    for (final relative in requiredPaths) {
      expect(
        File(p.join(root, relative)).existsSync(),
        isTrue,
        reason: 'missing $relative',
      );
    }

    final service = File(p.join(root, 'lib/services/catalog_service.dart'))
        .readAsStringSync();
    expect(service, contains('fetchItems'));

    final controller =
        File(p.join(root, 'lib/providers/catalog_controller.dart'))
            .readAsStringSync();
    expect(controller, contains('ChangeNotifier'));
    expect(controller, contains('CatalogRepository'));

    final catalogPage =
        File(p.join(root, 'lib/pages/catalog_page.dart')).readAsStringSync();
    expect(catalogPage, contains('Consumer<CatalogController>'));

    final cartPage =
        File(p.join(root, 'lib/pages/cart_page.dart')).readAsStringSync();
    expect(cartPage, contains('watch<CatalogController>'));

    final router =
        File(p.join(root, 'lib/router/app_router.dart')).readAsStringSync();
    expect(router, contains('CatalogPage'));
    expect(router, contains('CartPage'));
    expect(router, contains('GoRouter'));
    expect(router, contains('MaterialPageRoute'));
  });
}
