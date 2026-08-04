import '../graph/edge.dart';
import '../model/blast_result.dart';

class ConfidenceEngine {
  double pathConfidence(Iterable<GraphEdge> edges) {
    if (edges.isEmpty) {
      return 1.0;
    }
    var score = 1.0;
    for (final edge in edges) {
      score *= edge.confidence;
    }
    return score;
  }

  double overall(Iterable<double> endpointScores) {
    final scores = endpointScores.toList(growable: false);
    if (scores.isEmpty) {
      return 0.4;
    }
    final sum = scores.reduce((a, b) => a + b);
    return sum / scores.length;
  }

  RiskLevel riskFor({required int screenCount}) {
    if (screenCount >= 3) {
      return RiskLevel.high;
    }
    if (screenCount >= 1) {
      return RiskLevel.medium;
    }
    return RiskLevel.low;
  }
}
