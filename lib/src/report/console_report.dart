import '../model/blast_result.dart';

class ConsoleReport {
  String render(BlastResult result) {
    final buffer = StringBuffer()
      ..writeln('────────────────────────────────────────────')
      ..writeln()
      ..writeln('BlastRadius')
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
      buffer
        ..writeln('No dependents found in the graph walk.')
        ..writeln();
    }

    buffer
      ..writeln('Risk')
      ..writeln()
      ..writeln(result.risk.label)
      ..writeln()
      ..writeln('Confidence')
      ..writeln()
      ..writeln('${(result.confidence * 100).round()}%')
      ..writeln()
      ..writeln('────────────────────────────────────────────');

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
      ..writeln(title)
      ..writeln();
    if (items.isEmpty) {
      buffer.writeln('(none)');
    } else {
      for (final item in items) {
        buffer.writeln('✓ $item');
      }
    }
    buffer.writeln();
  }
}
