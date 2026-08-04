import '../models/holding.dart';
import '../services/portfolio_service.dart';

class PortfolioRepository {
  PortfolioRepository(this._service);

  final PortfolioService _service;

  Future<List<Holding>> fetchHoldings() => _service.getPortfolio();
}
