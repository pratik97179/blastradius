import 'dart:io';

import 'package:blastradius/src/analyzer/analysis_pipeline.dart';
import 'package:blastradius/src/engine/blast_radius_engine.dart';
import 'package:blastradius/src/engine/symbol_resolver.dart';
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

  test('traces getPortfolio reverse dependents through the call chain', () async {
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

    final snapshot = await AnalysisPipeline().run(context);
    final seeds = SymbolResolver().resolveMethod(
      snapshot.graph,
      methodName: 'getPortfolio',
    );
    final result = BlastRadiusEngine().trace(
      graph: snapshot.graph,
      seeds: seeds,
    );

    expect(result.changed, contains('PortfolioService.getPortfolio'));
    expect(result.repositories, contains('PortfolioRepository'));
    expect(result.services, isEmpty);
  });
}
