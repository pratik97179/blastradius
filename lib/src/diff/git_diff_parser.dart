import 'dart:io';

import 'package:path/path.dart' as p;

class DiffHunk {
  const DiffHunk({
    required this.relativePath,
    required this.startLine,
    required this.endLine,
  });

  /// Path relative to the analyzed project root.
  final String relativePath;
  final int startLine;
  final int endLine;
}

class GitDiffException implements Exception {
  GitDiffException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GitDiffParser {
  Future<List<DiffHunk>> collectHunks({
    required String projectRoot,
    String base = 'HEAD',
  }) async {
    final gitRoot = await _gitRoot(projectRoot);

    final result = await Process.run(
      'git',
      ['diff', '--unified=0', base],
      workingDirectory: gitRoot,
    );

    if (result.exitCode != 0) {
      final stderr = result.stderr.toString().trim();
      throw GitDiffException(
        stderr.isEmpty
            ? 'git diff failed for base "$base".'
            : 'git diff failed: $stderr',
      );
    }

    return parseDiffOutput(
      result.stdout.toString(),
      gitRoot: gitRoot,
      projectRoot: projectRoot,
    );
  }

  List<DiffHunk> parseDiffOutput(
    String diffOutput, {
    required String gitRoot,
    required String projectRoot,
  }) {
    final hunks = <DiffHunk>[];
    String? currentRepoRelative;
    final hunkPattern = RegExp(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@');

    for (final rawLine in diffOutput.split('\n')) {
      final line = rawLine.trimRight();
      if (line.startsWith('diff --git ')) {
        currentRepoRelative = null;
        continue;
      }
      if (line.startsWith('+++ b/')) {
        final relative = line.substring('+++ b/'.length).trim();
        if (relative != '/dev/null') {
          currentRepoRelative = p.normalize(relative);
        } else {
          currentRepoRelative = null;
        }
        continue;
      }
      if (currentRepoRelative == null ||
          !currentRepoRelative.endsWith('.dart')) {
        continue;
      }

      final absolute = p.normalize(p.join(gitRoot, currentRepoRelative));
      if (!_isUnderProject(absolute, projectRoot)) {
        continue;
      }

      final match = hunkPattern.firstMatch(line);
      if (match == null) {
        continue;
      }

      final start = int.parse(match.group(1)!);
      final count = int.parse(match.group(2) ?? '1');
      if (count <= 0) {
        continue;
      }

      hunks.add(
        DiffHunk(
          relativePath: p.relative(absolute, from: projectRoot),
          startLine: start,
          endLine: start + count - 1,
        ),
      );
    }

    return hunks;
  }

  Future<String> _gitRoot(String projectRoot) async {
    final result = await Process.run(
      'git',
      ['rev-parse', '--show-toplevel'],
      workingDirectory: projectRoot,
    );
    if (result.exitCode != 0) {
      throw GitDiffException(
        'Not a git repository: $projectRoot. Initialize git or pass a repo root via --project.',
      );
    }
    return p.normalize(result.stdout.toString().trim());
  }

  bool _isUnderProject(String absolutePath, String projectRoot) {
    final root = p.normalize(projectRoot);
    final file = p.normalize(absolutePath);
    return p.equals(file, root) || p.isWithin(root, file);
  }
}
