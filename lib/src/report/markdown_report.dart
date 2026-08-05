import '../model/blast_result.dart';

class MarkdownReport {
  String render(BlastResult result) {
    final buffer = StringBuffer()
      ..writeln('# BlastRadius')
      ..writeln();

    if (result.changedFiles.isNotEmpty) {
      _section(buffer, 'Changed Files', result.changedFiles);
    }
    _section(buffer, 'Changed', result.changed);
    _section(buffer, 'Affected Repositories', result.repositories);
    _section(buffer, 'Affected Services', result.services);
    _section(buffer, 'Affected State Managers', result.stateManagers);
    _section(buffer, 'Affected Screens', result.screens);
    if (result.widgets.isNotEmpty) {
      _section(buffer, 'Affected Widgets', result.widgets);
    }
    _section(buffer, 'Suggested Tests', result.suggestedTests);

    if (result.isEmpty) {
      buffer.writeln('_No user-facing dependents found._');
      buffer.writeln();
    }

    buffer
      ..writeln('## Risk')
      ..writeln()
      ..writeln(result.risk.label)
      ..writeln()
      ..writeln('## Confidence')
      ..writeln()
      ..writeln('${(result.confidence * 100).round()}%')
      ..writeln();

    return buffer.toString();
  }

  void _section(StringBuffer buffer, String title, List<String> items) {
    buffer
      ..writeln('## $title')
      ..writeln();
    if (items.isEmpty) {
      buffer.writeln('- _(none)_');
    } else {
      for (final item in items) {
        buffer.writeln('- [x] $item');
      }
    }
    buffer.writeln();
  }
}
