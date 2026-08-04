import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final root = p.join('test', 'fixtures', 'sample_flutter_app');

  test('portfolio fixture keeps the MVP dependency chain on disk', () {
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
}
