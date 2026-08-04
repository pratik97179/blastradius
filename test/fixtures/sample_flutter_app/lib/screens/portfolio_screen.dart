import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../bloc/portfolio_bloc.dart';
import '../bloc/portfolio_event.dart';
import '../bloc/portfolio_state.dart';
import '../repositories/portfolio_repository.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PortfolioBloc(context.read<PortfolioRepository>())
        ..add(const PortfolioStarted()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Portfolio')),
        body: BlocBuilder<PortfolioBloc, PortfolioState>(
          builder: (context, state) {
            if (state is PortfolioLoading || state is PortfolioInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PortfolioFailure) {
              return Center(child: Text(state.message));
            }
            final loaded = state as PortfolioLoaded;
            return ListView.builder(
              itemCount: loaded.holdings.length,
              itemBuilder: (context, index) {
                final holding = loaded.holdings[index];
                return ListTile(
                  title: Text(holding.symbol),
                  subtitle: Text('${holding.shares} shares'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
