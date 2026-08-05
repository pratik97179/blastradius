import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/catalog_controller.dart';
import 'repositories/catalog_repository.dart';
import 'router/app_router.dart';
import 'services/catalog_service.dart';

void main() {
  final service = CatalogService();
  final repository = CatalogRepository(service);
  final controller = CatalogController(repository);
  runApp(ShopApp(controller: controller));
}

class ShopApp extends StatelessWidget {
  const ShopApp({super.key, required this.controller});

  final CatalogController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CatalogController>.value(
      value: controller,
      child: MaterialApp.router(
        title: 'Shop Flutter App',
        routerConfig: createShopRouter(),
      ),
    );
  }
}
