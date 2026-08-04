import '../models/holding.dart';

class PortfolioService {
  Future<List<Holding>> getPortfolio() async {
    return const [
      Holding(symbol: 'AAPL', shares: 10),
      Holding(symbol: 'GOOG', shares: 5),
    ];
  }
}
