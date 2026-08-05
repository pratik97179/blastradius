import 'dart:convert';

import '../model/blast_result.dart';

class JsonReport {
  String render(BlastResult result) {
    final payload = <String, Object?>{
      'changed': result.changed,
      'changedFiles': result.changedFiles,
      'affected': <String, Object?>{
        'repositories': result.repositories,
        'services': result.services,
        'stateManagers': result.stateManagers,
        'screens': result.screens,
        'widgets': result.widgets,
      },
      'suggestedTests': result.suggestedTests,
      'risk': result.risk.label,
      'confidence': double.parse(result.confidence.toStringAsFixed(4)),
      'confidencePercent': (result.confidence * 100).round(),
      'empty': result.isEmpty,
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }
}
