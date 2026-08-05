import 'dart:io';

import 'package:blastradius/src/analyzer/ast_extractor.dart';
import 'package:blastradius/src/analyzer/classifiers.dart';
import 'package:blastradius/src/graph/edge.dart';
import 'package:blastradius/src/graph/graph_builder.dart';
import 'package:blastradius/src/model/project_context.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final root = p.normalize(
    p.absolute(p.join('test', 'fixtures', 'dart_call_chain')),
  );

  setUpAll(() async {
    final result = await Process.run(
      'dart',
      ['pub', 'get'],
      workingDirectory: root,
    );
    expect(result.exitCode, 0, reason: '${result.stderr}');
  });

  test('builds call chain Service <- Repository <- Loader', () async {
    final lib = p.join(root, 'lib');
    final dartFiles = Directory(lib)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => p.normalize(f.path))
        .toList()
      ..sort();

    final context = ProjectContext(
      rootPath: root,
      packageName: 'dart_call_chain',
      pubspecPath: p.join(root, 'pubspec.yaml'),
      dartFiles: dartFiles,
    );

    final ast = await AstExtractor().extract(context);
    final classified = ClassClassifier().classifyAll(
      ast.classes,
      routeDestinationNames: ast.routeDestinationNames,
    );
    final graph = GraphBuilder().build(ast: ast, classified: classified);

    expect(graph.nodeCount, greaterThanOrEqualTo(6));
    expect(graph.edgeCount, greaterThanOrEqualTo(2));

    final fetchProfile = graph.findMethod(
      methodName: 'fetchProfile',
      className: 'UserService',
    );
    expect(fetchProfile, isNotNull);

    final directDependents = graph.dependentsOf(fetchProfile!.id);
    expect(
      directDependents.any((edge) {
        final from = graph.nodeById(edge.fromId);
        return edge.kind == EdgeKind.calls &&
            from?.className == 'UserRepository' &&
            from?.name == 'loadProfile';
      }),
      isTrue,
    );

    final loadProfile = graph.findMethod(
      methodName: 'loadProfile',
      className: 'UserRepository',
    );
    expect(loadProfile, isNotNull);

    final loaderDependents = graph.dependentsOf(loadProfile!.id);
    expect(
      loaderDependents.any((edge) {
        final from = graph.nodeById(edge.fromId);
        return edge.kind == EdgeKind.calls &&
            from?.className == 'ProfileLoader' &&
            from?.name == 'load';
      }),
      isTrue,
    );

    final serviceClass = graph.nodes.values.firstWhere(
      (n) => !n.isMethod && n.name == 'UserService',
    );
    final repoClass = graph.nodes.values.firstWhere(
      (n) => !n.isMethod && n.name == 'UserRepository',
    );
    expect(
      graph.dependentsOf(serviceClass.id).any((e) => e.fromId == repoClass.id),
      isTrue,
    );
  });
}
