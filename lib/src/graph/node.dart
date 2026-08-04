import '../model/node_kind.dart';

class GraphNode {
  const GraphNode({
    required this.id,
    required this.name,
    required this.kind,
    required this.filePath,
    required this.isMethod,
    this.className,
  });

  final String id;
  final String name;
  final NodeKind kind;
  final String filePath;
  final bool isMethod;
  final String? className;

  String get displayName =>
      isMethod && className != null ? '$className.$name' : name;
}
