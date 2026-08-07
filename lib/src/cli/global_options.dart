import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../analyzer/project_analyzer.dart';
import '../model/project_context.dart';
import '../utils/logger.dart';

mixin GlobalOptions on Command<int> {
  Logger get logger => Logger(verbose: globalResults!['verbose'] == true);

  String get projectPath {
    final raw = globalResults!['project'] as String?;
    if (raw == null || raw.isEmpty) {
      return p.current;
    }
    return p.normalize(p.absolute(raw));
  }

  ProjectContext? discoverProject() {
    try {
      final context = ProjectAnalyzer().discover(projectPath);
      logger.debug(
        'discovered ${context.packageName} (${context.dartFileCount} dart files)',
      );
      return context;
    } on ProjectDiscoveryException catch (e) {
      logger.error(e.message);
      return null;
    }
  }
}
