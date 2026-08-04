import 'dart:io';

class Logger {
  Logger({this.verbose = false});

  bool verbose;

  void info(String message) => stdout.writeln(message);

  void warn(String message) => stderr.writeln('warning: $message');

  void error(String message) => stderr.writeln('error: $message');

  void debug(String message) {
    if (verbose) {
      stderr.writeln('debug: $message');
    }
  }
}
