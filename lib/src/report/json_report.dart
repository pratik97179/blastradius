import 'dart:convert';

import '../model/blast_result.dart';

class JsonReport {
  String render(BlastResult result) {
    return const JsonEncoder.withIndent('  ').convert(result.toJsonMap());
  }
}
