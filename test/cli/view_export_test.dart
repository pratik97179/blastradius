import 'dart:io';

import 'package:blastradius/blastradius.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('view method --export writes offline dashboard', () async {
    final out = Directory.systemTemp.createTempSync('blastradius-view-');
    addTearDown(() {
      if (out.existsSync()) {
        out.deleteSync(recursive: true);
      }
    });

    final code = await runBlastRadius([
      '-p',
      p.join('test', 'fixtures', 'dart_call_chain'),
      'view',
      'method',
      'fetchProfile',
      '--export',
      out.path,
      '--no-open',
    ]);

    expect(code, ExitCodes.success);
    expect(File(p.join(out.path, 'index.html')).existsSync(), isTrue);
    expect(File(p.join(out.path, 'payload.json')).existsSync(), isTrue);
    final payload = File(p.join(out.path, 'payload.json')).readAsStringSync();
    expect(payload, contains('UserService.fetchProfile'));
    expect(payload, contains('UserRepository'));
  });
}
