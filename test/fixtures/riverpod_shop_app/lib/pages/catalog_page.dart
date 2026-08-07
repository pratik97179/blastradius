import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/catalog_notifier.dart';

class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(catalogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Catalog')),
      body: ListView(
        children: [
          for (final item in items) ListTile(title: Text(item)),
        ],
      ),
    );
  }
}
