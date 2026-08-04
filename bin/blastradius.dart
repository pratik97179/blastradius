import 'dart:io';

import 'package:blastradius/blastradius.dart';

Future<void> main(List<String> args) async {
  final code = await runBlastRadius(args);
  exit(code);
}
