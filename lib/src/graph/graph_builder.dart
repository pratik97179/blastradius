import '../analyzer/classifiers.dart';
import '../model/ast_model.dart';
import '../model/node_kind.dart';
import '../utils/type_names.dart';
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

    final kindByClassId = <String, NodeKind>{
      for (final item in classified)
        _classId(item.declaration.filePath, item.name): item.kind,
    };

    for (final declaration in ast.classes) {
      final id = _classId(declaration.filePath, declaration.name);
      nodes[id] = GraphNode(
        id: id,
        name: declaration.name,
        kind: kindByClassId[id] ?? NodeKind.other,
        filePath: declaration.filePath,
        isMethod: false,
      );
    }

    final classIdsByName = <String, List<String>>{};
    final methodIdsByClassAndName = <String, List<String>>{};
    for (final node in nodes.values) {
      if (!node.isMethod) {
        classIdsByName.putIfAbsent(node.name, () => []).add(node.id);
      }
    }

    for (final declaration in ast.classes) {
      final id = _classId(declaration.filePath, declaration.name);

      void addHierarchy(String? typeName, EdgeKind kind) {
        if (typeName == null) {
          return;
        }
        final simple = simpleTypeName(typeName);
        final target = _uniqueId(classIdsByName[simple]);
        if (target == null || target == id) {
          return;
        }
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

      addHierarchy(declaration.superclassName, EdgeKind.extendsType);
      for (final mixinName in declaration.mixinNames) {
        addHierarchy(mixinName, EdgeKind.mixinType);
      }
      for (final interfaceName in declaration.interfaceNames) {
        addHierarchy(interfaceName, EdgeKind.implementsType);
      }
    }

    for (final method in ast.methods) {
      final id = _methodId(method.filePath, method.className, method.name);
      final classId = method.className == null
          ? null
          : _classId(method.filePath, method.className!);
      nodes[id] = GraphNode(
        id: id,
        name: method.name,
        kind: classId == null
            ? NodeKind.other
            : (kindByClassId[classId] ?? NodeKind.other),
        filePath: method.filePath,
        isMethod: true,
        className: method.className,
      );

      if (method.className != null) {
        methodIdsByClassAndName
            .putIfAbsent('${method.className}\u0000${method.name}', () => [])
            .add(id);
        if (classId != null && nodes.containsKey(classId)) {
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

    // Rebuild class index after methods are added (methods do not affect it).
    classIdsByName.clear();
    for (final node in nodes.values) {
      if (!node.isMethod) {
        classIdsByName.putIfAbsent(node.name, () => []).add(node.id);
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

      final toId = _resolveCallTargetId(
        nodes: nodes,
        call: call,
        classIdsByName: classIdsByName,
        methodIdsByClassAndName: methodIdsByClassAndName,
      );
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
            : _uniqueId(classIdsByName[toClass]);
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
      final toClassId = _uniqueId(classIdsByName[usage.targetTypeName]);
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

  String? _resolveCallTargetId({
    required Map<String, GraphNode> nodes,
    required ResolvedCall call,
    required Map<String, List<String>> classIdsByName,
    required Map<String, List<String>> methodIdsByClassAndName,
  }) {
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
      final methodKey = '${call.targetClass}\u0000${call.targetName}';
      final methodId = _uniqueId(methodIdsByClassAndName[methodKey]);
      if (methodId != null) {
        return methodId;
      }
      return _uniqueId(classIdsByName[call.targetClass!]);
    }

    return null;
  }

  String? _uniqueId(List<String>? ids) {
    if (ids == null || ids.length != 1) {
      return null;
    }
    return ids.first;
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
}
