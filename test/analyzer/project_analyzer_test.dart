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
    expect(context.dartFileCount, greaterThanOrEqualTo(12));
    expect(
      context.dartFiles.map((f) => p.relative(f, from: root)),
      containsAll([
        p.join('lib', 'services', 'portfolio_service.dart'),
        p.join('lib', 'repositories', 'portfolio_repository.dart'),
        p.join('lib', 'bloc', 'portfolio_bloc.dart'),
        p.join('lib', 'screens', 'portfolio_screen.dart'),
        p.join('lib', 'screens', 'dashboard_screen.dart'),
        p.join('lib', 'screens', 'stock_details_screen.dart'),
        p.join('lib', 'router', 'app_router.dart'),
        p.join('test', 'portfolio_bloc_test.dart'),
        p.join('test', 'portfolio_screen_test.dart'),
      ]),
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
