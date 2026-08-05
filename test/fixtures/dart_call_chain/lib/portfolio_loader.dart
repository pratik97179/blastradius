import 'repositories/portfolio_repository.dart';

class PortfolioLoader {
  PortfolioLoader(this.repository);

  final PortfolioRepository repository;

  Future<List<String>> load() {
    return repository.fetchHoldings();
  }
}
