import 'dart:io';

import 'package:blastradius/src/analyzer/analysis_pipeline.dart';
import 'package:blastradius/src/analyzer/project_analyzer.dart';
import 'package:blastradius/src/engine/blast_radius_engine.dart';
import 'package:blastradius/src/engine/symbol_resolver.dart';
import 'package:blastradius/src/graph/edge.dart';
import 'package:blastradius/src/model/node_kind.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final root = p.join('test', 'fixtures', 'riverpod_shop_app');

  setUpAll(() async {
    final result = await Process.run(
      'dart',
      ['pub', 'get'],
      workingDirectory: root,
    );
    expect(result.exitCode, 0, reason: '${result.stderr}');
  });

  test('Riverpod Notifier chain links pages into fetchItems blast', () async {
    final context = ProjectAnalyzer().discover(root);
    expect(context.isFlutter, isTrue);

    final snapshot = await AnalysisPipeline().run(context);

    final byName = {
      for (final item in snapshot.classified) item.name: item.kind,
    };
    expect(byName['CatalogService'], NodeKind.service);
    expect(byName['CatalogRepository'], NodeKind.repository);
    expect(byName['CatalogNotifier'], NodeKind.provider);
    expect(byName['CatalogPage'], NodeKind.screen);
    expect(byName['CartPage'], NodeKind.screen);

    expect(
      snapshot.ast.typeUsages.any(
        (usage) =>
            usage.fromClass == 'CatalogPage' &&
            usage.targetTypeName == 'CatalogNotifier',
      ),
      isTrue,
    );
    expect(
      snapshot.ast.typeUsages.any(
        (usage) =>
            usage.fromClass == 'CartPage' &&
            usage.targetTypeName == 'CatalogNotifier',
      ),
      isTrue,
    );

    final catalogPage = snapshot.graph.nodes.values.firstWhere(
      (node) => !node.isMethod && node.name == 'CatalogPage',
    );
    final notifier = snapshot.graph.nodes.values.firstWhere(
      (node) => !node.isMethod && node.name == 'CatalogNotifier',
    );
    expect(
      snapshot.graph.dependenciesOf(catalogPage.id).any(
            (edge) => edge.toId == notifier.id && edge.kind == EdgeKind.uses,
          ),
      isTrue,
    );

    final seeds = SymbolResolver().resolveMethod(
      snapshot.graph,
      methodName: 'fetchItems',
    );
    final result = BlastRadiusEngine()
        .trace(
          graph: snapshot.graph,
          seeds: seeds,
          candidateTestFiles: context.dartFiles
              .where((f) => f.endsWith('_test.dart'))
              .toList(growable: false),
        )
        .result;

    expect(result.changed, contains('CatalogService.fetchItems'));
    expect(result.repositories, contains('CatalogRepository'));
    expect(result.stateManagers, contains('CatalogNotifier'));
    expect(result.screens, containsAll(['CatalogPage', 'CartPage']));
    expect(result.suggestedTests, contains('catalog_notifier_test'));
  });
}
