import 'package:flutter_bloc/flutter_bloc.dart';

import '../repositories/portfolio_repository.dart';
import 'portfolio_event.dart';
import 'portfolio_state.dart';

class PortfolioBloc extends Bloc<PortfolioEvent, PortfolioState> {
  PortfolioBloc(this._repository) : super(const PortfolioInitial()) {
    on<PortfolioStarted>(_onStarted);
  }

  final PortfolioRepository _repository;

  Future<void> _onStarted(
    PortfolioStarted event,
    Emitter<PortfolioState> emit,
  ) async {
    emit(const PortfolioLoading());
    try {
      final holdings = await _repository.fetchHoldings();
      emit(PortfolioLoaded(holdings));
    } catch (error) {
      emit(PortfolioFailure(error.toString()));
    }
  }
}
