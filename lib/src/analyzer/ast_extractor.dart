import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../model/ast_model.dart';
import '../model/project_context.dart';
import 'kind_signals.dart';

class AstExtractionException implements Exception {
  AstExtractionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AstExtractor {
  Future<AstModel> extract(ProjectContext context) async {
    if (context.dartFiles.isEmpty) {
      return const AstModel(
        classes: [],
        methods: [],
        calls: [],
        routeDestinationNames: {},
        typeUsages: [],
      );
    }

    final collection = AnalysisContextCollection(
      includedPaths: [context.rootPath],
    );

    final classes = <DeclaredClass>[];
    final methods = <DeclaredMethod>[];
    final calls = <ResolvedCall>[];
    final routeDestinationNames = <String>{};
    final typeUsages = <TypeUsage>[];

    try {
      for (final filePath in context.dartFiles) {
        final analysisContext = collection.contextFor(filePath);
        final result = await analysisContext.currentSession.getResolvedUnit(
          filePath,
        );
        if (result is! ResolvedUnitResult) {
          continue;
        }

        final visitor = _ExtractionVisitor(filePath: filePath);
        result.unit.accept(visitor);
        classes.addAll(visitor.classes);
        methods.addAll(visitor.methods);
        calls.addAll(visitor.calls);
        routeDestinationNames.addAll(visitor.routeDestinationNames);
        typeUsages.addAll(visitor.typeUsages);
      }
    } finally {
      await collection.dispose();
    }

    classes.sort((a, b) => a.name.compareTo(b.name));
    methods.sort((a, b) => a.qualifiedName.compareTo(b.qualifiedName));
    return AstModel(
      classes: classes,
      methods: methods,
      calls: calls,
      routeDestinationNames: routeDestinationNames,
      typeUsages: typeUsages,
    );
  }
}

class _ExtractionVisitor extends RecursiveAstVisitor<void> {
  _ExtractionVisitor({required this.filePath});

  final String filePath;
  final List<DeclaredClass> classes = [];
  final List<DeclaredMethod> methods = [];
  final List<ResolvedCall> calls = [];
  final Set<String> routeDestinationNames = {};
  final List<TypeUsage> typeUsages = [];

  String? _currentClass;
  String? _currentMethod;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final previousClass = _currentClass;
    final className = node.namePart.typeName.lexeme;
    _currentClass = className;

    final methodNames = node.body.members
        .whereType<MethodDeclaration>()
        .map((MethodDeclaration method) => method.name.lexeme)
        .toList(growable: false);

    classes.add(
      DeclaredClass(
        name: className,
        filePath: filePath,
        superclassName: node.extendsClause?.superclass.toSource(),
        mixinNames: node.withClause?.mixinTypes
                .map((type) => type.toSource())
                .toList(growable: false) ??
            const [],
        interfaceNames: node.implementsClause?.interfaces
                .map((type) => type.toSource())
                .toList(growable: false) ??
            const [],
        methods: methodNames,
        startLine: _lineFor(node),
        endLine: _endLineFor(node),
      ),
    );

    super.visitClassDeclaration(node);
    _currentClass = previousClass;
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final previousMethod = _currentMethod;
    final methodName = node.name.lexeme;
    _currentMethod = methodName;

    methods.add(
      DeclaredMethod(
        name: methodName,
        className: _currentClass,
        filePath: filePath,
        offset: node.name.offset,
        line: _lineFor(node),
        endLine: _endLineFor(node),
      ),
    );

    super.visitMethodDeclaration(node);
    _currentMethod = previousMethod;
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (_currentClass != null) {
      super.visitFunctionDeclaration(node);
      return;
    }

    final previousMethod = _currentMethod;
    final functionName = node.name.lexeme;
    _currentMethod = functionName;

