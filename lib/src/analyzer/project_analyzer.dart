import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../model/project_context.dart';

class ProjectDiscoveryException implements Exception {
  ProjectDiscoveryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProjectAnalyzer {
  static final List<Glob> _excludeGlobs = [
    Glob('**/.dart_tool/**'),
    Glob('**/build/**'),
    Glob('**/*.g.dart'),
    Glob('**/*.freezed.dart'),
    Glob('**/*.mocks.dart'),
    Glob('**/*.config.dart'),
  ];

  ProjectContext discover(String projectPath) {
    final root = _resolveRoot(projectPath);
    final pubspecFile = File(p.join(root, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      throw ProjectDiscoveryException(
        'No pubspec.yaml found at $root. Pass --project to a Dart or Flutter package root.',
      );
    }

    final yaml = _loadYaml(pubspecFile);
    final packageName = _readPackageName(yaml, pubspecFile.path);
    final isFlutter = _isFlutterProject(yaml);

    final dartFiles = _indexDartFiles(root);
    return ProjectContext(
      rootPath: root,
      packageName: packageName,
      pubspecPath: pubspecFile.path,
      dartFiles: dartFiles,
      isFlutter: isFlutter,
    );
  }

  String _resolveRoot(String projectPath) {
    final dir = Directory(p.normalize(p.absolute(projectPath)));
    if (!dir.existsSync()) {
      throw ProjectDiscoveryException('Project path does not exist: ${dir.path}');
    }
    return dir.path;
  }

  YamlMap _loadYaml(File pubspecFile) {
    try {
      final doc = loadYaml(pubspecFile.readAsStringSync());
      if (doc is! YamlMap) {
        throw ProjectDiscoveryException(
          'Invalid pubspec.yaml (expected a map): ${pubspecFile.path}',
        );
      }
      return doc;
    } on YamlException catch (e) {
      throw ProjectDiscoveryException(
        'Failed to parse pubspec.yaml: ${e.message}',
      );
    }
  }

  String _readPackageName(YamlMap yaml, String pubspecPath) {
    final name = yaml['name'];
    if (name is! String || name.isEmpty) {
      throw ProjectDiscoveryException(
        'pubspec.yaml is missing a package name: $pubspecPath',
      );
    }
    return name;
  }

  bool _isFlutterProject(YamlMap yaml) {
    if (yaml.containsKey('flutter')) {
      return true;
    }

    for (final section in ['dependencies', 'dev_dependencies']) {
      final map = yaml[section];
      if (map is YamlMap && map.containsKey('flutter')) {
        return true;
      }
    }

    final environment = yaml['environment'];
    if (environment is YamlMap && environment.containsKey('flutter')) {
      return true;
    }

    return false;
  }

  List<String> _indexDartFiles(String root) {
    final libDir = Directory(p.join(root, 'lib'));
    final testDir = Directory(p.join(root, 'test'));
    final files = <String>[];

    for (final dir in [libDir, testDir]) {
      if (!dir.existsSync()) {
        continue;
      }
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final relative = p.relative(entity.path, from: root);
        if (_isExcluded(relative)) {
          continue;
        }
        files.add(p.normalize(entity.path));
      }
    }

    files.sort();
    return files;
  }

  bool _isExcluded(String relativePosixPath) {
    final normalized = relativePosixPath.replaceAll('\\', '/');
    for (final glob in _excludeGlobs) {
      if (glob.matches(normalized)) {
        return true;
      }
    }
    return false;
  }
}
