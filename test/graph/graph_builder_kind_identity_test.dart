import 'package:blastradius/src/analyzer/classifiers.dart';
import 'package:blastradius/src/graph/edge.dart';
import 'package:blastradius/src/graph/graph_builder.dart';
import 'package:blastradius/src/model/ast_model.dart';
import 'package:blastradius/src/model/node_kind.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('duplicate class names keep file-scoped kinds', () {
    final serviceFile = p.join('/app', 'lib', 'services', 'gateway.dart');
    final otherFile = p.join('/app', 'lib', 'util', 'gateway.dart');

    final serviceClass = DeclaredClass(
      name: 'Gateway',
      filePath: serviceFile,
      methods: const ['ping'],
      startLine: 1,
      endLine: 10,
    );
    final otherClass = DeclaredClass(
      name: 'Gateway',
      filePath: otherFile,
      methods: const ['ping'],
      mixinNames: const ['SomeMixin'],
      startLine: 1,
      endLine: 10,
    );
    final mixinClass = DeclaredClass(
      name: 'SomeMixin',
      filePath: p.join('/app', 'lib', 'util', 'mixin.dart'),
      methods: const [],
      startLine: 1,
      endLine: 5,
    );

    final ast = AstModel(
      classes: [serviceClass, otherClass, mixinClass],
      methods: [
        DeclaredMethod(
          name: 'ping',
          className: 'Gateway',
          filePath: serviceFile,
          offset: 0,
          line: 3,
          endLine: 5,
        ),
        DeclaredMethod(
          name: 'ping',
          className: 'Gateway',
          filePath: otherFile,
          offset: 0,
          line: 3,
          endLine: 5,
        ),
      ],
      calls: const [],
    );

    final classified = [
      ClassifiedClass(declaration: serviceClass, kind: NodeKind.service),
      ClassifiedClass(declaration: otherClass, kind: NodeKind.other),
      ClassifiedClass(declaration: mixinClass, kind: NodeKind.other),
    ];

    final graph = GraphBuilder().build(ast: ast, classified: classified);
    final serviceNode = graph.nodeById('$serviceFile#Gateway');
    final otherNode = graph.nodeById('$otherFile#Gateway');

    expect(serviceNode?.kind, NodeKind.service);
    expect(otherNode?.kind, NodeKind.other);

    final mixinEdge = graph.edges.any(
      (e) =>
          e.fromId == otherNode!.id &&
          e.toId.endsWith('#SomeMixin') &&
          e.kind == EdgeKind.mixinType,
    );
    expect(mixinEdge, isTrue);
  });
}
