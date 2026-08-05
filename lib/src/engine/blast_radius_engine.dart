import '../graph/graph.dart';
import '../graph/node.dart';
import '../model/blast_result.dart';
import '../model/node_kind.dart';
import 'confidence_engine.dart';

class BlastRadiusEngine {
  BlastRadiusEngine({ConfidenceEngine? confidenceEngine})
      : _confidence = confidenceEngine ?? ConfidenceEngine();

  final ConfidenceEngine _confidence;

  static const _stateManagerKinds = {
    NodeKind.bloc,
    NodeKind.cubit,
    NodeKind.changeNotifier,
    NodeKind.provider,
  };

  BlastResult trace({
    required DependencyGraph graph,
    required List<GraphNode> seeds,
    List<String> candidateTestFiles = const [],
  }) {
    if (seeds.isEmpty) {
      return BlastResult(
        changed: const [],
        repositories: const [],
        stateManagers: const [],
        screens: const [],
        widgets: const [],
        services: const [],
        suggestedTests: const [],
        risk: RiskLevel.low,
        confidence: 0.0,
      );
    }

    final bestScore = <String, double>{};
    final queue = <String>[];

    for (final seed in seeds) {
      bestScore[seed.id] = 1.0;
      queue.add(seed.id);
    }

    var head = 0;
    while (head < queue.length) {
      final currentId = queue[head++];
      final currentScore = bestScore[currentId] ?? 0.0;

      for (final edge in graph.dependentsOf(currentId)) {
        final nextScore = currentScore * edge.confidence;
        final existing = bestScore[edge.fromId];
        if (existing != null && existing >= nextScore) {
          continue;
        }
        bestScore[edge.fromId] = nextScore;
        queue.add(edge.fromId);
      }
    }

    final seedIds = seeds.map((s) => s.id).toSet();
    final seedClassNames = <String>{
      for (final seed in seeds)
        if (seed.isMethod && seed.className != null)
          seed.className!
        else if (!seed.isMethod)
          seed.name,
    };
    final affected = bestScore.keys
        .map(graph.nodeById)
        .whereType<GraphNode>()
        .where((node) => !seedIds.contains(node.id))
        .where((node) {
          if (node.isMethod) {
            return true;
          }
          return !seedClassNames.contains(node.name);
        })
        .toList(growable: false);

    final repositories = _names(affected, NodeKind.repository);
    final services = _names(affected, NodeKind.service);
    final stateManagers = affected
        .where((n) => !n.isMethod && _stateManagerKinds.contains(n.kind))
        .map((n) => n.displayName)
        .toSet()
        .toList()
      ..sort();
    final screens = _names(affected, NodeKind.screen);
    final widgets = _names(affected, NodeKind.widget);

    final endpointScores = <double>[
      for (final node in affected)
        if (_isEndpoint(node)) bestScore[node.id] ?? 0.0,
    ];

    final suggestedTests = _suggestTests(
      affectedNames: [
        ...repositories,
        ...stateManagers,
        ...screens,
        ...seeds.map((s) => s.displayName),
      ],
      candidateTestFiles: candidateTestFiles,
    );

    return BlastResult(
      changed: seeds.map((s) => s.displayName).toSet().toList()..sort(),
      repositories: repositories,
      stateManagers: stateManagers,
      screens: screens,
      widgets: widgets,
      services: services,
      suggestedTests: suggestedTests,
      risk: _confidence.riskFor(
        screenCount: screens.length,
        surfaceCount: repositories.length +
            services.length +
            stateManagers.length +
            screens.length +
            widgets.length,
      ),
      confidence: _confidence.overall(endpointScores),
    );
  }

  bool _isEndpoint(GraphNode node) {
    if (node.isMethod) {
      return false;
    }
    return node.kind == NodeKind.screen ||
        node.kind == NodeKind.repository ||
        _stateManagerKinds.contains(node.kind);
  }

  List<String> _names(List<GraphNode> nodes, NodeKind kind) {
    return nodes
        .where((n) => !n.isMethod && n.kind == kind)
        .map((n) => n.displayName)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _suggestTests({
    required List<String> affectedNames,
    required List<String> candidateTestFiles,
  }) {
    if (candidateTestFiles.isEmpty || affectedNames.isEmpty) {
      return const [];
    }

    final needles = affectedNames
        .map(_toSnakeHint)
        .where((s) => s.isNotEmpty)
        .toSet();

    final matches = <String>[];
    for (final file in candidateTestFiles) {
      final base = file.split('/').last.split('\\').last.toLowerCase();
      for (final needle in needles) {
        if (base.contains(needle)) {
          matches.add(base.replaceAll('.dart', ''));
          break;
        }
      }
    }
    matches.sort();
    return matches;
  }

  String _toSnakeHint(String name) {
    final simple = name.contains('.') ? name.split('.').first : name;
    final buffer = StringBuffer();
    for (var i = 0; i < simple.length; i++) {
      final char = simple[i];
      final isUpper = char.toUpperCase() == char && char.toLowerCase() != char;
      if (isUpper && i > 0) {
        buffer.write('_');
      }
      buffer.write(char.toLowerCase());
    }
    return buffer.toString().replaceAll('_bloc', '').replaceAll('_screen', '');
  }
}
