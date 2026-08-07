import 'dart:io';

import 'package:blastradius/blastradius.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('packageVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final doc = loadYaml(pubspec);
    expect(doc, isA<YamlMap>());
    expect((doc as YamlMap)['version'], packageVersion);
  });
}
