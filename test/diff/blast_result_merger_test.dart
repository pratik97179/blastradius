import 'package:blastradius/src/diff/blast_result_merger.dart';
import 'package:blastradius/src/model/blast_result.dart';
import 'package:test/test.dart';

void main() {
  final merger = BlastResultMerger();

  test('empty merge uses advisory confidence 0.4', () {
    final result = merger.merge(const [], changedFiles: const ['lib/a.dart']);
    expect(result.confidence, 0.4);
    expect(result.risk, RiskLevel.low);
    expect(result.changedFiles, ['lib/a.dart']);
    expect(result.isEmpty, isTrue);
  });

  test('unions affected lists and takes max risk', () {
    const low = BlastResult(
      changed: ['A'],
      repositories: ['RepoA'],
      stateManagers: [],
      screens: [],
      widgets: [],
      services: [],
      suggestedTests: [],
      risk: RiskLevel.low,
      confidence: 0.8,
    );
    const high = BlastResult(
      changed: ['B'],
      repositories: ['RepoB'],
      stateManagers: ['Bloc'],
      screens: ['Screen'],
      widgets: [],
      services: ['Svc'],
      suggestedTests: ['a_test'],
      risk: RiskLevel.high,
      confidence: 0.4,
    );

    final merged = merger.merge([low, high]);
    expect(merged.changed, ['A', 'B']);
    expect(merged.repositories, ['RepoA', 'RepoB']);
    expect(merged.stateManagers, ['Bloc']);
    expect(merged.screens, ['Screen']);
    expect(merged.services, ['Svc']);
    expect(merged.risk, RiskLevel.high);
    expect(merged.confidence, closeTo(0.6, 0.0001));
  });
}
