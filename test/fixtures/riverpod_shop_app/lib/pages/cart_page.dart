import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/catalog_notifier.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(catalogProvider).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Center(child: Text('Items available: $count')),
    );
  }
}
