import '../model/blast_result.dart';
import 'report_sections.dart';

class MarkdownReport {
  String render(BlastResult result) {
    final buffer = StringBuffer()
      ..writeln('# BlastRadius')
      ..writeln();

    for (final section in blastReportSections(result)) {
      if (section.optional && section.items.isEmpty) {
        continue;
      }
      _section(buffer, section.title, section.items);
    }

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
