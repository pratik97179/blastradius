import 'package:equatable/equatable.dart';

sealed class PortfolioEvent extends Equatable {
  const PortfolioEvent();

  @override
  List<Object?> get props => [];
}

final class PortfolioStarted extends PortfolioEvent {
  const PortfolioStarted();
}
