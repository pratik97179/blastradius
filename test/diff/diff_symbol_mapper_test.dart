import 'package:blastradius/src/diff/diff_symbol_mapper.dart';
import 'package:blastradius/src/diff/git_diff_parser.dart';
import 'package:blastradius/src/graph/edge.dart';
import 'package:blastradius/src/graph/graph.dart';
import 'package:blastradius/src/graph/node.dart';
import 'package:blastradius/src/model/ast_model.dart';
import 'package:blastradius/src/model/node_kind.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('maps overlapping hunk lines to method seeds', () {
    final root = p.normalize('/app');
    final file = p.join(root, 'lib', 'service.dart');

    final ast = AstModel(
      classes: [
        DeclaredClass(
          name: 'PortfolioService',
          filePath: file,
          methods: const ['getPortfolio'],
          startLine: 1,
          endLine: 20,
        ),
      ],
      methods: [
        DeclaredMethod(
          name: 'getPortfolio',
          className: 'PortfolioService',
          filePath: file,
          offset: 10,
          line: 5,
          endLine: 12,
        ),
      ],
      calls: const [],
    );

    final methodNode = GraphNode(
      id: '$file#PortfolioService.getPortfolio',
      name: 'getPortfolio',
      kind: NodeKind.service,
      filePath: file,
      isMethod: true,
      className: 'PortfolioService',
    );
    final classNode = GraphNode(
      id: '$file#PortfolioService',
      name: 'PortfolioService',
      kind: NodeKind.service,
      filePath: file,
      isMethod: false,
    );
    final graph = DependencyGraph(
      nodes: {
        methodNode.id: methodNode,
        classNode.id: classNode,
      },
      edges: [
        GraphEdge(
          fromId: classNode.id,
          toId: methodNode.id,
          kind: EdgeKind.uses,
          confidence: 1.0,
        ),
      ],
    );

    final seeds = DiffSymbolMapper().mapToSeeds(
      ast: ast,
      graph: graph,
      projectRoot: root,
      hunks: [
        DiffHunk(
          relativePath: p.join('lib', 'service.dart'),
          startLine: 8,
          endLine: 9,
        ),
      ],
    );

    expect(seeds, hasLength(1));
    expect(seeds.single.displayName, 'PortfolioService.getPortfolio');
  });
}
