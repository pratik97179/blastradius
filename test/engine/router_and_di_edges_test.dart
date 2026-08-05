import 'package:blastradius/src/analyzer/analysis_pipeline.dart';
import 'package:blastradius/src/analyzer/project_analyzer.dart';
import 'package:blastradius/src/graph/edge.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final root = p.join('test', 'fixtures', 'sample_flutter_app');
  late AnalysisSnapshot snapshot;

  setUpAll(() async {
    final context = ProjectAnalyzer().discover(root);
    snapshot = await AnalysisPipeline().run(context);
  });

  test('top-level router function records call edges to screens', () {
    final router = snapshot.graph.findMethod(methodName: 'createAppRouter');
    expect(router, isNotNull);

    final targets = snapshot.graph
        .dependenciesOf(router!.id)
        .where((edge) => edge.kind == EdgeKind.calls)
        .map((edge) => snapshot.graph.nodeById(edge.toId)?.name)
        .whereType<String>()
        .toSet();

    expect(
      targets,
      containsAll(['DashboardScreen', 'PortfolioScreen', 'StockDetailsScreen']),
    );
  });

  test('field and constructor types create DI uses edges', () {
    final bloc = snapshot.graph.nodes.values.firstWhere(
      (node) => !node.isMethod && node.name == 'PortfolioBloc',
    );
    final repository = snapshot.graph.nodes.values.firstWhere(
      (node) => !node.isMethod && node.name == 'PortfolioRepository',
    );
    final service = snapshot.graph.nodes.values.firstWhere(
      (node) => !node.isMethod && node.name == 'PortfolioService',
    );

    expect(
      snapshot.graph.dependenciesOf(bloc.id).any(
            (edge) =>
                edge.toId == repository.id && edge.kind == EdgeKind.uses,
          ),
      isTrue,
    );
    expect(
      snapshot.graph.dependenciesOf(repository.id).any(
            (edge) => edge.toId == service.id && edge.kind == EdgeKind.uses,
          ),
      isTrue,
    );
  });
}
