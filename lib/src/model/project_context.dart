class ProjectContext {
  const ProjectContext({
    required this.rootPath,
    required this.packageName,
    required this.dartFiles,
    required this.pubspecPath,
    this.isFlutter = false,
  });

  final String rootPath;
  final String packageName;
  final String pubspecPath;
  final List<String> dartFiles;

  /// True when pubspec declares a Flutter SDK / flutter: config.
  final bool isFlutter;

  int get dartFileCount => dartFiles.length;
}
