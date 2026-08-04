import 'package:blastradius/blastradius.dart';
import 'package:test/test.dart';

void main() {
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

    test('acknowledges trace method as not implemented', () async {
      final code = await runBlastRadius([
        'trace',
        'method',
        'getPortfolio',
        '--project',
        '.',
      ]);
      expect(code, ExitCodes.notImplemented);
    });

    test('acknowledges diff as not implemented', () async {
      final code = await runBlastRadius(['diff']);
      expect(code, ExitCodes.notImplemented);
    });

    test('acknowledges analyze as not implemented', () async {
      final code = await runBlastRadius(['analyze', '-v']);
      expect(code, ExitCodes.notImplemented);
    });
  });
}
