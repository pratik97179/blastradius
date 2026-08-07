import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../analyzer/ast_extractor.dart';
import '../analyzer/classifiers.dart';
import '../engine/symbol_resolver.dart';
import '../graph/edge.dart';
import '../graph/node.dart';
import '../model/node_kind.dart';
import '../model/project_context.dart';
import '../report/report_renderer.dart';
import 'analysis_workflow.dart';
import 'cli_options.dart';
import 'exit_codes.dart';
import 'global_options.dart';
import 'view_commands.dart';

const String packageVersion = '0.3.3';

Future<int> runBlastRadius(List<String> args) async {
  final runner = BlastRadiusCommandRunner();
  try {
    return await runner.run(args);
  } on UsageException catch (e) {
    stderr.writeln(e.message);
    if (e.usage.isNotEmpty) {
      stderr.writeln();
      stderr.writeln(e.usage);
    }
    return ExitCodes.usageError;
  }
}

class BlastRadiusCommandRunner extends CommandRunner<int> {
  BlastRadiusCommandRunner()
      : super(
          'blastradius',
          'Know your blast radius before you commit.\n'
              'Static impact analysis for Dart and Flutter packages.',
        ) {
    argParser.addFlag(
      'version',
      abbr: 'V',
      negatable: false,
      help: 'Print the BlastRadius version.',
    );
    argParser.addOption(
      'project',
      abbr: 'p',
      help:
          'Path to the Dart or Flutter package root (defaults to the current directory).',
      valueHelp: 'path',
    );
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Enable verbose logging.',
    );

    addCommand(TraceCommand());
    addCommand(DiffCommand());
    addCommand(AnalyzeCommand());
    addCommand(ViewCommand());
  }

  @override
  Future<int> run(Iterable<String> args) async {
    final argResults = parse(args);
    if (argResults['version'] == true) {
      stdout.writeln('blastradius $packageVersion');
      return ExitCodes.success;
    }

    if (argResults.command == null &&
        (argResults.rest.isEmpty || argResults['help'] == true)) {
      stdout.write(usage);
      return ExitCodes.success;
    }

    return await runCommand(argResults) ?? ExitCodes.success;
  }
}

mixin TraceReportOptions on GlobalOptions {
  Future<int> runTraceReport({
    required ProjectContext context,
    required List<GraphNode> Function(AnalysisSnapshot snapshot) resolveSeeds,
    required String format,
  }) async {
    try {
      final trace = await AnalysisWorkflow(logger: logger).runTrace(
        context: context,
        resolveSeeds: resolveSeeds,
      );
      logger.info(ReportRenderer().render(trace.result, format));
      return ExitCodes.success;
    } on Object catch (e) {
      final code = exitCodeForAnalysisError(e);
      if (code != null) {
        logger.error(e.toString());
        return code;
      }
      rethrow;
    }
  }
}

class TraceCommand extends Command<int> with GlobalOptions {
  TraceCommand() {
    addSubcommand(TraceMethodCommand());
    addSubcommand(TraceFileCommand());
    addSubcommand(TraceClassCommand());
  }

  @override
  String get name => 'trace';

  @override
  String get description =>
      'Trace the blast radius of a method, file, or class.';

  @override
  Future<int> run() async {
    stdout.writeln(usage);
    return ExitCodes.usageError;
  }
}

class TraceMethodCommand extends Command<int>
    with GlobalOptions, TraceReportOptions {
  TraceMethodCommand() {
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'Disambiguate the method by source file path.',
      valueHelp: 'path',
    );
    addReportFormatOption(argParser);
  }

  @override
  String get name => 'method';

  @override
  String get description => 'Trace blast radius for a method name.';

  @override
  String get invocation => 'blastradius trace method <name> [arguments]';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      throw UsageException('Missing method name.', usage);
    }
    final context = discoverProject();
    if (context == null) {
      return ExitCodes.projectError;
    }

    final methodName = argResults!.rest.first;
    final file = argResults!['file'] as String?;
    final format = argResults!['format'] as String;

    return runTraceReport(
      context: context,
      format: format,
      resolveSeeds: (snapshot) => SymbolResolver().resolveMethod(
        snapshot.graph,
        methodName: methodName,
        filePath: file,
        projectRoot: context.rootPath,
      ),
    );
  }
}

class TraceFileCommand extends Command<int>
    with GlobalOptions, TraceReportOptions {
  TraceFileCommand() {
    addReportFormatOption(argParser);
  }

  @override
  String get name => 'file';

  @override
  String get description => 'Trace blast radius for a Dart source file.';

  @override
  String get invocation => 'blastradius trace file <path> [arguments]';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      throw UsageException('Missing file path.', usage);
    }
    final context = discoverProject();
    if (context == null) {
      return ExitCodes.projectError;
    }

    final filePath = argResults!.rest.first;
    final format = argResults!['format'] as String;

    return runTraceReport(
      context: context,
      format: format,
      resolveSeeds: (snapshot) => SymbolResolver().resolveFile(
        snapshot.graph,
        filePath: filePath,
        projectRoot: context.rootPath,
      ),
    );
  }
}

