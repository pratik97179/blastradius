import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../analyzer/ast_extractor.dart';
import '../analyzer/classifiers.dart';
import '../analyzer/project_analyzer.dart';
import '../model/node_kind.dart';
import '../model/project_context.dart';
import '../utils/logger.dart';
import 'exit_codes.dart';

const String packageVersion = '0.0.5';

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
              'Static impact analysis for Flutter applications.',
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
      help: 'Path to the Flutter project root (defaults to the current directory).',
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

  Logger loggerFrom(ArgResults global) {
    return Logger(verbose: global['verbose'] == true);
  }

  String projectFrom(ArgResults global) {
    final raw = global['project'] as String?;
    if (raw == null || raw.isEmpty) {
      return p.current;
    }
    return p.normalize(p.absolute(raw));
  }
}

mixin GlobalOptions on Command<int> {
  BlastRadiusCommandRunner get blastRunner =>
      runner! as BlastRadiusCommandRunner;

  Logger get logger => blastRunner.loggerFrom(globalResults!);

  String get projectPath => blastRunner.projectFrom(globalResults!);

  ProjectContext? discoverProject() {
    try {
      final context = ProjectAnalyzer().discover(projectPath);
      logger.debug('discovered ${context.packageName} (${context.dartFileCount} dart files)');
      return context;
    } on ProjectDiscoveryException catch (e) {
      logger.error(e.message);
      return null;
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

class TraceMethodCommand extends Command<int> with GlobalOptions {
  TraceMethodCommand() {
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'Disambiguate the method by source file path.',
      valueHelp: 'path',
    );
    argParser.addOption(
      'format',
      allowed: ['console', 'json', 'md'],
      defaultsTo: 'console',
      help: 'Report format.',
    );
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
    return _notImplemented(
      logger: logger,
      context: context,
      summary:
          'trace method $methodName'
          '${file != null ? ' --file $file' : ''} --format $format',
    );
  }
}

class TraceFileCommand extends Command<int> with GlobalOptions {
  TraceFileCommand() {
    argParser.addOption(
      'format',
      allowed: ['console', 'json', 'md'],
      defaultsTo: 'console',
      help: 'Report format.',
    );
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
    return _notImplemented(
      logger: logger,
      context: context,
      summary: 'trace file $filePath --format $format',
    );
  }
}

class TraceClassCommand extends Command<int> with GlobalOptions {
  TraceClassCommand() {
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'Disambiguate the class by source file path.',
      valueHelp: 'path',
    );
    argParser.addOption(
      'format',
      allowed: ['console', 'json', 'md'],
      defaultsTo: 'console',
      help: 'Report format.',
    );
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
    return _notImplemented(
      logger: logger,
      context: context,
      summary:
          'trace class $className'
          '${file != null ? ' --file $file' : ''} --format $format',
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
    argParser.addOption(
      'format',
      allowed: ['console', 'json', 'md'],
      defaultsTo: 'console',
      help: 'Report format.',
    );
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
    return _notImplemented(
      logger: logger,
      context: context,
      summary: 'diff --base $base --format $format',
    );
  }
}

class AnalyzeCommand extends Command<int> with GlobalOptions {
  @override
  String get name => 'analyze';

  @override
  String get description =>
      'Discover a Flutter project, extract AST symbols, and classify types.';

  @override
  Future<int> run() async {
    final context = discoverProject();
    if (context == null) {
      return ExitCodes.projectError;
    }

    logger.info('BlastRadius $packageVersion');
    logger.info('Project   ${context.rootPath}');
    logger.info('Package   ${context.packageName}');
    logger.info('Pubspec   ${context.pubspecPath}');
    logger.info('Dart files ${context.dartFileCount}');
    if (logger.verbose) {
      for (final file in context.dartFiles) {
        logger.debug(p.relative(file, from: context.rootPath));
      }
    }

    try {
      final ast = await AstExtractor().extract(context);
      final classifier = ClassClassifier();
      final classified = classifier.classifyAll(ast.classes);
      final kindCounts = classifier.countByKind(classified);

      logger.info('Classes   ${ast.classes.length}');
      logger.info('Methods   ${ast.methods.length}');
      logger.info(
        'Calls     ${ast.calls.length} (${ast.resolvedCallCount} resolved)',
      );
      logger.info('Kinds');
      for (final kind in NodeKind.values) {
        final count = kindCounts[kind];
        if (count == null || count == 0) {
          continue;
        }
        logger.info('  ${kind.label.padRight(14)} $count');
      }

      if (logger.verbose) {
        for (final item in classified) {
          logger.debug('${item.kind.label}: ${item.name}');
        }
        for (final call in ast.calls.where((c) => c.isResolved)) {
          final from = [
            if (call.fromClass != null) call.fromClass,
            if (call.fromMethod != null) call.fromMethod,
          ].join('.');
          logger.debug('$from -> ${call.targetQualifiedName}');
        }
      }
    } on AstExtractionException catch (e) {
      logger.error(e.message);
      return ExitCodes.projectError;
    }

    return ExitCodes.success;
  }
}

Future<int> _notImplemented({
  required Logger logger,
  required ProjectContext context,
  required String summary,
}) async {
  logger.info('BlastRadius $packageVersion');
  logger.info('Project ${context.packageName} (${context.dartFileCount} dart files)');
  logger.info('Command acknowledged: $summary');
  logger.info('Analysis not implemented yet.');
  return ExitCodes.notImplemented;
}
