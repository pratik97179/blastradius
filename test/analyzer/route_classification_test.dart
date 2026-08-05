import 'dart:io';

import 'package:blastradius/src/analyzer/analysis_pipeline.dart';
import 'package:blastradius/src/analyzer/ast_extractor.dart';
import 'package:blastradius/src/analyzer/project_analyzer.dart';
import 'package:blastradius/src/model/node_kind.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final root = p.normalize(
    p.absolute(p.join('test', 'fixtures', 'sample_flutter_app')),
  );

  setUpAll(() async {
    final result = await Process.run(
      'dart',
      ['pub', 'get'],
      workingDirectory: root,
    );
    expect(result.exitCode, 0, reason: '${result.stderr}');
  });

  test('extracts GoRoute and MaterialPageRoute destination widgets', () async {
    final context = ProjectAnalyzer().discover(root);
    final ast = await AstExtractor().extract(context);

    expect(
      ast.routeDestinationNames,
      containsAll([
        'DashboardScreen',
        'PortfolioScreen',
        'StockDetailsScreen',
      ]),
    );
  });

  test('classifies routed widgets as screens via structural signals', () async {
    final context = ProjectAnalyzer().discover(root);
    final snapshot = await AnalysisPipeline().run(context);
    final byName = {
      for (final item in snapshot.classified) item.name: item.kind,
    };

    expect(byName['DashboardScreen'], NodeKind.screen);
    expect(byName['PortfolioScreen'], NodeKind.screen);
    expect(byName['StockDetailsScreen'], NodeKind.screen);
    expect(byName['PortfolioBloc'], NodeKind.bloc);
    expect(byName['PortfolioRepository'], NodeKind.repository);
    expect(byName['PortfolioService'], NodeKind.service);
  });
}
