import 'dart:io';

import 'package:blastradius/src/analyzer/ast_extractor.dart';
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
    expect(
      result.exitCode,
      0,
      reason: 'dart pub get failed:\n${result.stderr}',
    );
  });

  test('extracts classes, methods, and resolved getPortfolio call', () async {
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

    expect(
      ast.classes.map((c) => c.name),
      containsAll([
        'PortfolioService',
        'PortfolioRepository',
        'PortfolioLoader',
      ]),
    );
    expect(
      ast.methods.map((m) => m.qualifiedName),
      containsAll([
        'PortfolioService.getPortfolio',
        'PortfolioRepository.fetchHoldings',
        'PortfolioLoader.load',
      ]),
    );

    final portfolioCalls = ast.calls.where(
      (c) => c.targetName == 'getPortfolio' && c.isResolved,
    );
    expect(portfolioCalls, isNotEmpty);
    expect(
      portfolioCalls.any(
        (c) =>
            c.fromClass == 'PortfolioRepository' &&
            c.fromMethod == 'fetchHoldings' &&
            c.targetClass == 'PortfolioService',
      ),
      isTrue,
    );
  });
}
