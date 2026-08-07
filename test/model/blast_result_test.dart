import 'package:blastradius/src/model/blast_result.dart';
import 'package:test/test.dart';

void main() {
  test('empty baseline uses advisory confidence 0.4', () {
    expect(BlastResult.empty.confidence, 0.4);
    expect(BlastResult.empty.risk, RiskLevel.low);
    expect(BlastResult.empty.isEmpty, isTrue);
  });

  test('withChangedFiles preserves other fields and sorts paths', () {
    const base = BlastResult(
      changed: ['A.m'],
      repositories: ['Repo'],
      stateManagers: ['Bloc'],
      screens: ['Screen'],
      widgets: [],
      services: [],
      suggestedTests: ['a_test'],
      risk: RiskLevel.medium,
      confidence: 0.9,
    );

    final next = base.withChangedFiles(const [
      'lib/b.dart',
      'lib/a.dart',
    ]);

    expect(next.changedFiles, ['lib/a.dart', 'lib/b.dart']);
    expect(next.changed, base.changed);
    expect(next.repositories, base.repositories);
    expect(next.stateManagers, base.stateManagers);
    expect(next.screens, base.screens);
    expect(next.confidence, 0.9);
    expect(next.risk, RiskLevel.medium);
  });
}
