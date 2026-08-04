import 'package:blastradius/src/analyzer/project_analyzer.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final analyzer = ProjectAnalyzer();
  final fixtures = p.join('test', 'fixtures');

  test('discovers Flutter project and indexes Dart sources', () {
    final root = p.join(fixtures, 'sample_flutter_app');
    final context = analyzer.discover(root);

    expect(context.packageName, 'sample_flutter_app');
    expect(context.dartFileCount, 3);
    expect(
      context.dartFiles.map(p.basename),
      containsAll(['main.dart', 'portfolio_service.dart', 'smoke_test.dart']),
    );
    expect(
      context.dartFiles.any((f) => f.endsWith('example.g.dart')),
      isFalse,
    );
  });

  test('rejects a plain Dart package', () {
    final root = p.join(fixtures, 'plain_dart_package');
    expect(
      () => analyzer.discover(root),
      throwsA(isA<ProjectDiscoveryException>()),
    );
  });

  test('rejects a missing path', () {
    expect(
      () => analyzer.discover(p.join(fixtures, 'does_not_exist')),
      throwsA(isA<ProjectDiscoveryException>()),
    );
  });
}
