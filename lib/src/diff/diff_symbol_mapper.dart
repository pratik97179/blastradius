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

    final seeds = <String, GraphNode>{};

    for (final hunk in hunks) {
      final absolute = p.normalize(p.join(projectRoot, hunk.relativePath));
      final methods = ast.methods.where((method) {
        return p.equals(p.normalize(method.filePath), absolute) &&
            _overlaps(
              hunk.startLine,
              hunk.endLine,
              method.startLine,
              method.endLine == 0 ? method.startLine : method.endLine,
            );
      }).toList(growable: false);

      if (methods.isNotEmpty) {
        for (final method in methods) {
          final node = graph.findMethod(
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

      final classes = ast.classes.where((declaration) {
        return p.equals(p.normalize(declaration.filePath), absolute) &&
            _overlaps(
              hunk.startLine,
              hunk.endLine,
              declaration.startLine,
              declaration.endLine == 0
                  ? declaration.startLine
                  : declaration.endLine,
            );
      }).toList(growable: false);

      if (classes.isNotEmpty) {
        for (final declaration in classes) {
          for (final node in graph.nodes.values) {
            if (!node.isMethod &&
                node.name == declaration.name &&
                p.equals(p.normalize(node.filePath), absolute)) {
              seeds[node.id] = node;
            }
          }
        }
        continue;
      }

      for (final node in graph.nodes.values) {
        if (p.equals(p.normalize(node.filePath), absolute)) {
          seeds[node.id] = node;
        }
      }
    }

    return seeds.values.toList(growable: false);
  }

  bool _overlaps(int aStart, int aEnd, int bStart, int bEnd) {
    return aStart <= bEnd && bStart <= aEnd;
  }
}
