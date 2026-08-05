import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../analyzer/analysis_pipeline.dart';
import '../analyzer/ast_extractor.dart';
import '../diff/blast_result_merger.dart';
import '../diff/diff_symbol_mapper.dart';
import '../diff/git_diff_parser.dart';
import '../engine/blast_radius_engine.dart';
import '../engine/symbol_resolver.dart';
import '../graph/node.dart';
import '../model/blast_result.dart';
import '../model/blast_trace.dart';
import '../model/project_context.dart';
import '../report/visual_payload.dart';
import 'commands.dart';
import 'exit_codes.dart';
import 'package_paths.dart';
import 'view_server.dart';

void addDashboardOptions(ArgParser parser) {
  parser.addOption(
    'port',
    defaultsTo: '7423',
    help: 'Local port for the dashboard server.',
    valueHelp: 'port',
  );
  parser.addFlag(
    'open',
    defaultsTo: true,
    negatable: true,
    help: 'Open the dashboard in the default browser.',
  );
  parser.addOption(
    'export',
    help: 'Write an offline dashboard folder instead of serving.',
    valueHelp: 'dir',
  );
}

class ViewCommand extends Command<int> {
  ViewCommand() {
    addSubcommand(ViewMethodCommand());
    addSubcommand(ViewFileCommand());
    addSubcommand(ViewClassCommand());
    addSubcommand(ViewDiffCommand());
    addSubcommand(ViewGraphCommand());
  }

  @override
  String get name => 'view';

  @override
  String get description =>
      'Open an interactive blast-radius dashboard in the browser.';

  @override
  Future<int> run() async {
    stdout.writeln(usage);
    return ExitCodes.usageError;
  }
}

class ViewMethodCommand extends Command<int> with GlobalOptions {
  ViewMethodCommand() {
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'Disambiguate the method by source file path.',
      valueHelp: 'path',
    );
    addDashboardOptions(argParser);
  }

  @override
  String get name => 'method';

  @override
  String get description => 'Visualize blast radius for a method name.';

  @override
  String get invocation => 'blastradius view method <name> [arguments]';

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
    return ViewLauncher(this).runTraceView(
      context: context,
      resolveSeeds: (snapshot) => SymbolResolver().resolveMethod(
        snapshot.graph,
        methodName: methodName,
        filePath: file,
        projectRoot: context.rootPath,
      ),
    );
  }
}

class ViewFileCommand extends Command<int> with GlobalOptions {
  ViewFileCommand() {
    addDashboardOptions(argParser);
  }

  @override
  String get name => 'file';

  @override
  String get description => 'Visualize blast radius for a Dart source file.';

  @override
  String get invocation => 'blastradius view file <path> [arguments]';

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
    return ViewLauncher(this).runTraceView(
      context: context,
      resolveSeeds: (snapshot) => SymbolResolver().resolveFile(
        snapshot.graph,
        filePath: filePath,
        projectRoot: context.rootPath,
      ),
    );
  }
}

class ViewClassCommand extends Command<int> with GlobalOptions {
  ViewClassCommand() {
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'Disambiguate the class by source file path.',
      valueHelp: 'path',
    );
    addDashboardOptions(argParser);
  }

  @override
  String get name => 'class';

  @override
  String get description => 'Visualize blast radius for a class name.';

  @override
  String get invocation => 'blastradius view class <name> [arguments]';

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
    return ViewLauncher(this).runTraceView(
      context: context,
      resolveSeeds: (snapshot) => SymbolResolver().resolveClass(
        snapshot.graph,
        className: className,
        filePath: file,
        projectRoot: context.rootPath,
      ),
    );
  }
}

class ViewDiffCommand extends Command<int> with GlobalOptions {
  ViewDiffCommand() {
    argParser.addOption(
      'base',
      defaultsTo: 'HEAD',
      help: 'Git revision to diff against (working tree vs base).',
      valueHelp: 'ref',
    );
    addDashboardOptions(argParser);
  }

  @override
  String get name => 'diff';

  @override
  String get description =>
      'Visualize blast radius for changes in the git working tree.';

