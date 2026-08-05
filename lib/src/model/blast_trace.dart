import 'blast_result.dart';

/// Result of a blast walk, including graph overlay metadata for visualization.
class BlastTrace {
  const BlastTrace({
    required this.result,
    required this.seedIds,
    required this.scoresByNodeId,
  });

  final BlastResult result;
  final Set<String> seedIds;
  final Map<String, double> scoresByNodeId;
}
