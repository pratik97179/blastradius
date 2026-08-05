import 'dart:convert';
import 'dart:io';

import 'package:blastradius/src/analyzer/analysis_pipeline.dart';
import 'package:blastradius/src/analyzer/project_analyzer.dart';
import 'package:blastradius/src/engine/blast_radius_engine.dart';
import 'package:blastradius/src/engine/symbol_resolver.dart';
import 'package:blastradius/src/report/visual_payload.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('VisualPayload', () {
    test('fromTrace includes seed and affected nodes for dart_call_chain',
        () async {
      final root = p.join('test', 'fixtures', 'dart_call_chain');
      await _pubGet(root);
      final context = ProjectAnalyzer().discover(root);
      final snapshot = await AnalysisPipeline().run(context);
      final seeds = SymbolResolver().resolveMethod(
        snapshot.graph,
        methodName: 'fetchProfile',
      );
      final trace = BlastRadiusEngine().trace(
        graph: snapshot.graph,
        seeds: seeds,
      );

      final payload = VisualPayload.fromTrace(
        context: context,
        graph: snapshot.graph,
        trace: trace,
        command: 'trace',
        generatedAt: DateTime.utc(2026, 1, 1),
      );
      final decoded = jsonDecode(payload.toJson()) as Map<String, dynamic>;

      expect(decoded['meta']['packageName'], 'dart_call_chain');
      expect(decoded['meta']['platform'], 'dart');
      expect(decoded['meta']['command'], 'trace');
      expect(decoded['summary']['changed'], contains('UserService.fetchProfile'));

      final nodes = (decoded['graph']['nodes'] as List).cast<Map<String, dynamic>>();
      expect(nodes.any((n) => n['role'] == 'seed'), isTrue);
      expect(nodes.any((n) => n['role'] == 'affected'), isTrue);
      expect(
        nodes.any((n) => (n['label'] as String).contains('UserRepository')),
        isTrue,
      );

      final edges = decoded['graph']['edges'] as List;
      expect(edges, isNotEmpty);
    });

    test('fromTrace highlights shop pages for fetchItems', () async {
      final root = p.join('test', 'fixtures', 'shop_flutter_app');
      await _pubGet(root);
      final context = ProjectAnalyzer().discover(root);
      final snapshot = await AnalysisPipeline().run(context);
      final seeds = SymbolResolver().resolveMethod(
        snapshot.graph,
        methodName: 'fetchItems',
      );
      final trace = BlastRadiusEngine().trace(
        graph: snapshot.graph,
        seeds: seeds,
      );

      final payload = VisualPayload.fromTrace(
        context: context,
        graph: snapshot.graph,
        trace: trace,
        command: 'trace',
      );
      final decoded = jsonDecode(payload.toJson()) as Map<String, dynamic>;
      final labels = (decoded['graph']['nodes'] as List)
          .map((n) => (n as Map)['label'] as String)
          .toSet();

      expect(labels, contains('CatalogService.fetchItems'));
      expect(labels, contains('CatalogPage'));
      expect(labels, contains('CartPage'));
      expect(decoded['summary']['affected']['screens'], contains('CatalogPage'));
    });

    test('fromFullGraph includes every node as context', () async {
      final root = p.join('test', 'fixtures', 'dart_call_chain');
      await _pubGet(root);
      final context = ProjectAnalyzer().discover(root);
      final snapshot = await AnalysisPipeline().run(context);

      final payload = VisualPayload.fromFullGraph(
        context: context,
        graph: snapshot.graph,
        command: 'analyze',
      );
      final decoded = jsonDecode(payload.toJson()) as Map<String, dynamic>;
      final nodes = (decoded['graph']['nodes'] as List).cast<Map<String, dynamic>>();

      expect(nodes.length, snapshot.graph.nodeCount);
      expect(nodes.every((n) => n['role'] == 'context'), isTrue);
      expect(decoded['graph']['edges'], hasLength(snapshot.graph.edgeCount));
    });
  });
}

Future<void> _pubGet(String root) async {
  final result = await Process.run(
    'dart',
    ['pub', 'get'],
    workingDirectory: root,
  );
  expect(result.exitCode, 0, reason: '${result.stderr}');
}
