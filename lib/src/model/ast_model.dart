class DeclaredClass {
  const DeclaredClass({
    required this.name,
    required this.filePath,
    required this.methods,
    this.superclassName,
    this.mixinNames = const [],
    this.interfaceNames = const [],
  });

  final String name;
  final String filePath;
  final String? superclassName;
  final List<String> mixinNames;
  final List<String> interfaceNames;
  final List<String> methods;

  List<String> get hierarchyTypeNames => [
        if (superclassName != null) superclassName!,
        ...mixinNames,
        ...interfaceNames,
      ];
}

class DeclaredMethod {
  const DeclaredMethod({
    required this.name,
    required this.filePath,
    required this.offset,
    required this.line,
    this.className,
  });

  final String name;
  final String filePath;
  final String? className;
  final int offset;
  final int line;

  String get qualifiedName =>
      className == null ? name : '$className.$name';
}

class ResolvedCall {
  const ResolvedCall({
    required this.fromFile,
    required this.targetName,
    required this.isResolved,
    this.fromClass,
    this.fromMethod,
    this.targetClass,
    this.targetFile,
  });

  final String fromFile;
  final String? fromClass;
  final String? fromMethod;
  final String targetName;
  final String? targetClass;
  final String? targetFile;
  final bool isResolved;

  String get targetQualifiedName =>
      targetClass == null ? targetName : '$targetClass.$targetName';
}

class AstModel {
  const AstModel({
    required this.classes,
    required this.methods,
    required this.calls,
  });

  final List<DeclaredClass> classes;
  final List<DeclaredMethod> methods;
  final List<ResolvedCall> calls;

  int get resolvedCallCount => calls.where((c) => c.isResolved).length;
}
