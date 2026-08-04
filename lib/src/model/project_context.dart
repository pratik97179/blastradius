class ProjectContext {
  const ProjectContext({
    required this.rootPath,
    required this.packageName,
    required this.dartFiles,
    required this.pubspecPath,
  });

  final String rootPath;
  final String packageName;
  final String pubspecPath;
  final List<String> dartFiles;

  int get dartFileCount => dartFiles.length;
}
