enum EdgeKind {
  calls,
  uses,
  extendsType,
  implementsType,
}

class GraphEdge {
  const GraphEdge({
    required this.fromId,
    required this.toId,
    required this.kind,
    required this.confidence,
  });

  final String fromId;
  final String toId;
  final EdgeKind kind;
  final double confidence;
}
