import 'package:path/path.dart' as p;

import '../model/ast_model.dart';
import '../model/node_kind.dart';
import '../utils/type_names.dart';
import 'kind_signals.dart';

class ClassifiedClass {
  const ClassifiedClass({
    required this.declaration,
    required this.kind,
  });

  final DeclaredClass declaration;
  final NodeKind kind;

  String get name => declaration.name;
}

class ClassClassifier {
  List<ClassifiedClass> classifyAll(
    Iterable<DeclaredClass> classes, {
    Set<String> routeDestinationNames = const {},
  }) {
    return classes
        .map(
          (declaration) => ClassifiedClass(
            declaration: declaration,
            kind: classify(
              declaration,
              routeDestinationNames: routeDestinationNames,
            ),
          ),
        )
        .toList(growable: false);
  }

  NodeKind classify(
    DeclaredClass declaration, {
    Set<String> routeDestinationNames = const {},
  }) {
    final hierarchy = declaration.hierarchyTypeNames;
    final pathSegments = _pathSegments(declaration.filePath);

    if (_matchesAny(hierarchy, KindSignals.cubitBases)) {
      return NodeKind.cubit;
    }
    if (_matchesAny(hierarchy, KindSignals.blocBases)) {
      return NodeKind.bloc;
    }
    if (_matchesAny(hierarchy, KindSignals.changeNotifierBases)) {
      return NodeKind.changeNotifier;
    }
    if (_matchesAny(hierarchy, KindSignals.notifierBases)) {
      return NodeKind.provider;
    }

    final isWidget = _matchesAny(hierarchy, KindSignals.widgetBases);
    if (isWidget &&
        (routeDestinationNames.contains(declaration.name) ||
            _hasSegment(pathSegments, KindSignals.screenFolders))) {
      return NodeKind.screen;
    }

    if (_hasSegment(pathSegments, KindSignals.repositoryFolders)) {
      return NodeKind.repository;
    }
    if (_hasSegment(pathSegments, KindSignals.serviceFolders)) {
      return NodeKind.service;
    }
    if (_hasSegment(pathSegments, KindSignals.providerFolders)) {
      return NodeKind.provider;
    }

    if (isWidget) {
      return NodeKind.widget;
    }

    return NodeKind.other;
  }

  Map<NodeKind, int> countByKind(Iterable<ClassifiedClass> classified) {
    final counts = <NodeKind, int>{};
    for (final item in classified) {
      counts[item.kind] = (counts[item.kind] ?? 0) + 1;
    }
    return counts;
  }

  bool _matchesAny(Iterable<String> hierarchy, Set<String> bases) {
    for (final entry in hierarchy) {
      if (bases.contains(simpleTypeName(entry))) {
        return true;
      }
    }
    return false;
  }

  bool _hasSegment(Iterable<String> segments, Set<String> folderNames) {
    for (final segment in segments) {
      if (folderNames.contains(segment)) {
        return true;
      }
    }
    return false;
  }

  List<String> _pathSegments(String filePath) {
    final normalized = p.normalize(filePath).replaceAll('\\', '/');
    return normalized.split('/').where((s) => s.isNotEmpty).toList();
  }
}
