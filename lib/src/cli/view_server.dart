import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

class ViewServer {
  ViewServer({
    required this.distDir,
    required this.payloadJson,
  });

  final Directory distDir;
  final String payloadJson;

  Future<ViewServerSession> start({int port = 7423}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    // Cancelled in ViewServerSession.close().
    // ignore: cancel_subscriptions
    final subscription = server.listen(_handle);
    return ViewServerSession(
      server: server,
      subscription: subscription,
      url: 'http://127.0.0.1:${server.port}/',
    );
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      final path = request.uri.path;
      if (path == '/api/payload.json') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(payloadJson);
        await request.response.close();
        return;
      }

      final relative = path == '/' ? 'index.html' : path.substring(1);
      final distPath = p.normalize(distDir.absolute.path);
      final file = File(p.normalize(p.join(distPath, relative)));
      final filePath = p.normalize(file.absolute.path);
      if (!p.isWithin(distPath, filePath)) {
        request.response.statusCode = HttpStatus.forbidden;
        await request.response.close();
        return;
      }

      if (!file.existsSync() || file.statSync().type != FileSystemEntityType.file) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = _contentTypeFor(file.path);
      await request.response.addStream(file.openRead());
      await request.response.close();
    } on Object {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } on Object {
        // Ignore secondary close failures.
      }
    }
  }

  ContentType _contentTypeFor(String path) {
    final ext = p.extension(path).toLowerCase();
    return switch (ext) {
      '.html' => ContentType.html,
      '.js' => ContentType('text', 'javascript', charset: 'utf-8'),
      '.css' => ContentType('text', 'css', charset: 'utf-8'),
      '.json' => ContentType.json,
      '.svg' => ContentType('image', 'svg+xml'),
      '.png' => ContentType('image', 'png'),
      '.woff2' => ContentType('font', 'woff2'),
      _ => ContentType.binary,
    };
  }
}

class ViewServerSession {
  ViewServerSession({
    required this.server,
    required this.subscription,
    required this.url,
  });

  final HttpServer server;
  final StreamSubscription<HttpRequest> subscription;
  final String url;

  int get port => server.port;

  Future<void> close() async {
    await subscription.cancel();
    await server.close(force: true);
  }
}

Future<void> openBrowser(String url) async {
  if (Platform.isMacOS) {
    await Process.run('open', [url]);
    return;
  }
  if (Platform.isWindows) {
    await Process.run('cmd', ['/c', 'start', '', url]);
    return;
  }
  await Process.run('xdg-open', [url]);
}

/// Copies the dashboard dist and injects the payload for offline viewing.
Future<Directory> exportDashboard({
  required Directory distDir,
  required String payloadJson,
  required String exportPath,
}) async {
  final target = Directory(p.normalize(p.absolute(exportPath)));
  if (target.existsSync()) {
    target.deleteSync(recursive: true);
  }
  target.createSync(recursive: true);

  await _copyDir(distDir, target);

  final payloadFile = File(p.join(target.path, 'payload.json'));
  await payloadFile.writeAsString(payloadJson);

  final payloadJs = File(p.join(target.path, 'payload.js'));
  await payloadJs.writeAsString(
    'window.__BLASTRADIUS_PAYLOAD__ = $payloadJson;\n',
  );

  final indexFile = File(p.join(target.path, 'index.html'));
  if (indexFile.existsSync()) {
    var html = await indexFile.readAsString();
    const marker = '<script type="module"';
    const inject = '<script src="./payload.js"></script>\n    $marker';
    if (html.contains(marker) && !html.contains('payload.js')) {
      html = html.replaceFirst(marker, inject);
      await indexFile.writeAsString(html);
    } else if (!html.contains('payload.js')) {
      html = html.replaceFirst(
        '</head>',
        '  <script src="./payload.js"></script>\n  </head>',
      );
      await indexFile.writeAsString(html);
    }
  }

  return target;
}

Future<void> _copyDir(Directory from, Directory to) async {
  await for (final entity in from.list(recursive: true, followLinks: false)) {
    final relative = p.relative(entity.path, from: from.path);
    final destPath = p.join(to.path, relative);
    if (entity is Directory) {
      await Directory(destPath).create(recursive: true);
    } else if (entity is File) {
      await File(destPath).parent.create(recursive: true);
      await entity.copy(destPath);
    }
  }
}
