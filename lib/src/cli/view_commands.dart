import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../engine/symbol_resolver.dart';
import '../graph/node.dart';
import '../model/project_context.dart';
import '../report/visual_payload.dart';
import 'analysis_workflow.dart';
import 'cli_options.dart';
import 'exit_codes.dart';
import 'global_options.dart';
import 'package_paths.dart';
import 'view_server.dart';

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

mixin ViewLauncher on GlobalOptions {
  bool get compactGraph => argResults?['full-graph'] != true;

  Future<int> runTraceView({
    required ProjectContext context,
    required List<GraphNode> Function(AnalysisSnapshot snapshot) resolveSeeds,
    String command = 'trace',
  }) async {
    try {
      final outcome = await AnalysisWorkflow(logger: logger).runTraceWithSnapshot(
        context: context,
        resolveSeeds: resolveSeeds,
      );
      final payload = VisualPayload.fromTrace(
        context: context,
        graph: outcome.snapshot.graph,
        trace: outcome.trace,
        command: command,
        compact: compactGraph,
      );
      return deliver(payload);
    } on Object catch (e) {
      return _handleDeliveryError(e);
    }
  }

  Future<int> runDiffView({
    required ProjectContext context,
    required String base,
  }) async {
    try {
      final result = await AnalysisWorkflow(logger: logger).runDiff(
        context: context,
        base: base,
      );
      final payload = VisualPayload.fromTrace(
        context: context,
        graph: result.snapshot.graph,
        trace: result.trace,
        command: 'diff',
        compact: compactGraph,
      );
      return deliver(payload);
    } on Object catch (e) {
      return _handleDeliveryError(e);
    }
  }

  Future<int> deliver(VisualPayload payload) async {
    final exportPath = argResults!['export'] as String?;
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

    final port = _readPort(argResults!['port'] as String);
    final session = await ViewServer(
      distDir: dist,
      payloadJson: json,
    ).start(port: port);

    logger.info('BlastRadius dashboard: ${session.url}');
    if (argResults!['open'] == true) {
      await openBrowser(session.url);
    }
    logger.info('Press Ctrl+C to stop.');

    final stop = Completer<void>();
    late final StreamSubscription<ProcessSignal> subscription;
    subscription = ProcessSignal.sigint.watch().listen((_) async {
      if (!stop.isCompleted) {
        stop.complete();
      }
    });
    await stop.future;
    await subscription.cancel();
    await session.close();
    return ExitCodes.success;
  }

  int _handleDeliveryError(Object e) {
    final code = exitCodeForAnalysisError(e);
    if (code != null) {
      logger.error(e.toString());
      return code;
    }
    if (e is PackagePathsException) {
      logger.error(e.message);
      return ExitCodes.projectError;
    }
    throw e;
  }

  int _readPort(String raw) {
    final port = int.tryParse(raw);
    if (port == null || port <= 0 || port > 65535) {
      throw UsageException('Invalid --port value: $raw', usage);
    }
    return port;
  }
}

class ViewMethodCommand extends Command<int> with GlobalOptions, ViewLauncher {
  ViewMethodCommand() {
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
    return runTraceView(
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

class ViewFileCommand extends Command<int> with GlobalOptions, ViewLauncher {
  ViewFileCommand() {
    addDashboardOptions(argParser, includeFileDisambiguator: false);
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
    return runTraceView(
      context: context,
      resolveSeeds: (snapshot) => SymbolResolver().resolveFile(
        snapshot.graph,
        filePath: filePath,
        projectRoot: context.rootPath,
      ),
    );
  }
}

class ViewClassCommand extends Command<int> with GlobalOptions, ViewLauncher {
  ViewClassCommand() {
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
    return runTraceView(
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

class ViewDiffCommand extends Command<int> with GlobalOptions, ViewLauncher {
  ViewDiffCommand() {
    argParser.addOption(
      'base',
      defaultsTo: 'HEAD',
      help: 'Git revision to diff against (working tree vs base).',
      valueHelp: 'ref',
    );
    addDashboardOptions(argParser, includeFileDisambiguator: false);
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

    return runDiffView(
      context: context,
      base: argResults!['base'] as String,
    );
  }
}

class ViewGraphCommand extends Command<int> with GlobalOptions, ViewLauncher {
  ViewGraphCommand() {
    addDashboardOptions(argParser, includeFileDisambiguator: false);
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

    try {
      final snapshot =
          await AnalysisWorkflow(logger: logger).runPipeline(context);
      final payload = VisualPayload.fromFullGraph(
        context: context,
        graph: snapshot.graph,
        command: 'analyze',
        compact: compactGraph,
      );
      return deliver(payload);
    } on Object catch (e) {
      return _handleDeliveryError(e);
    }
  }
}
