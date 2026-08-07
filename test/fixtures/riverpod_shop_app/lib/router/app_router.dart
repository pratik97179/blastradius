import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/cart_page.dart';
import '../pages/catalog_page.dart';

GoRouter createShopRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: 'catalog',
        builder: (context, state) => const CatalogPage(),
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartPage(),
      ),
    ],
  );
}

class LegacyCartRoute {
  static Route<void> material() {
    return MaterialPageRoute<void>(
      builder: (_) => const CartPage(),
    );
  }
}
