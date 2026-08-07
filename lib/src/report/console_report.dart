import '../model/blast_result.dart';
import 'report_sections.dart';

class ConsoleReport {
  String render(BlastResult result) {
    final buffer = StringBuffer()
      ..writeln('────────────────────────────────────────────')
      ..writeln()
      ..writeln('BlastRadius')
      ..writeln();

    for (final section in blastReportSections(result)) {
      if (section.optional && section.items.isEmpty) {
        continue;
      }
      _section(buffer, section.title, section.items);
    }

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
