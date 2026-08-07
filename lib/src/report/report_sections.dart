import '../model/blast_result.dart';

typedef ReportSection = ({String title, List<String> items, bool optional});

/// Ordered report sections shared by console and markdown renderers.
List<ReportSection> blastReportSections(BlastResult result) {
  return [
    if (result.changedFiles.isNotEmpty)
      (
        title: 'Changed Files',
        items: result.changedFiles,
        optional: false,
      ),
    (title: 'Changed', items: result.changed, optional: false),
    (
      title: 'Affected Repositories',
      items: result.repositories,
      optional: true,
    ),
    (title: 'Affected Services', items: result.services, optional: true),
    (
      title: 'Affected State Managers',
      items: result.stateManagers,
      optional: true,
    ),
    (title: 'Affected Screens', items: result.screens, optional: true),
    (title: 'Affected Widgets', items: result.widgets, optional: true),
    (title: 'Suggested Tests', items: result.suggestedTests, optional: true),
  ];
}
