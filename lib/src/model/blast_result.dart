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
}
