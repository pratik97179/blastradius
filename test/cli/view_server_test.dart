import 'dart:convert';
import 'dart:io';

import 'package:blastradius/src/cli/package_paths.dart';
import 'package:blastradius/src/cli/view_server.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('serves dashboard index and payload JSON', () async {
    final dist = PackagePaths.dashboardDist();
    const payload = '{"ok":true,"graph":{"nodes":[],"edges":[]}}';
    final session = await ViewServer(
      distDir: dist,
      payloadJson: payload,
    ).start(port: 0);

    try {
      final index = await HttpClient().getUrl(Uri.parse(session.url));
      final indexResponse = await index.close();
      expect(indexResponse.statusCode, 200);
      final indexBody = await indexResponse.transform(utf8.decoder).join();
      expect(indexBody, contains('BlastRadius'));

      final api = await HttpClient()
          .getUrl(Uri.parse('${session.url}api/payload.json'));
      final apiResponse = await api.close();
      expect(apiResponse.statusCode, 200);
      final apiBody = await apiResponse.transform(utf8.decoder).join();
      expect(jsonDecode(apiBody)['ok'], isTrue);
    } finally {
      await session.close();
    }
  });

  test('exportDashboard writes payload.js and index injection', () async {
    final dist = PackagePaths.dashboardDist();
    final out = Directory.systemTemp.createTempSync('blastradius-export-');
    addTearDown(() {
      if (out.existsSync()) {
        out.deleteSync(recursive: true);
      }
    });

    const payload = '{"hello":"world"}';
    final exported = await exportDashboard(
      distDir: dist,
      payloadJson: payload,
      exportPath: out.path,
    );

    expect(File(p.join(exported.path, 'index.html')).existsSync(), isTrue);
    expect(File(p.join(exported.path, 'payload.json')).existsSync(), isTrue);
    final payloadJs =
        File(p.join(exported.path, 'payload.js')).readAsStringSync();
    expect(payloadJs, contains('window.__BLASTRADIUS_PAYLOAD__'));
    expect(payloadJs, contains('"hello":"world"'));

    final index = File(p.join(exported.path, 'index.html')).readAsStringSync();
    expect(index, contains('payload.js'));
  });
}
