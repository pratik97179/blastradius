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
      );
    }

    final nodes = <Map<String, Object?>>[];
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
    nodes.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

    final edges = <Map<String, Object?>>[];
    for (final edge in graph.edges) {
      if (!nodeIds.contains(edge.fromId) || !nodeIds.contains(edge.toId)) {
        continue;
      }
      edges.add(_edgeJson(edge));
    }
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
    );
  }

  factory VisualPayload.fromFullGraph({
    required ProjectContext context,
    required DependencyGraph graph,
    required String command,
    DateTime? generatedAt,
  }) {
    final nodes = graph.nodes.values
        .map(
          (node) => _nodeJson(
            node: node,
            projectRoot: context.rootPath,
            role: VisualNodeRole.context,
            score: null,
          ),
        )
        .toList()
      ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

    final edges = graph.edges.map(_edgeJson).toList()
      ..sort((a, b) {
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
      summary: const BlastResult(
        changed: [],
        repositories: [],
        stateManagers: [],
        screens: [],
        widgets: [],
        services: [],
        suggestedTests: [],
        risk: RiskLevel.low,
        confidence: 0.0,
      ),
      nodes: nodes,
      edges: edges,
    );
  }

  factory VisualPayload._build({
    required ProjectContext context,
    required String command,
    required DateTime? generatedAt,
    required BlastResult summary,
    required List<Map<String, Object?>> nodes,
    required List<Map<String, Object?>> edges,
  }) {
    final at = generatedAt ?? DateTime.now().toUtc();
    return VisualPayload({
      'meta': <String, Object?>{
        'packageName': context.packageName,
        'projectRoot': context.rootPath,
        'platform': context.isFlutter ? 'flutter' : 'dart',
        'command': command,
        'generatedAt': at.toIso8601String(),
      },
      'summary': _summaryJson(summary),
      'graph': <String, Object?>{
        'nodes': nodes,
        'edges': edges,
      },
    });
  }

  String toJson() => const JsonEncoder.withIndent('  ').convert(data);

  static Map<String, Object?> _summaryJson(BlastResult result) {
    return {
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
  }

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
