import 'package:path/path.dart' as p;

import '../graph/graph.dart';
import '../graph/node.dart';

class SymbolResolutionException implements Exception {
  SymbolResolutionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SymbolResolver {
  List<GraphNode> resolveMethod(
    DependencyGraph graph, {
    required String methodName,
    String? filePath,
    String? projectRoot,
  }) {
    final normalizedFile = _normalizeFile(filePath, projectRoot);
    final matches = graph.nodes.values.where((node) {
      if (!node.isMethod || node.name != methodName) {
        return false;
      }
      if (normalizedFile != null &&
          !_filesEqual(node.filePath, normalizedFile)) {
        return false;
      }
      return true;
    }).toList(growable: false);

    if (matches.isEmpty) {
      throw SymbolResolutionException(
        'No method named "$methodName" found'
        '${normalizedFile != null ? ' in $normalizedFile' : ''}.',
      );
    }
    if (matches.length > 1 && normalizedFile == null) {
      final options = matches.map((m) => m.displayName).join(', ');
      throw SymbolResolutionException(
        'Ambiguous method "$methodName". Matches: $options. Pass --file.',
      );
    }
    return matches;
  }

  List<GraphNode> resolveClass(
    DependencyGraph graph, {
    required String className,
    String? filePath,
    String? projectRoot,
  }) {
    final normalizedFile = _normalizeFile(filePath, projectRoot);
    final matches = graph.nodes.values.where((node) {
      if (node.isMethod || node.name != className) {
        return false;
      }
      if (normalizedFile != null &&
          !_filesEqual(node.filePath, normalizedFile)) {
        return false;
      }
      return true;
    }).toList(growable: false);

    if (matches.isEmpty) {
      throw SymbolResolutionException(
        'No class named "$className" found'
        '${normalizedFile != null ? ' in $normalizedFile' : ''}.',
      );
    }
    if (matches.length > 1 && normalizedFile == null) {
      final options = matches.map((m) => m.filePath).join(', ');
      throw SymbolResolutionException(
        'Ambiguous class "$className". Files: $options. Pass --file.',
      );
    }
    return matches;
  }

  List<GraphNode> resolveFile(
    DependencyGraph graph, {
    required String filePath,
    required String projectRoot,
  }) {
    final normalizedFile = _normalizeFile(filePath, projectRoot);
    if (normalizedFile == null) {
      throw SymbolResolutionException('Missing file path.');
    }

    final matches = graph.nodes.values
        .where((node) => _filesEqual(node.filePath, normalizedFile))
        .toList(growable: false);

    if (matches.isEmpty) {
      throw SymbolResolutionException(
        'No graph nodes found for file $normalizedFile.',
      );
    }
    return matches;
  }

  String? _normalizeFile(String? filePath, String? projectRoot) {
    if (filePath == null || filePath.isEmpty) {
      return null;
    }
    if (p.isAbsolute(filePath)) {
      return p.normalize(filePath);
    }
    if (projectRoot == null) {
      return p.normalize(filePath);
    }
    return p.normalize(p.join(projectRoot, filePath));
  }

  bool _filesEqual(String a, String b) => p.equals(p.normalize(a), p.normalize(b));
}
