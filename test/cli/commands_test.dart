import 'package:blastradius/blastradius.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final flutterFixture = p.join('test', 'fixtures', 'sample_flutter_app');
  final dartFixture = p.join('test', 'fixtures', 'dart_call_chain');

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

    test('analyze discovers the Flutter fixture project', () async {
      final code = await runBlastRadius(['-p', flutterFixture, 'analyze']);
      expect(code, ExitCodes.success);
    });

    test('analyze accepts a plain Dart package', () async {
      final code = await runBlastRadius([
        '-p',
        p.join('test', 'fixtures', 'plain_dart_package'),
        'analyze',
      ]);
      expect(code, ExitCodes.success);
    });

    test('analyze and trace work on dart_call_chain', () async {
      final analyze = await runBlastRadius(['-p', dartFixture, 'analyze']);
      expect(analyze, ExitCodes.success);

      final trace = await runBlastRadius([
        '-p',
        dartFixture,
        'trace',
        'method',
        'getPortfolio',
      ]);
      expect(trace, ExitCodes.success);
    });

    test('trace method returns a blast radius report', () async {
      final code = await runBlastRadius([
        '-p',
        flutterFixture,
        'trace',
        'method',
        'getPortfolio',
      ]);
      expect(code, ExitCodes.success);
    });

    test('trace unknown method fails with usage error', () async {
      final code = await runBlastRadius([
        '-p',
        flutterFixture,
        'trace',
        'method',
        'definitelyMissingMethodZz',
      ]);
      expect(code, ExitCodes.usageError);
    });

    test('diff runs against the enclosing git repository', () async {
      final code = await runBlastRadius(['-p', flutterFixture, 'diff']);
      expect(code, ExitCodes.success);
    });
  });
}