    methods.add(
      DeclaredMethod(
        name: functionName,
        filePath: filePath,
        offset: node.name.offset,
        line: _lineFor(node),
        endLine: _endLineFor(node),
      ),
    );
    super.visitFunctionDeclaration(node);
    _currentMethod = previousMethod;
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _recordTypeAnnotation(node.fields.type);
    super.visitFieldDeclaration(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _recordTypeAnnotation(node.type);
    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _recordCall(
      targetName: node.methodName.name,
      element: node.methodName.element,
    );
    if (KindSignals.stateLookupMethods.contains(node.methodName.name)) {
      _recordTypeArguments(node.typeArguments);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitNamedType(NamedType node) {
    if (_isTypeArgOfStateConsumer(node)) {
      _recordTypeUsage(node.name.lexeme);
    }
    super.visitNamedType(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName;
    final typeName = constructorName.type.name.lexeme;
    final named = constructorName.name?.name;
    final targetName =
        named == null || named.isEmpty ? typeName : '$typeName.$named';
    _recordCall(
      targetName: targetName,
      element: constructorName.element,
      targetClass: typeName,
    );

    if (KindSignals.routeConstructors.contains(typeName)) {
      _collectRouteDestinations(node.argumentList);
    }

    super.visitInstanceCreationExpression(node);
  }

  void _collectRouteDestinations(ArgumentList argumentList) {
    final collector = _RouteDestinationCollector(routeDestinationNames);
    for (final arg in argumentList.arguments) {
      if (arg is! NamedExpression) {
        continue;
      }
      if (!KindSignals.routeDestinationArgs.contains(arg.name.label.name)) {
        continue;
      }
      arg.expression.accept(collector);
    }
  }

  bool _isTypeArgOfStateConsumer(NamedType node) {
    final parent = node.parent;
    if (parent is! TypeArgumentList) {
      return false;
    }
    final owner = parent.parent;
    if (owner is NamedType) {
      return KindSignals.stateConsumerTypes.contains(owner.name.lexeme);
    }
    return false;
  }

  void _recordTypeAnnotation(TypeAnnotation? type) {
    if (type is NamedType) {
      _recordTypeUsage(type.name.lexeme);
    }
  }

  void _recordTypeArguments(TypeArgumentList? typeArguments) {
    if (typeArguments == null) {
      return;
    }
    for (final arg in typeArguments.arguments) {
      if (arg is NamedType) {
        _recordTypeUsage(arg.name.lexeme);
      }
    }
  }

  void _recordTypeUsage(String targetTypeName) {
    if (targetTypeName.isEmpty) {
      return;
    }
    if (_currentClass == null && _currentMethod == null) {
      return;
    }
    if (targetTypeName == _currentClass) {
      return;
    }
    typeUsages.add(
      TypeUsage(
        fromFile: filePath,
        fromClass: _currentClass,
        fromMethod: _currentMethod,
        targetTypeName: targetTypeName,
      ),
    );
  }

  void _recordCall({
    required String targetName,
    Element? element,
    String? targetClass,
  }) {
    var resolved = false;
    String? resolvedClass = targetClass;
    String? resolvedFile;

    if (element != null) {
      resolved = true;
      resolvedFile = _fileFor(element);
      final enclosing = element.enclosingElement;
      if (enclosing is InterfaceElement) {
        resolvedClass ??= enclosing.name;
      }
    }

    calls.add(
      ResolvedCall(
        fromFile: filePath,
        fromClass: _currentClass,
        fromMethod: _currentMethod,
        targetName: targetName,
        targetClass: resolvedClass,
        targetFile: resolvedFile,
        isResolved: resolved,
      ),
    );
  }

  String? _fileFor(Element element) {
    try {
      return element.firstFragment.libraryFragment?.source.fullName;
    } catch (_) {
      return element.library?.firstFragment.source.fullName;
    }
  }

  int _lineFor(AstNode node) {
    final unit = node.root;
    if (unit is CompilationUnit) {
      return unit.lineInfo.getLocation(node.offset).lineNumber;
    }
    return 0;
  }

  int _endLineFor(AstNode node) {
    final unit = node.root;
    if (unit is CompilationUnit) {
      return unit.lineInfo.getLocation(node.end).lineNumber;
    }
    return 0;
  }
}

class _RouteDestinationCollector extends RecursiveAstVisitor<void> {
  _RouteDestinationCollector(this.names);

  final Set<String> names;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    names.add(node.constructorName.type.name.lexeme);
    super.visitInstanceCreationExpression(node);
  }
}
