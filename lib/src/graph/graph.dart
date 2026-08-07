import 'edge.dart';
import 'node.dart';

class DependencyGraph {
  DependencyGraph({
    required Map<String, GraphNode> nodes,
    required List<GraphEdge> edges,
  })  : nodes = Map.unmodifiable(nodes),
        edges = List.unmodifiable(edges),
        outgoing = _indexOutgoing(edges),
        incoming = _indexIncoming(edges);

  final Map<String, GraphNode> nodes;
  final List<GraphEdge> edges;
  final Map<String, List<GraphEdge>> outgoing;
  final Map<String, List<GraphEdge>> incoming;

  int get nodeCount => nodes.length;
  int get edgeCount => edges.length;

  GraphNode? nodeById(String id) => nodes[id];

  static const _emptyEdges = <GraphEdge>[];

  List<GraphEdge> dependenciesOf(String id) => outgoing[id] ?? _emptyEdges;

  List<GraphEdge> dependentsOf(String id) => incoming[id] ?? _emptyEdges;

  /// Returns a single match, or null when missing / ambiguous.
  GraphNode? findMethod({
    required String methodName,
    String? className,
    String? filePath,
  }) {
    final matches = nodes.values.where((node) {
      if (!node.isMethod || node.name != methodName) {
        return false;
      }
      if (className != null && node.className != className) {
        return false;
      }
      if (filePath != null && node.filePath != filePath) {
        return false;
      }
      return true;
    }).toList(growable: false);

    if (matches.length != 1) {
      return null;
    }
    return matches.first;
  }

  static Map<String, List<GraphEdge>> _indexOutgoing(List<GraphEdge> edges) {
    final map = <String, List<GraphEdge>>{};
    for (final edge in edges) {
      map.putIfAbsent(edge.fromId, () => []).add(edge);
    }
    return Map.unmodifiable({
      for (final entry in map.entries)
        entry.key: List<GraphEdge>.unmodifiable(entry.value),
    });
  }

  static Map<String, List<GraphEdge>> _indexIncoming(List<GraphEdge> edges) {
    final map = <String, List<GraphEdge>>{};
    for (final edge in edges) {
      map.putIfAbsent(edge.toId, () => []).add(edge);
    }
    return Map.unmodifiable({
      for (final entry in map.entries)
        entry.key: List<GraphEdge>.unmodifiable(entry.value),
    });
  }
}
