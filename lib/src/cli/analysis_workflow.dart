import '../analyzer/analysis_pipeline.dart';
import '../analyzer/ast_extractor.dart';
import '../diff/diff_symbol_mapper.dart';
import '../diff/git_diff_parser.dart';
import '../engine/blast_radius_engine.dart';
import '../engine/symbol_resolver.dart';
import '../graph/node.dart';
import '../model/blast_trace.dart';
import '../model/project_context.dart';
import '../utils/logger.dart';
import 'exit_codes.dart';
import 'package_paths.dart';

export '../analyzer/analysis_pipeline.dart' show AnalysisSnapshot;

class DiffWorkflowResult {
  const DiffWorkflowResult({
    required this.snapshot,
    required this.trace,
    required this.changedFiles,
  });

  final AnalysisSnapshot snapshot;
  final BlastTrace trace;
  final List<String> changedFiles;
}

class AnalysisWorkflow {
  AnalysisWorkflow({
    AnalysisPipeline? pipeline,
    BlastRadiusEngine? engine,
    DiffSymbolMapper? diffMapper,
    GitDiffParser? diffParser,
    Logger? logger,
  })  : _pipeline = pipeline ?? AnalysisPipeline(logger: logger),
        _engine = engine ?? BlastRadiusEngine(),
        _diffMapper = diffMapper ?? DiffSymbolMapper(),
        _diffParser = diffParser ?? GitDiffParser();

  final AnalysisPipeline _pipeline;
  final BlastRadiusEngine _engine;
  final DiffSymbolMapper _diffMapper;
  final GitDiffParser _diffParser;

  Future<AnalysisSnapshot> runPipeline(ProjectContext context) {
    return _pipeline.run(context);
  }

  List<String> testCandidates(ProjectContext context) {
    return context.dartFiles
        .where((f) => f.endsWith('_test.dart'))
        .toList(growable: false);
  }

  Future<BlastTrace> runTrace({
    required ProjectContext context,
    required List<GraphNode> Function(AnalysisSnapshot snapshot) resolveSeeds,
  }) async {
    final snapshot = await runPipeline(context);
    final seeds = resolveSeeds(snapshot);
    return _engine.trace(
      graph: snapshot.graph,
      seeds: seeds,
      candidateTestFiles: testCandidates(context),
    );
  }

  Future<({AnalysisSnapshot snapshot, BlastTrace trace})> runTraceWithSnapshot({
    required ProjectContext context,
    required List<GraphNode> Function(AnalysisSnapshot snapshot) resolveSeeds,
  }) async {
    final snapshot = await runPipeline(context);
    final seeds = resolveSeeds(snapshot);
    final trace = _engine.trace(
      graph: snapshot.graph,
      seeds: seeds,
      candidateTestFiles: testCandidates(context),
    );
    return (snapshot: snapshot, trace: trace);
  }

  Future<DiffWorkflowResult> runDiff({
    required ProjectContext context,
    required String base,
  }) async {
    final hunks = await _diffParser.collectHunks(
      projectRoot: context.rootPath,
      base: base,
    );
    final snapshot = await runPipeline(context);
    final seeds = _diffMapper.mapToSeeds(
      ast: snapshot.ast,
      graph: snapshot.graph,
      hunks: hunks,
      projectRoot: context.rootPath,
    );
    final changedFiles = hunks.map((h) => h.relativePath).toSet().toList()
      ..sort();
    final traced = _engine.trace(
      graph: snapshot.graph,
      seeds: seeds,
      candidateTestFiles: testCandidates(context),
    );
    return DiffWorkflowResult(
      snapshot: snapshot,
      trace: BlastTrace(
        result: traced.result.withChangedFiles(changedFiles),
        seedIds: traced.seedIds,
        scoresByNodeId: traced.scoresByNodeId,
      ),
      changedFiles: changedFiles,
    );
  }
}

/// Maps workflow failures to CLI exit codes. Returns null if not handled.
int? exitCodeForAnalysisError(Object error) {
  if (error is AstExtractionException ||
      error is GitDiffException ||
      error is PackagePathsException) {
    return ExitCodes.projectError;
  }
  if (error is SymbolResolutionException) {
    return ExitCodes.usageError;
  }
  return null;
}
