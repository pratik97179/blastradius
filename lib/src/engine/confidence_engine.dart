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

  /// Screen count drives Flutter UX risk; [surfaceCount] covers repos,
  /// services, state managers, widgets, and screens for Dart packages too.
  RiskLevel riskFor({
    required int screenCount,
    int surfaceCount = 0,
  }) {
    if (screenCount >= 3 || surfaceCount >= 5) {
      return RiskLevel.high;
    }
    if (screenCount >= 1 || surfaceCount >= 2) {
      return RiskLevel.medium;
    }
    return RiskLevel.low;
  }
}

