import 'package:blastradius/src/engine/confidence_engine.dart';
import 'package:blastradius/src/graph/edge.dart';
import 'package:blastradius/src/model/blast_result.dart';
import 'package:test/test.dart';

void main() {
  final engine = ConfidenceEngine();

  test('overall on empty scores is 0.4', () {
    expect(engine.overall(const []), 0.4);
  });

  test('overall averages endpoint scores', () {
    expect(engine.overall(const [1.0, 0.5]), 0.75);
  });

  test('pathConfidence multiplies edge confidences', () {
    expect(
      engine.pathConfidence(const [
        GraphEdge(fromId: 'a', toId: 'b', kind: EdgeKind.calls, confidence: 1.0),
        GraphEdge(fromId: 'b', toId: 'c', kind: EdgeKind.calls, confidence: 0.5),
      ]),
      0.5,
    );
  });

  test('risk thresholds for screens and surfaces', () {
    expect(engine.riskFor(screenCount: 0, surfaceCount: 0), RiskLevel.low);
    expect(engine.riskFor(screenCount: 1, surfaceCount: 0), RiskLevel.medium);
    expect(engine.riskFor(screenCount: 0, surfaceCount: 2), RiskLevel.medium);
    expect(engine.riskFor(screenCount: 3, surfaceCount: 0), RiskLevel.high);
    expect(engine.riskFor(screenCount: 0, surfaceCount: 5), RiskLevel.high);
  });
}
