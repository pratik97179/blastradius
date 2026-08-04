import '../graph/graph.dart';
import '../graph/graph_builder.dart';
import '../model/ast_model.dart';
import '../model/project_context.dart';
import 'ast_extractor.dart';
import 'classifiers.dart';

class AnalysisSnapshot {
  const AnalysisSnapshot({
    required this.context,
    required this.ast,
    required this.classified,
    required this.graph,
  });

  final ProjectContext context;
  final AstModel ast;
  final List<ClassifiedClass> classified;
  final DependencyGraph graph;
}

class AnalysisPipeline {
  Future<AnalysisSnapshot> run(ProjectContext context) async {
    final ast = await AstExtractor().extract(context);
    final classified = ClassClassifier().classifyAll(ast.classes);
    final graph = GraphBuilder().build(ast: ast, classified: classified);
    return AnalysisSnapshot(
      context: context,
      ast: ast,
      classified: classified,
      graph: graph,
    );
  }
}
