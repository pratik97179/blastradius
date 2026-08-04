import 'package:blastradius/blastradius.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final fixture = p.join('test', 'fixtures', 'sample_flutter_app');

  group('runBlastRadius', () {
    test('prints version', () async {
      final code = await runBlastRadius(['--version']);
      expect(code, ExitCodes.success);
    });

    test('prints usage when given no args', () async {
      final code = await runBlastRadius([]);
      expect(code, ExitCodes.success);
    });

    test('returns usage error for unknown command', () async {
      final code = await runBlastRadius(['nope']);
      expect(code, ExitCodes.usageError);
    });

    test('returns usage error when method name is missing', () async {
      final code = await runBlastRadius(['trace', 'method']);
      expect(code, ExitCodes.usageError);
    });

    test('analyze discovers the fixture project', () async {
      final code = await runBlastRadius(['-p', fixture, 'analyze']);
      expect(code, ExitCodes.success);
    });

    test('rejects non-Flutter project roots', () async {
      final code = await runBlastRadius([
        '-p',
        p.join('test', 'fixtures', 'plain_dart_package'),
        'analyze',
      ]);
      expect(code, ExitCodes.projectError);
    });

    test('trace method returns a blast radius report', () async {
      final code = await runBlastRadius([
        '-p',
        fixture,
        'trace',
        'method',
        'getPortfolio',
      ]);
      expect(code, ExitCodes.success);
    });

    test('trace unknown method fails with usage error', () async {
      final code = await runBlastRadius([
        '-p',
        fixture,
        'trace',
        'method',
        'definitelyMissingMethodZz',
      ]);
      expect(code, ExitCodes.usageError);
    });

    test('diff validates project then reports not implemented', () async {
      final code = await runBlastRadius(['-p', fixture, 'diff']);
      expect(code, ExitCodes.notImplemented);
    });
  });
}
