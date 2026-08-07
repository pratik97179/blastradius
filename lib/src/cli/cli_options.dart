import 'package:args/args.dart';

void addReportFormatOption(ArgParser parser) {
  parser.addOption(
    'format',
    allowed: ['console', 'json', 'md'],
    defaultsTo: 'console',
    help: 'Report format.',
  );
}

void addDashboardOptions(
  ArgParser parser, {
  bool includeFileDisambiguator = true,
}) {
  if (includeFileDisambiguator) {
    parser.addOption(
      'file',
      abbr: 'f',
      help: 'Disambiguate the target by source file path.',
      valueHelp: 'path',
    );
  }
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
  parser.addFlag(
    'full-graph',
    negatable: false,
    help: 'Include every method node (skip class-collapse compaction).',
  );
}
