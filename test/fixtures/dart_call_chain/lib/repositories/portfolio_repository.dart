import '../services/portfolio_service.dart';

class PortfolioRepository {
  PortfolioRepository(this.service);

  final PortfolioService service;

  Future<List<String>> fetchHoldings() {
    return service.getPortfolio();
  }
}
