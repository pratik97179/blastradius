import 'package:blastradius/src/diff/git_diff_parser.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('parses unified diff hunks under the project root', () {
    final gitRoot = p.normalize('/repo');
    final projectRoot = p.normalize('/repo/app');
    const diff = '''
diff --git a/app/lib/services/portfolio_service.dart b/app/lib/services/portfolio_service.dart
--- a/app/lib/services/portfolio_service.dart
+++ b/app/lib/services/portfolio_service.dart
@@ -4,0 +5,2 @@ class PortfolioService {
+  // changed
+  Future<List<Holding>> getPortfolio() async {
diff --git a/other/lib/main.dart b/other/lib/main.dart
--- a/other/lib/main.dart
+++ b/other/lib/main.dart
@@ -1 +1 @@
-old
+new
''';

    final hunks = GitDiffParser().parseDiffOutput(
      diff,
      gitRoot: gitRoot,
      projectRoot: projectRoot,
    );

    expect(hunks, hasLength(1));
    expect(hunks.single.relativePath, p.join('lib', 'services', 'portfolio_service.dart'));
    expect(hunks.single.startLine, 5);
    expect(hunks.single.endLine, 6);
  });
}
