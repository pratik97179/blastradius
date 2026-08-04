import 'dart:io';

import 'package:blastradius/blastradius.dart';

void main(List<String> args) {
  final code = runBlastRadius(args);
  exit(code);
}
