import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class PackagePathsException implements Exception {
  PackagePathsException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PackagePaths {
  /// Resolves the BlastRadius package root that contains `web/dashboard/dist`.
  static Directory root() {
    final candidates = <Directory>[];

    if (Platform.script.scheme == 'file') {
      var dir = File(Platform.script.toFilePath()).parent;
      for (var i = 0; i < 8; i++) {
        candidates.add(dir);
        final parent = dir.parent;
        if (parent.path == dir.path) {
          break;
        }
        dir = parent;
      }
    }
    candidates.add(Directory.current);

    for (final dir in candidates) {
      if (_isBlastRadiusRoot(dir)) {
        return dir;
      }
    }

    throw PackagePathsException(
      'Could not locate BlastRadius package root with web/dashboard/dist. '
      'Run from the repo or rebuild the dashboard (`cd web/dashboard && npm run build`).',
    );
  }

  static Directory dashboardDist() {
    final dist = Directory(p.join(root().path, 'web', 'dashboard', 'dist'));
    if (!dist.existsSync()) {
      throw PackagePathsException(
        'Dashboard build missing at ${dist.path}. '
        'Run: cd web/dashboard && npm install && npm run build',
      );
    }
    return dist;
  }

  static bool _isBlastRadiusRoot(Directory dir) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    final dist = Directory(p.join(dir.path, 'web', 'dashboard', 'dist'));
    if (!pubspec.existsSync() || !dist.existsSync()) {
      return false;
    }
    try {
      final doc = loadYaml(pubspec.readAsStringSync());
      return doc is YamlMap && doc['name'] == 'blastradius';
    } on Object {
      return false;
    }
  }
}
