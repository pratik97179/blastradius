import 'package:blastradius/src/cli/analysis_workflow.dart';
import 'package:blastradius/src/diff/blast_result_merger.dart';
import 'package:blastradius/src/diff/diff_symbol_mapper.dart';
import 'package:blastradius/src/diff/git_diff_parser.dart';
import 'package:blastradius/src/engine/blast_radius_engine.dart';
import 'package:blastradius/src/graph/edge.dart';
import 'package:blastradius/src/graph/graph.dart';
import 'package:blastradius/src/graph/node.dart';
import 'package:blastradius/src/model/ast_model.dart';
import 'package:blastradius/src/model/blast_result.dart';
import 'package:blastradius/src/model/node_kind.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('empty engine and empty merger share confidence 0.4', () {
    final engine = BlastRadiusEngine().trace(
      graph: DependencyGraph(nodes: const {}, edges: const []),
      seeds: const [],
    );
    final merged = BlastResultMerger().merge(const []);
    expect(engine.result.confidence, 0.4);
    expect(merged.confidence, engine.result.confidence);
    expect(merged.confidence, BlastResult.empty.confidence);
  });

  test('import/comment-only hunks do not seed whole files', () {
    final root = p.normalize('/app');
    final file = p.join(root, 'lib', 'a.dart');
    final classNode = GraphNode(
      id: '$file#Foo',
      name: 'Foo',
      kind: NodeKind.other,
      filePath: file,
      isMethod: false,
    );
    final methodNode = GraphNode(
      id: '$file#Foo.run',
      name: 'run',
      kind: NodeKind.other,
      filePath: file,
      isMethod: true,
      className: 'Foo',
    );
    final graph = DependencyGraph(
      nodes: {
        classNode.id: classNode,
        methodNode.id: methodNode,
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
      ast: AstModel(
        classes: [
          DeclaredClass(
            name: 'Foo',
            filePath: file,
            methods: const ['run'],
            startLine: 10,
            endLine: 20,
          ),
        ],
        methods: [
          DeclaredMethod(
            name: 'run',
            className: 'Foo',
            filePath: file,
            offset: 0,
            line: 12,
            endLine: 18,
          ),
        ],
        calls: const [],
      ),
      graph: graph,
      projectRoot: root,
      hunks: [
        DiffHunk(
          relativePath: p.join('lib', 'a.dart'),
          startLine: 1,
          endLine: 2,
        ),
      ],
    );

    expect(seeds, isEmpty);

    final traced = BlastRadiusEngine().trace(graph: graph, seeds: seeds);
    final attached = traced.result.withChangedFiles(const ['lib/a.dart']);
    expect(attached.confidence, 0.4);
    expect(attached.changedFiles, ['lib/a.dart']);
    expect(exitCodeForAnalysisError(StateError('x')), isNull);
  });
}
