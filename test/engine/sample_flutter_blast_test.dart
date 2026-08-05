import 'package:blastradius/src/analyzer/analysis_pipeline.dart';
import 'package:blastradius/src/analyzer/project_analyzer.dart';
import 'package:blastradius/src/engine/blast_radius_engine.dart';
import 'package:blastradius/src/engine/symbol_resolver.dart';
import 'package:blastradius/src/graph/edge.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final root = p.join('test', 'fixtures', 'sample_flutter_app');

  test('BlocBuilder type usage links DashboardScreen into getPortfolio blast',
      () async {
    final context = ProjectAnalyzer().discover(root);
    final snapshot = await AnalysisPipeline().run(context);

    expect(
      snapshot.ast.typeUsages.any(
        (usage) =>
            usage.fromClass == 'DashboardScreen' &&
            usage.targetTypeName == 'PortfolioBloc',
      ),
      isTrue,
    );

    final dashboard = snapshot.graph.nodes.values.firstWhere(
      (node) => !node.isMethod && node.name == 'DashboardScreen',
    );
    final bloc = snapshot.graph.nodes.values.firstWhere(
      (node) => !node.isMethod && node.name == 'PortfolioBloc',
    );
    expect(
      snapshot.graph.dependenciesOf(dashboard.id).any(
            (edge) =>
                edge.toId == bloc.id && edge.kind == EdgeKind.uses,
          ),
      isTrue,
    );

    final seeds = SymbolResolver().resolveMethod(
      snapshot.graph,
      methodName: 'getPortfolio',
    );
    final result = BlastRadiusEngine().trace(
      graph: snapshot.graph,
      seeds: seeds,
      candidateTestFiles: context.dartFiles
          .where((f) => f.endsWith('_test.dart'))
          .toList(growable: false),
    );

    expect(result.screens, contains('DashboardScreen'));
    expect(result.screens, contains('PortfolioScreen'));
    expect(result.screens, contains('StockDetailsScreen'));
    expect(result.stateManagers, contains('PortfolioBloc'));
  });
}
