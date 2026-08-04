import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'bloc/portfolio_bloc.dart';
import 'bloc/portfolio_event.dart';
import 'repositories/portfolio_repository.dart';
import 'router/app_router.dart';
import 'services/portfolio_service.dart';

void main() {
  final service = PortfolioService();
  final repository = PortfolioRepository(service);

  runApp(
    MultiProvider(
      providers: [
        Provider<PortfolioService>.value(value: service),
        Provider<PortfolioRepository>.value(value: repository),
        BlocProvider(
          create: (_) => PortfolioBloc(repository)..add(const PortfolioStarted()),
        ),
      ],
      child: SampleApp(repository: repository),
    ),
  );
}

class SampleApp extends StatelessWidget {
  const SampleApp({super.key, required this.repository});

  final PortfolioRepository repository;

  @override
  Widget build(BuildContext context) {
    final router = createAppRouter(repository);
    return MaterialApp.router(
      title: 'Sample Flutter App',
      routerConfig: router,
    );
  }
}
