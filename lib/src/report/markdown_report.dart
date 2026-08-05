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
    _sectionIfPresent(buffer, 'Affected Repositories', result.repositories);
    _sectionIfPresent(buffer, 'Affected Services', result.services);
    _sectionIfPresent(buffer, 'Affected State Managers', result.stateManagers);
    _sectionIfPresent(buffer, 'Affected Screens', result.screens);
    _sectionIfPresent(buffer, 'Affected Widgets', result.widgets);
    _sectionIfPresent(buffer, 'Suggested Tests', result.suggestedTests);

    if (result.isEmpty) {
      buffer.writeln('_No dependents found in the graph walk._');
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

  void _sectionIfPresent(StringBuffer buffer, String title, List<String> items) {
    if (items.isEmpty) {
      return;
    }
    _section(buffer, title, items);
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
