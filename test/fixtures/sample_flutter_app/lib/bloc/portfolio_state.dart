import 'package:equatable/equatable.dart';

import '../models/holding.dart';

sealed class PortfolioState extends Equatable {
  const PortfolioState();

  @override
  List<Object?> get props => [];
}

final class PortfolioInitial extends PortfolioState {
  const PortfolioInitial();
}

final class PortfolioLoading extends PortfolioState {
  const PortfolioLoading();
}

final class PortfolioLoaded extends PortfolioState {
  const PortfolioLoaded(this.holdings);

  final List<Holding> holdings;

  @override
  List<Object?> get props => [holdings];
}

final class PortfolioFailure extends PortfolioState {
  const PortfolioFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
