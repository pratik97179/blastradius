import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/catalog_controller.dart';

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catalog')),
      body: Consumer<CatalogController>(
        builder: (context, controller, _) {
          if (controller.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [
              for (final item in controller.items) ListTile(title: Text(item)),
            ],
          );
        },
      ),
    );
  }
}
