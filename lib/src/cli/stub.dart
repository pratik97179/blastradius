import 'dart:io';

/// Temporary CLI entry until the real command parser lands.
///
/// Returns a process exit code.
int runBlastRadius(List<String> args) {
  final out = stdout;
  out.writeln('BlastRadius $packageVersion');
  out.writeln('Know your blast radius before you commit.');
  out.writeln();

  if (args.isEmpty) {
    out.writeln('Usage: blastradius <command>');
    out.writeln('Commands (coming soon): trace, diff, analyze');
    return 0;
  }

  out.writeln('Received args: ${args.join(' ')}');
  out.writeln('CLI commands are not wired yet. See README.md.');
  return 0;
}

/// Package version mirrored from pubspec for stub output.
const String packageVersion = '0.0.1';
