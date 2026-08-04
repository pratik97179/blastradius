import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../utils/logger.dart';
import 'exit_codes.dart';

/// Package version mirrored from pubspec.
const String packageVersion = '0.0.1';

/// Parses argv and dispatches BlastRadius commands.
///
/// Returns a process exit code.
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

    // `CommandRunner.run` normally requires a command; allow bare `--help` /
    // empty argv to print usage without a usage error.
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
    final methodName = argResults!.rest.first;
    final file = argResults!['file'] as String?;
    final format = argResults!['format'] as String;
    return _notImplemented(
      logger: logger,
      projectPath: projectPath,
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
    final filePath = argResults!.rest.first;
    final format = argResults!['format'] as String;
    return _notImplemented(
      logger: logger,
      projectPath: projectPath,
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
    final className = argResults!.rest.first;
    final file = argResults!['file'] as String?;
    final format = argResults!['format'] as String;
    return _notImplemented(
      logger: logger,
      projectPath: projectPath,
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
    final base = argResults!['base'] as String;
    final format = argResults!['format'] as String;
    return _notImplemented(
      logger: logger,
      projectPath: projectPath,
      summary: 'diff --base $base --format $format',
    );
  }
}

class AnalyzeCommand extends Command<int> with GlobalOptions {
  @override
  String get name => 'analyze';

  @override
  String get description =>
      'Build and cache the project dependency graph (warm-up).';

  @override
  Future<int> run() async {
    return _notImplemented(
      logger: logger,
      projectPath: projectPath,
      summary: 'analyze',
    );
  }
}

Future<int> _notImplemented({
  required Logger logger,
  required String projectPath,
  required String summary,
}) async {
  logger.info('BlastRadius $packageVersion');
  logger.debug('project=$projectPath');
  logger.info('Command acknowledged: $summary');
  logger.info('Not implemented yet. Project root: $projectPath');
  return ExitCodes.notImplemented;
}
