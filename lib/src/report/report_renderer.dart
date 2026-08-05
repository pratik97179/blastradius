import '../model/blast_result.dart';
import 'console_report.dart';
import 'json_report.dart';
import 'markdown_report.dart';

class ReportRenderer {
  String render(BlastResult result, String format) {
    switch (format) {
      case 'json':
        return JsonReport().render(result);
      case 'md':
        return MarkdownReport().render(result);
      case 'console':
      default:
        return ConsoleReport().render(result);
    }
  }
}
