import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/catalog_controller.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CatalogController>().items.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Center(child: Text('Items available: $count')),
    );
  }
}
