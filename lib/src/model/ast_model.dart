class DeclaredClass {
  const DeclaredClass({
    required this.name,
    required this.filePath,
    required this.methods,
    this.superclassName,
    this.mixinNames = const [],
    this.interfaceNames = const [],
    this.startLine = 0,
    this.endLine = 0,
  });

  final String name;
  final String filePath;
  final String? superclassName;
  final List<String> mixinNames;
  final List<String> interfaceNames;
  final List<String> methods;
  final int startLine;
  final int endLine;

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
    this.endLine = 0,
  });

  final String name;
  final String filePath;
  final String? className;
  final int offset;
  final int line;
  final int endLine;

  String get qualifiedName =>
      className == null ? name : '$className.$name';

  int get startLine => line;
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

class TypeUsage {
  const TypeUsage({
    required this.fromFile,
    required this.targetTypeName,
    this.fromClass,
    this.fromMethod,
  });

  final String fromFile;
  final String? fromClass;
  final String? fromMethod;
  final String targetTypeName;
}

class AstModel {
  const AstModel({
    required this.classes,
    required this.methods,
    required this.calls,
    this.routeDestinationNames = const {},
    this.typeUsages = const [],
  });

  final List<DeclaredClass> classes;
  final List<DeclaredMethod> methods;
  final List<ResolvedCall> calls;

  /// Widget class names constructed inside GoRoute / *PageRoute destinations.
  final Set<String> routeDestinationNames;

  /// Type arguments from BlocBuilder / Provider / context.read-style usages.
  final List<TypeUsage> typeUsages;

  int get resolvedCallCount => calls.where((c) => c.isResolved).length;
}
