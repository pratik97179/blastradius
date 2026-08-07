import 'dart:convert';

import 'package:path/path.dart' as p;

import '../graph/edge.dart';
import '../graph/graph.dart';
import '../graph/node.dart';
import '../model/blast_result.dart';
import '../model/blast_trace.dart';
import '../model/node_kind.dart';
import '../model/project_context.dart';

enum VisualNodeRole { seed, affected, context }

extension VisualNodeRoleLabel on VisualNodeRole {
  String get label => name;
}

class VisualPayload {
  VisualPayload(this.data);

  final Map<String, Object?> data;

  factory VisualPayload.fromTrace({
    required ProjectContext context,
    required DependencyGraph graph,
    required BlastTrace trace,
    required String command,
    DateTime? generatedAt,
    bool compact = true,
  }) {
    final nodeIds = trace.scoresByNodeId.keys.toSet();
    if (nodeIds.isEmpty) {
      return VisualPayload._build(
        context: context,
        command: command,
        generatedAt: generatedAt,
        summary: trace.result,
        nodes: const [],
        edges: const [],
        compact: compact,
      );
    }

    final List<Map<String, Object?>> nodes;
    final List<Map<String, Object?>> edges;

    if (compact) {
      final compacted = _compactGraph(
        graph: graph,
        projectRoot: context.rootPath,
        seedIds: trace.seedIds,
        scoresByNodeId: trace.scoresByNodeId,
        candidateNodeIds: nodeIds,
      );
      nodes = compacted.nodes;
      edges = compacted.edges;
    } else {
      nodes = <Map<String, Object?>>[];
      for (final id in nodeIds) {
        final node = graph.nodeById(id);
        if (node == null) {
          continue;
        }
        final role = trace.seedIds.contains(id)
            ? VisualNodeRole.seed
            : VisualNodeRole.affected;
        nodes.add(
          _nodeJson(
            node: node,
            projectRoot: context.rootPath,
            role: role,
            score: trace.scoresByNodeId[id],
          ),
        );
      }

      edges = <Map<String, Object?>>[];
      for (final edge in graph.edges) {
        if (!nodeIds.contains(edge.fromId) || !nodeIds.contains(edge.toId)) {
          continue;
        }
        edges.add(_edgeJson(edge));
      }
    }

    nodes.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
    edges.sort((a, b) {
      final from = (a['from'] as String).compareTo(b['from'] as String);
      if (from != 0) {
        return from;
      }
      return (a['to'] as String).compareTo(b['to'] as String);
    });

    return VisualPayload._build(
      context: context,
      command: command,
      generatedAt: generatedAt,
      summary: trace.result,
      nodes: nodes,
      edges: edges,
      compact: compact,
    );
  }

  factory VisualPayload.fromFullGraph({
    required ProjectContext context,
    required DependencyGraph graph,
    required String command,
    DateTime? generatedAt,
    bool compact = true,
  }) {
    final List<Map<String, Object?>> nodes;
    final List<Map<String, Object?>> edges;

    if (compact) {
      final compacted = _compactGraph(
        graph: graph,
        projectRoot: context.rootPath,
        seedIds: const {},
        scoresByNodeId: const {},
        candidateNodeIds: graph.nodes.keys.toSet(),
        defaultRole: VisualNodeRole.context,
      );
      nodes = compacted.nodes;
      edges = compacted.edges;
    } else {
      nodes = graph.nodes.values
          .map(
            (node) => _nodeJson(
              node: node,
              projectRoot: context.rootPath,
              role: VisualNodeRole.context,
              score: null,
            ),
          )
          .toList();
      edges = graph.edges.map(_edgeJson).toList();
    }

    nodes.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
    edges.sort((a, b) {
      final from = (a['from'] as String).compareTo(b['from'] as String);
      if (from != 0) {
        return from;
      }
      return (a['to'] as String).compareTo(b['to'] as String);
    });

    return VisualPayload._build(
      context: context,
      command: command,
      generatedAt: generatedAt,
      summary: BlastResult.empty,
      nodes: nodes,
      edges: edges,
      compact: compact,
    );
  }

  factory VisualPayload._build({
    required ProjectContext context,
    required String command,
    required DateTime? generatedAt,
    required BlastResult summary,
    required List<Map<String, Object?>> nodes,
    required List<Map<String, Object?>> edges,
    required bool compact,
  }) {
    final at = generatedAt ?? DateTime.now().toUtc();
    return VisualPayload({
      'meta': <String, Object?>{
        'packageName': context.packageName,
        'projectRoot': context.rootPath,
        'platform': context.isFlutter ? 'flutter' : 'dart',
        'command': command,
        'generatedAt': at.toIso8601String(),
        'compact': compact,
      },
      'summary': summary.toJsonMap(),
      'graph': <String, Object?>{
        'nodes': nodes,
        'edges': edges,
      },
    });
  }

