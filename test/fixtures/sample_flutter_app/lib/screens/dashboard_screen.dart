import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/portfolio_bloc.dart';
import '../bloc/portfolio_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: BlocBuilder<PortfolioBloc, PortfolioState>(
        builder: (context, state) {
          final count = state is PortfolioLoaded ? state.holdings.length : 0;
          return Center(child: Text('Holdings: $count'));
        },
      ),
    );
  }
}
