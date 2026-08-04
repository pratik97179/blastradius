import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../model/ast_model.dart';
import '../model/project_context.dart';

class AstExtractionException implements Exception {
  AstExtractionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AstExtractor {
  Future<AstModel> extract(ProjectContext context) async {
    if (context.dartFiles.isEmpty) {
      return const AstModel(classes: [], methods: [], calls: []);
    }

    final collection = AnalysisContextCollection(
      includedPaths: [context.rootPath],
    );

    final classes = <DeclaredClass>[];
    final methods = <DeclaredMethod>[];
    final calls = <ResolvedCall>[];

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
      }
    } finally {
      await collection.dispose();
    }

    classes.sort((a, b) => a.name.compareTo(b.name));
    methods.sort((a, b) => a.qualifiedName.compareTo(b.qualifiedName));
    return AstModel(classes: classes, methods: methods, calls: calls);
  }
}

class _ExtractionVisitor extends RecursiveAstVisitor<void> {
  _ExtractionVisitor({required this.filePath});

  final String filePath;
  final List<DeclaredClass> classes = [];
  final List<DeclaredMethod> methods = [];
  final List<ResolvedCall> calls = [];

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

    methods.add(
      DeclaredMethod(
        name: node.name.lexeme,
        filePath: filePath,
        offset: node.name.offset,
        line: _lineFor(node),
      ),
    );
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _recordCall(
      targetName: node.methodName.name,
      element: node.methodName.element,
    );
    super.visitMethodInvocation(node);
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
    super.visitInstanceCreationExpression(node);
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
}
