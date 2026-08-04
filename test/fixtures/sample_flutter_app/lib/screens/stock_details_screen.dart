import 'package:flutter/material.dart';

import '../repositories/portfolio_repository.dart';

class StockDetailsScreen extends StatelessWidget {
  const StockDetailsScreen({
    super.key,
    required this.symbol,
    required this.repository,
  });

  final String symbol;
  final PortfolioRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(symbol)),
      body: FutureBuilder(
        future: repository.fetchHoldings(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final holding = snapshot.data!.where((h) => h.symbol == symbol);
          final shares = holding.isEmpty ? 0.0 : holding.first.shares;
          return Center(child: Text('$symbol: $shares shares'));
        },
      ),
    );
  }
}