  String toJson() => const JsonEncoder.withIndent('  ').convert(data);

  /// Collapse non-seed methods into class nodes and drop hierarchy edges.
  static ({
    List<Map<String, Object?>> nodes,
    List<Map<String, Object?>> edges,
  }) _compactGraph({
    required DependencyGraph graph,
    required String projectRoot,
    required Set<String> seedIds,
    required Map<String, double> scoresByNodeId,
    required Set<String> candidateNodeIds,
    VisualNodeRole defaultRole = VisualNodeRole.affected,
  }) {
    final classByKey = <String, GraphNode>{};
    for (final node in graph.nodes.values) {
      if (!node.isMethod) {
        classByKey[_classKey(node.filePath, node.name)] = node;
      }
    }

    GraphNode? classFor(GraphNode node) {
      if (!node.isMethod || node.className == null) {
        return null;
      }
      return classByKey[_classKey(node.filePath, node.className!)];
    }

    final classScores = <String, double>{};
    for (final entry in scoresByNodeId.entries) {
      final method = graph.nodeById(entry.key);
      if (method == null || !method.isMethod || method.className == null) {
        continue;
      }
      final cls = classFor(method);
      if (cls == null) {
        continue;
      }
      final existing = classScores[cls.id];
      if (existing == null || entry.value > existing) {
        classScores[cls.id] = entry.value;
      }
    }

    final keep = <String, GraphNode>{};
    for (final id in candidateNodeIds) {
      final node = graph.nodeById(id);
      if (node == null) {
        continue;
      }
      if (seedIds.contains(id)) {
        keep[id] = node;
        continue;
      }
      if (node.isMethod) {
        final cls = classFor(node);
        if (cls != null) {
          keep[cls.id] = cls;
        }
        continue;
      }
      keep[id] = node;
    }

    for (final node in [...keep.values]) {
      if (!node.isMethod || node.className == null) {
        continue;
      }
      final cls = classFor(node);
      if (cls != null) {
        keep.putIfAbsent(cls.id, () => cls);
      }
    }

    String? resolve(String id) {
      if (keep.containsKey(id)) {
        return id;
      }
      final node = graph.nodeById(id);
      if (node == null) {
        return null;
      }
      final cls = classFor(node);
      if (cls != null && keep.containsKey(cls.id)) {
        return cls.id;
      }
      return null;
    }

    VisualNodeRole roleFor(GraphNode node) {
      if (seedIds.contains(node.id)) {
        return VisualNodeRole.seed;
      }
      if (defaultRole == VisualNodeRole.context) {
        return VisualNodeRole.context;
      }
      return VisualNodeRole.affected;
    }

    double? scoreFor(String id) {
      final direct = scoresByNodeId[id];
      if (direct != null) {
        return direct;
      }
      return classScores[id];
    }

    final nodes = keep.values
        .map(
          (node) => _nodeJson(
            node: node,
            projectRoot: projectRoot,
            role: roleFor(node),
            score: scoreFor(node.id),
          ),
        )
        .toList();

    final edgeKeys = <String>{};
    final edges = <Map<String, Object?>>[];
    for (final edge in graph.edges) {
      if (edge.kind == EdgeKind.extendsType ||
          edge.kind == EdgeKind.implementsType ||
          edge.kind == EdgeKind.mixinType) {
        continue;
      }
      final from = resolve(edge.fromId);
      final to = resolve(edge.toId);
      if (from == null || to == null || from == to) {
        continue;
      }
      final key = '$from|$to|${edge.kind.name}';
      if (!edgeKeys.add(key)) {
        continue;
      }
      edges.add({
        'from': from,
        'to': to,
        'kind': edge.kind.name,
        'confidence': double.parse(edge.confidence.toStringAsFixed(4)),
      });
    }

    return (nodes: nodes, edges: edges);
  }

  static String _classKey(String filePath, String className) =>
      '$filePath#$className';

  static Map<String, Object?> _nodeJson({
    required GraphNode node,
    required String projectRoot,
    required VisualNodeRole role,
    required double? score,
  }) {
    final relative = p.isWithin(projectRoot, node.filePath)
        ? p.relative(node.filePath, from: projectRoot)
        : node.filePath;
    return {
      'id': node.id,
      'label': node.displayName,
      'kind': node.kind.label,
      'filePath': relative.replaceAll('\\', '/'),
      'isMethod': node.isMethod,
      'className': node.className,
      'role': role.label,
      'score': score == null
          ? null
          : double.parse(score.toStringAsFixed(4)),
    };
  }

  static Map<String, Object?> _edgeJson(GraphEdge edge) {
    return {
      'from': edge.fromId,
      'to': edge.toId,
      'kind': edge.kind.name,
      'confidence': double.parse(edge.confidence.toStringAsFixed(4)),
    };
  }
}
