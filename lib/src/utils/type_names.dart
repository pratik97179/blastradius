/// Returns the simple identifier for a type source like `pkg.Foo<Bar>`.
String simpleTypeName(String typeSource) {
  final withoutArgs = typeSource.split('<').first.trim();
  return withoutArgs.split('.').last.trim();
}