  @override
  Future<int> run() async {
    final context = discoverProject();
    if (context == null) {
      return ExitCodes.projectError;
    }

    final base = argResults!['base'] as String;
    final launcher = ViewLauncher(this);
    try {
      final hunks = await GitDiffParser().collectHunks(
        projectRoot: context.rootPath,
        base: base,
      );
      final snapshot = await AnalysisPipeline().run(context);
      final seeds = DiffSymbolMapper().mapToSeeds(
        ast: snapshot.ast,
        graph: snapshot.graph,
        hunks: hunks,
        projectRoot: context.rootPath,
      );
      final changedFiles = hunks.map((h) => h.relativePath).toSet().toList()
        ..sort();

      final BlastTrace blastTrace;
      if (seeds.isEmpty) {
        blastTrace = BlastTrace(
          result: BlastResultMerger().merge(
            const [],
            changedFiles: changedFiles,
          ),
          seedIds: const {},
          scoresByNodeId: const {},
        );
      } else {
        final traced = BlastRadiusEngine().trace(
          graph: snapshot.graph,
          seeds: seeds,
          candidateTestFiles: context.dartFiles
              .where((f) => f.endsWith('_test.dart'))
              .toList(growable: false),
        );
        blastTrace = BlastTrace(
          result: BlastResult(
            changed: traced.result.changed,
            changedFiles: changedFiles,
            repositories: traced.result.repositories,
            stateManagers: traced.result.stateManagers,
            screens: traced.result.screens,
            widgets: traced.result.widgets,
            services: traced.result.services,
            suggestedTests: traced.result.suggestedTests,
            risk: traced.result.risk,
            confidence: traced.result.confidence,
          ),
          seedIds: traced.seedIds,
          scoresByNodeId: traced.scoresByNodeId,
        );
      }

      final payload = VisualPayload.fromTrace(
        context: context,
        graph: snapshot.graph,
        trace: blastTrace,
        command: 'diff',
      );
      return launcher.deliver(payload);
    } on GitDiffException catch (e) {
      logger.error(e.message);
      return ExitCodes.projectError;
    } on AstExtractionException catch (e) {
      logger.error(e.message);
      return ExitCodes.projectError;
    } on PackagePathsException catch (e) {
      logger.error(e.message);
      return ExitCodes.projectError;
    }
  }
}

class ViewGraphCommand extends Command<int> with GlobalOptions {
  ViewGraphCommand() {
    addDashboardOptions(argParser);
  }

  @override
  String get name => 'graph';

  @override
  String get description =>
      'Visualize the full dependency graph (analyze-style map).';

  @override
  Future<int> run() async {
    final context = discoverProject();
    if (context == null) {
      return ExitCodes.projectError;
    }

    final launcher = ViewLauncher(this);
    try {
      final snapshot = await AnalysisPipeline().run(context);
      final payload = VisualPayload.fromFullGraph(
        context: context,
        graph: snapshot.graph,
        command: 'analyze',
      );
      return launcher.deliver(payload);
    } on AstExtractionException catch (e) {
      logger.error(e.message);
      return ExitCodes.projectError;
    } on PackagePathsException catch (e) {
      logger.error(e.message);
      return ExitCodes.projectError;
    }
  }
}

class ViewLauncher {
  ViewLauncher(this.command);

  final Command<int> command;

  Future<int> runTraceView({
    required ProjectContext context,
    required List<GraphNode> Function(AnalysisSnapshot snapshot) resolveSeeds,
  }) async {
    final logger = (command as GlobalOptions).logger;
    try {
      final snapshot = await AnalysisPipeline().run(context);
      final seeds = resolveSeeds(snapshot);
      final trace = BlastRadiusEngine().trace(
        graph: snapshot.graph,
        seeds: seeds,
        candidateTestFiles: context.dartFiles
            .where((f) => f.endsWith('_test.dart'))
            .toList(growable: false),
      );
      final payload = VisualPayload.fromTrace(
        context: context,
        graph: snapshot.graph,
        trace: trace,
        command: 'trace',
      );
      return deliver(payload);
    } on AstExtractionException catch (e) {
      logger.error(e.message);
      return ExitCodes.projectError;
    } on SymbolResolutionException catch (e) {
      logger.error(e.message);
      return ExitCodes.usageError;
    } on PackagePathsException catch (e) {
      logger.error(e.message);
      return ExitCodes.projectError;
    }
  }

  Future<int> deliver(VisualPayload payload) async {
    final logger = (command as GlobalOptions).logger;
    final results = command.argResults!;
    final exportPath = results['export'] as String?;
    final dist = PackagePaths.dashboardDist();
    final json = payload.toJson();

    if (exportPath != null && exportPath.isNotEmpty) {
      final dir = await exportDashboard(
        distDir: dist,
        payloadJson: json,
        exportPath: exportPath,
      );
      logger.info('Exported dashboard to ${dir.path}');
      logger.info('Open ${p.join(dir.path, 'index.html')} in a browser.');
      return ExitCodes.success;
    }

    final port = _readPort(results['port'] as String);
    final session = await ViewServer(
      distDir: dist,
      payloadJson: json,
    ).start(port: port);

    logger.info('BlastRadius dashboard: ${session.url}');
    if (results['open'] == true) {
      await openBrowser(session.url);
    }
    logger.info('Press Ctrl+C to stop.');

    final stop = Completer<void>();
    ProcessSignal.sigint.watch().listen((_) {
      if (!stop.isCompleted) {
        stop.complete();
      }
    });
    await stop.future;
    await session.close();
    return ExitCodes.success;
  }

  int _readPort(String raw) {
    final port = int.tryParse(raw);
    if (port == null || port <= 0 || port > 65535) {
      throw UsageException('Invalid --port value: $raw', command.usage);
    }
    return port;
  }
}
