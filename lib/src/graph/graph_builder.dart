import '../analyzer/classifiers.dart';
import '../model/ast_model.dart';
import '../model/node_kind.dart';
import 'edge.dart';
import 'graph.dart';
import 'node.dart';

class GraphBuilder {
  DependencyGraph build({
    required AstModel ast,
    required List<ClassifiedClass> classified,
  }) {
    final nodes = <String, GraphNode>{};
    final edges = <GraphEdge>[];
    final seenEdges = <String>{};

    final kindByClassName = <String, NodeKind>{
      for (final item in classified) item.name: item.kind,
    };

    for (final declaration in ast.classes) {
      final id = _classId(declaration.filePath, declaration.name);
      nodes[id] = GraphNode(
        id: id,
        name: declaration.name,
        kind: kindByClassName[declaration.name] ?? NodeKind.other,
        filePath: declaration.filePath,
        isMethod: false,
      );

      for (final typeName in declaration.hierarchyTypeNames) {
        final simple = _simpleTypeName(typeName);
        final target = _findClassNodeId(nodes, ast, simple);
        if (target == null || target == id) {
          continue;
        }
        final kind = declaration.superclassName == typeName
            ? EdgeKind.extendsType
            : EdgeKind.implementsType;
        _addEdge(
          edges: edges,
          seen: seenEdges,
          edge: GraphEdge(
            fromId: id,
            toId: target,
            kind: kind,
            confidence: 0.95,
          ),
        );
      }
    }

    for (final method in ast.methods) {
      final id = _methodId(method.filePath, method.className, method.name);
      nodes[id] = GraphNode(
        id: id,
        name: method.name,
        kind: method.className == null
            ? NodeKind.other
            : (kindByClassName[method.className!] ?? NodeKind.other),
        filePath: method.filePath,
        isMethod: true,
        className: method.className,
      );

      if (method.className != null) {
        final classId = _classId(method.filePath, method.className!);
        if (nodes.containsKey(classId)) {
          _addEdge(
            edges: edges,
            seen: seenEdges,
            edge: GraphEdge(
              fromId: classId,
              toId: id,
              kind: EdgeKind.uses,
              confidence: 1.0,
            ),
          );
        }
      }
    }

    for (final call in ast.calls) {
      if (!call.isResolved || call.fromMethod == null) {
        continue;
      }

      final fromId = _methodId(call.fromFile, call.fromClass, call.fromMethod!);
      if (!nodes.containsKey(fromId)) {
        continue;
      }

      final toId = _resolveCallTargetId(nodes, call);
      if (toId == null || toId == fromId) {
        continue;
      }

      _addEdge(
        edges: edges,
        seen: seenEdges,
        edge: GraphEdge(
          fromId: fromId,
          toId: toId,
          kind: EdgeKind.calls,
          confidence: call.targetFile != null ? 1.0 : 0.7,
        ),
      );

      final fromClass = call.fromClass;
      final toClass = call.targetClass;
      if (fromClass != null && toClass != null) {
        final fromClassId = _classId(call.fromFile, fromClass);
        final toClassId = call.targetFile != null
            ? _classId(call.targetFile!, toClass)
            : _findClassNodeId(nodes, ast, toClass);
        if (toClassId != null &&
            nodes.containsKey(fromClassId) &&
            nodes.containsKey(toClassId) &&
            fromClassId != toClassId) {
          _addEdge(
            edges: edges,
            seen: seenEdges,
            edge: GraphEdge(
              fromId: fromClassId,
              toId: toClassId,
              kind: EdgeKind.calls,
              confidence: call.targetFile != null ? 0.95 : 0.7,
            ),
          );
        }
      }
    }

    for (final usage in ast.typeUsages) {
      final toClassId = _findClassNodeId(nodes, ast, usage.targetTypeName);
      if (toClassId == null) {
        continue;
      }

      if (usage.fromClass != null) {
        final fromClassId = _classId(usage.fromFile, usage.fromClass!);
        if (nodes.containsKey(fromClassId) && fromClassId != toClassId) {
          _addEdge(
            edges: edges,
            seen: seenEdges,
            edge: GraphEdge(
              fromId: fromClassId,
              toId: toClassId,
              kind: EdgeKind.uses,
              confidence: 0.9,
            ),
          );
        }
      }

      if (usage.fromMethod != null) {
        final fromMethodId = _methodId(
          usage.fromFile,
          usage.fromClass,
          usage.fromMethod!,
        );
        if (nodes.containsKey(fromMethodId) && fromMethodId != toClassId) {
          _addEdge(
            edges: edges,
            seen: seenEdges,
            edge: GraphEdge(
              fromId: fromMethodId,
              toId: toClassId,
              kind: EdgeKind.uses,
              confidence: 0.9,
            ),
          );
        }
      }
    }

    return DependencyGraph(nodes: nodes, edges: edges);
  }

  String? _resolveCallTargetId(
    Map<String, GraphNode> nodes,
    ResolvedCall call,
  ) {
    if (call.targetFile != null && call.targetClass != null) {
      final methodId = _methodId(
        call.targetFile!,
        call.targetClass,
        call.targetName,
      );
      if (nodes.containsKey(methodId)) {
        return methodId;
      }
      final classId = _classId(call.targetFile!, call.targetClass!);
      if (nodes.containsKey(classId)) {
        return classId;
      }
    }

    if (call.targetClass != null) {
      final matches = nodes.values.where((node) {
        return node.isMethod &&
            node.className == call.targetClass &&
            node.name == call.targetName;
      }).toList(growable: false);
      if (matches.length == 1) {
        return matches.first.id;
      }

      final classMatches = nodes.values
          .where(
            (node) => !node.isMethod && node.name == call.targetClass,
          )
          .toList(growable: false);
      if (classMatches.length == 1) {
        return classMatches.first.id;
      }
    }

    return null;
  }

  String? _findClassNodeId(
    Map<String, GraphNode> nodes,
    AstModel ast,
    String className,
  ) {
    final matches = nodes.values
        .where((node) => !node.isMethod && node.name == className)
        .toList(growable: false);
    if (matches.length == 1) {
      return matches.first.id;
    }
    return null;
  }

  void _addEdge({
    required List<GraphEdge> edges,
    required Set<String> seen,
    required GraphEdge edge,
  }) {
    final key = '${edge.fromId}|${edge.toId}|${edge.kind.name}';
    if (!seen.add(key)) {
      return;
    }
    edges.add(edge);
  }

  String _classId(String filePath, String className) => '$filePath#$className';

  String _methodId(String filePath, String? className, String methodName) {
    if (className == null) {
      return '$filePath#$methodName';
    }
    return '$filePath#$className.$methodName';
  }

  String _simpleTypeName(String typeSource) {
    final withoutArgs = typeSource.split('<').first.trim();
    return withoutArgs.split('.').last.trim();
  }
}