class TraceClassCommand extends Command<int>
    with GlobalOptions, TraceReportOptions {
  TraceClassCommand() {
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'Disambiguate the class by source file path.',
      valueHelp: 'path',
    );
    addReportFormatOption(argParser);
  }

  @override
  String get name => 'class';

  @override
  String get description => 'Trace blast radius for a class name.';

  @override
  String get invocation => 'blastradius trace class <name> [arguments]';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      throw UsageException('Missing class name.', usage);
    }
    final context = discoverProject();
    if (context == null) {
      return ExitCodes.projectError;
    }

    final className = argResults!.rest.first;
    final file = argResults!['file'] as String?;
    final format = argResults!['format'] as String;

    return runTraceReport(
      context: context,
      format: format,
      resolveSeeds: (snapshot) => SymbolResolver().resolveClass(
        snapshot.graph,
        className: className,
        filePath: file,
        projectRoot: context.rootPath,
      ),
    );
  }
}

class DiffCommand extends Command<int> with GlobalOptions {
  DiffCommand() {
    argParser.addOption(
      'base',
      defaultsTo: 'HEAD',
      help: 'Git revision to diff against (working tree vs base).',
      valueHelp: 'ref',
    );
    addReportFormatOption(argParser);
  }

  @override
  String get name => 'diff';

  @override
  String get description =>
      'Trace blast radius for changes in the git working tree.';

  @override
  Future<int> run() async {
    final context = discoverProject();
    if (context == null) {
      return ExitCodes.projectError;
    }

    final base = argResults!['base'] as String;
    final format = argResults!['format'] as String;

    try {
      final result = await AnalysisWorkflow(logger: logger).runDiff(
        context: context,
        base: base,
      );
      logger.info(ReportRenderer().render(result.trace.result, format));
      return ExitCodes.success;
    } on Object catch (e) {
      final code = exitCodeForAnalysisError(e);
      if (code != null) {
        logger.error(e.toString());
        return code;
      }
      rethrow;
    }
  }
}

class AnalyzeCommand extends Command<int> with GlobalOptions {
  @override
  String get name => 'analyze';

  @override
  String get description =>
      'Discover a Dart or Flutter package, extract AST, classify types, and build the dependency graph.';

  @override
  Future<int> run() async {
    final context = discoverProject();
    if (context == null) {
      return ExitCodes.projectError;
    }

    logger.info('BlastRadius $packageVersion');
    logger.info('Project   ${context.rootPath}');
    logger.info('Package   ${context.packageName}');
    logger.info('Platform  ${context.isFlutter ? 'flutter' : 'dart'}');
    logger.info('Pubspec   ${context.pubspecPath}');
    logger.info('Dart files ${context.dartFileCount}');
    if (logger.verbose) {
      for (final file in context.dartFiles) {
        logger.debug(p.relative(file, from: context.rootPath));
      }
    }

    try {
      final snapshot =
          await AnalysisWorkflow(logger: logger).runPipeline(context);
      final kindCounts = ClassClassifier().countByKind(snapshot.classified);
      final graph = snapshot.graph;
      final ast = snapshot.ast;

      logger.info('Classes   ${ast.classes.length}');
      logger.info('Methods   ${ast.methods.length}');
      logger.info(
        'Calls     ${ast.calls.length} (${ast.resolvedCallCount} resolved)',
      );
      logger.info('Graph     ${graph.nodeCount} nodes, ${graph.edgeCount} edges');
      if (ast.unresolvedUnitCount > 0) {
        logger.info(
          'Unresolved units ${ast.unresolvedUnitCount} '
          '(${ast.skippedUnitPaths.length} skipped)',
        );
      }
      logger.info('Kinds');
      for (final kind in NodeKind.values) {
        final count = kindCounts[kind];
        if (count == null || count == 0) {
          continue;
        }
        logger.info('  ${kind.label.padRight(14)} $count');
      }

      if (logger.verbose) {
        for (final item in snapshot.classified) {
          logger.debug('${item.kind.label}: ${item.name}');
        }
        for (final edge in graph.edges.where((e) => e.kind == EdgeKind.calls)) {
          final from = graph.nodeById(edge.fromId)?.displayName ?? edge.fromId;
          final to = graph.nodeById(edge.toId)?.displayName ?? edge.toId;
          logger.debug('edge calls: $from -> $to');
        }
      }
    } on AstExtractionException catch (e) {
      logger.error(e.message);
      return ExitCodes.projectError;
    }

    return ExitCodes.success;
  }
}
