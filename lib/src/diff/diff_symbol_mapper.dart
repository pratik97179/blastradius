import 'package:path/path.dart' as p;

import '../graph/graph.dart';
import '../graph/node.dart';
import '../model/ast_model.dart';
import 'git_diff_parser.dart';

class DiffSymbolMapper {
  List<GraphNode> mapToSeeds({
    required AstModel ast,
    required DependencyGraph graph,
    required List<DiffHunk> hunks,
    required String projectRoot,
  }) {
    if (hunks.isEmpty) {
      return const [];
    }

    final methodsByFile = <String, List<DeclaredMethod>>{};
    for (final method in ast.methods) {
      final key = p.normalize(method.filePath);
      methodsByFile.putIfAbsent(key, () => []).add(method);
    }

    final classesByFile = <String, List<DeclaredClass>>{};
    for (final declaration in ast.classes) {
      final key = p.normalize(declaration.filePath);
      classesByFile.putIfAbsent(key, () => []).add(declaration);
    }

    final seeds = <String, GraphNode>{};

    for (final hunk in hunks) {
      final absolute = p.normalize(p.join(projectRoot, hunk.relativePath));
      final methods = (methodsByFile[absolute] ?? const <DeclaredMethod>[])
          .where(
            (method) => _overlaps(
              hunk.startLine,
              hunk.endLine,
              method.startLine,
              method.endLine == 0 ? method.startLine : method.endLine,
            ),
          )
          .toList(growable: false);

      if (methods.isNotEmpty) {
        for (final method in methods) {
          final id = _methodId(method.filePath, method.className, method.name);
          final node = graph.nodeById(id) ??
              graph.findMethod(
                methodName: method.name,
                className: method.className,
                filePath: method.filePath,
              );
          if (node != null) {
            seeds[node.id] = node;
          }
        }
        continue;
      }

      final classes = (classesByFile[absolute] ?? const <DeclaredClass>[])
          .where(
            (declaration) => _overlaps(
              hunk.startLine,
              hunk.endLine,
              declaration.startLine,
              declaration.endLine == 0
                  ? declaration.startLine
                  : declaration.endLine,
            ),
          )
          .toList(growable: false);

      if (classes.isNotEmpty) {
        for (final declaration in classes) {
          final id = _classId(declaration.filePath, declaration.name);
          final node = graph.nodeById(id);
          if (node != null) {
            seeds[node.id] = node;
          }
        }
        continue;
      }

      // Import/comment-only hunks: prefer no seeds over seeding every node.
    }

    return seeds.values.toList(growable: false);
  }

  bool _overlaps(int aStart, int aEnd, int bStart, int bEnd) {
    return aStart <= bEnd && bStart <= aEnd;
  }

  String _classId(String filePath, String className) => '$filePath#$className';

  String _methodId(String filePath, String? className, String methodName) {
    if (className == null) {
      return '$filePath#$methodName';
    }
    return '$filePath#$className.$methodName';
  }
}
