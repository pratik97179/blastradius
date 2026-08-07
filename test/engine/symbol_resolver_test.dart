import 'package:blastradius/src/engine/symbol_resolver.dart';
import 'package:blastradius/src/graph/graph.dart';
import 'package:blastradius/src/graph/node.dart';
import 'package:blastradius/src/model/node_kind.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final root = p.normalize('/app');
  final fileA = p.join(root, 'lib', 'a.dart');
  final fileB = p.join(root, 'lib', 'b.dart');

  DependencyGraph graphWithDuplicateMethods() {
    final a = GraphNode(
      id: '$fileA#Service.run',
      name: 'run',
      kind: NodeKind.service,
      filePath: fileA,
      isMethod: true,
      className: 'Service',
    );
    final b = GraphNode(
      id: '$fileB#Helper.run',
      name: 'run',
      kind: NodeKind.other,
      filePath: fileB,
      isMethod: true,
      className: 'Helper',
    );
    final classA = GraphNode(
      id: '$fileA#Service',
      name: 'Service',
      kind: NodeKind.service,
      filePath: fileA,
      isMethod: false,
    );
    final classB = GraphNode(
      id: '$fileB#Service',
      name: 'Service',
      kind: NodeKind.other,
      filePath: fileB,
      isMethod: false,
    );
    return DependencyGraph(
      nodes: {
        a.id: a,
        b.id: b,
        classA.id: classA,
        classB.id: classB,
      },
      edges: const [],
    );
  }

  test('ambiguous method without file throws', () {
    final graph = graphWithDuplicateMethods();
    expect(
      () => SymbolResolver().resolveMethod(graph, methodName: 'run'),
      throwsA(isA<SymbolResolutionException>()),
    );
  });

  test('relative file disambiguates method', () {
    final graph = graphWithDuplicateMethods();
    final matches = SymbolResolver().resolveMethod(
      graph,
      methodName: 'run',
      filePath: 'lib/a.dart',
      projectRoot: root,
    );
    expect(matches, hasLength(1));
    expect(matches.single.className, 'Service');
  });

  test('ambiguous class without file throws', () {
    final graph = graphWithDuplicateMethods();
    expect(
      () => SymbolResolver().resolveClass(graph, className: 'Service'),
      throwsA(isA<SymbolResolutionException>()),
    );
  });
}
