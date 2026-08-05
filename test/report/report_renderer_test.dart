import 'dart:convert';

import 'package:blastradius/src/model/blast_result.dart';
import 'package:blastradius/src/report/report_renderer.dart';
import 'package:test/test.dart';

void main() {
  final result = BlastResult(
    changed: const ['PortfolioService.getPortfolio'],
    changedFiles: const ['lib/services/portfolio_service.dart'],
    repositories: const ['PortfolioRepository'],
    services: const [],
    stateManagers: const ['PortfolioBloc'],
    screens: const ['PortfolioScreen', 'StockDetailsScreen'],
    widgets: const [],
    suggestedTests: const ['portfolio_bloc_test'],
    risk: RiskLevel.medium,
    confidence: 0.91,
  );

  final renderer = ReportRenderer();

  test('renders console report with key sections', () {
    final text = renderer.render(result, 'console');
    expect(text, contains('BlastRadius'));
    expect(text, contains('PortfolioService.getPortfolio'));
    expect(text, contains('PortfolioScreen'));
    expect(text, contains('MEDIUM'));
    expect(text, contains('91%'));
  });

  test('renders valid JSON report', () {
    final text = renderer.render(result, 'json');
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    expect(decoded['risk'], 'MEDIUM');
    expect(decoded['confidencePercent'], 91);
    expect(
      (decoded['affected'] as Map<String, dynamic>)['screens'],
      contains('PortfolioScreen'),
    );
    expect(decoded['changedFiles'], contains('lib/services/portfolio_service.dart'));
  });

  test('renders markdown report with checklist items', () {
    final text = renderer.render(result, 'md');
    expect(text, contains('# BlastRadius'));
    expect(text, contains('## Affected Screens'));
    expect(text, contains('- [x] PortfolioScreen'));
    expect(text, contains('## Risk'));
    expect(text, contains('MEDIUM'));
  });
}
