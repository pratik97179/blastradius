import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../repositories/portfolio_repository.dart';
import '../screens/dashboard_screen.dart';
import '../screens/portfolio_screen.dart';
import '../screens/stock_details_screen.dart';

GoRouter createAppRouter(PortfolioRepository repository) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/portfolio',
        name: 'portfolio',
        builder: (context, state) => const PortfolioScreen(),
      ),
      GoRoute(
        path: '/stocks/:symbol',
        name: 'stockDetails',
        builder: (context, state) {
          final symbol = state.pathParameters['symbol'] ?? '';
          return StockDetailsScreen(symbol: symbol, repository: repository);
        },
      ),
    ],
  );
}

class LegacyPortfolioRoute {
  static Route<void> material(PortfolioRepository repository) {
    return MaterialPageRoute<void>(
      builder: (_) => StockDetailsScreen(
        symbol: 'AAPL',
        repository: repository,
      ),
    );
  }
}
