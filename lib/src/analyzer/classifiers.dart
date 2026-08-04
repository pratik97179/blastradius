import '../model/ast_model.dart';
import '../model/node_kind.dart';

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
  List<ClassifiedClass> classifyAll(Iterable<DeclaredClass> classes) {
    return classes
        .map(
          (declaration) => ClassifiedClass(
            declaration: declaration,
            kind: classify(declaration),
          ),
        )
        .toList(growable: false);
  }

  NodeKind classify(DeclaredClass declaration) {
    final name = declaration.name;
    final hierarchy = declaration.hierarchyTypeNames;

    if (_matchesType(hierarchy, 'Cubit') || name.endsWith('Cubit')) {
      return NodeKind.cubit;
    }
    if (_matchesType(hierarchy, 'Bloc') || name.endsWith('Bloc')) {
      return NodeKind.bloc;
    }
    if (_isScreenName(name)) {
      return NodeKind.screen;
    }
    if (_matchesType(hierarchy, 'ChangeNotifier') ||
        name.endsWith('ChangeNotifier') ||
        name.endsWith('Notifier')) {
      return NodeKind.changeNotifier;
    }
    if (_matchesType(hierarchy, 'StatelessWidget') ||
        _matchesType(hierarchy, 'StatefulWidget') ||
        _matchesType(hierarchy, 'Widget')) {
      return NodeKind.widget;
    }
    if (name.endsWith('Repository')) {
      return NodeKind.repository;
    }
    if (name.endsWith('Service')) {
      return NodeKind.service;
    }
    if (name.endsWith('Provider')) {
      return NodeKind.provider;
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

  bool _isScreenName(String name) =>
      name.endsWith('Screen') || name.endsWith('Page');

  bool _matchesType(Iterable<String> hierarchy, String typeName) {
    for (final entry in hierarchy) {
      final simple = _simpleTypeName(entry);
      if (simple == typeName) {
        return true;
      }
    }
    return false;
  }

  String _simpleTypeName(String typeSource) {
    final withoutArgs = typeSource.split('<').first.trim();
    final dotted = withoutArgs.split('.');
    return dotted.last.trim();
  }
}
