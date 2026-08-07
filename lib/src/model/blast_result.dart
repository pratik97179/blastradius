enum RiskLevel { low, medium, high }

extension RiskLevelLabel on RiskLevel {
  String get label => switch (this) {
        RiskLevel.low => 'LOW',
        RiskLevel.medium => 'MEDIUM',
        RiskLevel.high => 'HIGH',
      };
}

class BlastResult {
  const BlastResult({
    required this.changed,
    required this.repositories,
    required this.stateManagers,
    required this.screens,
    required this.widgets,
    required this.services,
    required this.suggestedTests,
    required this.risk,
    required this.confidence,
    this.changedFiles = const [],
  });

  /// Empty blast with advisory confidence matching [ConfidenceEngine.overall].
  static const empty = BlastResult(
    changed: [],
    repositories: [],
    stateManagers: [],
    screens: [],
    widgets: [],
    services: [],
    suggestedTests: [],
    risk: RiskLevel.low,
    confidence: 0.4,
  );

  final List<String> changed;
  final List<String> changedFiles;
  final List<String> repositories;
  final List<String> stateManagers;
  final List<String> screens;
  final List<String> widgets;
  final List<String> services;
  final List<String> suggestedTests;
  final RiskLevel risk;
  final double confidence;

  bool get isEmpty =>
      repositories.isEmpty &&
      stateManagers.isEmpty &&
      screens.isEmpty &&
      widgets.isEmpty &&
      services.isEmpty;

  BlastResult copyWith({
    List<String>? changed,
    List<String>? changedFiles,
    List<String>? repositories,
    List<String>? stateManagers,
    List<String>? screens,
    List<String>? widgets,
    List<String>? services,
    List<String>? suggestedTests,
    RiskLevel? risk,
    double? confidence,
  }) {
    return BlastResult(
      changed: changed ?? this.changed,
      changedFiles: changedFiles ?? this.changedFiles,
      repositories: repositories ?? this.repositories,
      stateManagers: stateManagers ?? this.stateManagers,
      screens: screens ?? this.screens,
      widgets: widgets ?? this.widgets,
      services: services ?? this.services,
      suggestedTests: suggestedTests ?? this.suggestedTests,
      risk: risk ?? this.risk,
      confidence: confidence ?? this.confidence,
    );
  }

  BlastResult withChangedFiles(List<String> files) {
    final sorted = files.toList()..sort();
    return copyWith(changedFiles: sorted);
  }

  Map<String, Object?> toJsonMap() {
    return {
      'changed': changed,
      'changedFiles': changedFiles,
      'affected': <String, Object?>{
        'repositories': repositories,
        'services': services,
        'stateManagers': stateManagers,
        'screens': screens,
        'widgets': widgets,
      },
      'suggestedTests': suggestedTests,
      'risk': risk.label,
      'confidence': double.parse(confidence.toStringAsFixed(4)),
      'confidencePercent': (confidence * 100).round(),
      'empty': isEmpty,
    };
  }
}
