import '../model/blast_result.dart';

class BlastResultMerger {
  BlastResult merge(Iterable<BlastResult> results, {List<String> changedFiles = const []}) {
    final list = results.toList(growable: false);
    if (list.isEmpty) {
      return BlastResult(
        changed: const [],
        changedFiles: changedFiles,
        repositories: const [],
        stateManagers: const [],
        screens: const [],
        widgets: const [],
        services: const [],
        suggestedTests: const [],
        risk: RiskLevel.low,
        confidence: 0.4,
      );
    }

    List<String> union(Iterable<List<String>> values) {
      final set = <String>{};
      for (final items in values) {
        set.addAll(items);
      }
      final sorted = set.toList()..sort();
      return sorted;
    }

    final risks = list.map((r) => r.risk).toList(growable: false);
    var risk = RiskLevel.low;
    if (risks.contains(RiskLevel.high)) {
      risk = RiskLevel.high;
    } else if (risks.contains(RiskLevel.medium)) {
      risk = RiskLevel.medium;
    }

    final confidence =
        list.map((r) => r.confidence).reduce((a, b) => a + b) / list.length;

    return BlastResult(
      changed: union(list.map((r) => r.changed)),
      changedFiles: changedFiles.isEmpty
          ? union(list.map((r) => r.changedFiles))
          : (changedFiles.toList()..sort()),
      repositories: union(list.map((r) => r.repositories)),
      stateManagers: union(list.map((r) => r.stateManagers)),
      screens: union(list.map((r) => r.screens)),
      widgets: union(list.map((r) => r.widgets)),
      services: union(list.map((r) => r.services)),
      suggestedTests: union(list.map((r) => r.suggestedTests)),
      risk: risk,
      confidence: confidence,
    );
  }
}
