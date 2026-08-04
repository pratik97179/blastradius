import 'package:blastradius/src/analyzer/classifiers.dart';
import 'package:blastradius/src/model/ast_model.dart';
import 'package:blastradius/src/model/node_kind.dart';
import 'package:test/test.dart';

void main() {
  final classifier = ClassClassifier();

  DeclaredClass clazz({
    required String name,
    String? superclassName,
    List<String> mixinNames = const [],
    List<String> interfaceNames = const [],
  }) {
    return DeclaredClass(
      name: name,
      filePath: 'lib/$name.dart',
      methods: const [],
      superclassName: superclassName,
      mixinNames: mixinNames,
      interfaceNames: interfaceNames,
    );
  }

  test('classifies repository and service by naming', () {
    expect(
      classifier.classify(clazz(name: 'PortfolioRepository')),
      NodeKind.repository,
    );
    expect(
      classifier.classify(clazz(name: 'PortfolioService')),
      NodeKind.service,
    );
  });

  test('classifies bloc and cubit by hierarchy or suffix', () {
    expect(
      classifier.classify(
        clazz(
          name: 'PortfolioBloc',
          superclassName: 'Bloc<PortfolioEvent, PortfolioState>',
        ),
      ),
      NodeKind.bloc,
    );
    expect(
      classifier.classify(clazz(name: 'SettingsCubit')),
      NodeKind.cubit,
    );
  });

  test('prefers screen over generic widget for Screen/Page names', () {
    expect(
      classifier.classify(
        clazz(
          name: 'PortfolioScreen',
          superclassName: 'StatelessWidget',
        ),
      ),
      NodeKind.screen,
    );
    expect(
      classifier.classify(
        clazz(
          name: 'HoldingTile',
          superclassName: 'StatelessWidget',
        ),
      ),
      NodeKind.widget,
    );
  });

  test('classifies ChangeNotifier mixins and Provider suffixes', () {
    expect(
      classifier.classify(
        clazz(
          name: 'SessionModel',
          mixinNames: ['ChangeNotifier'],
        ),
      ),
      NodeKind.changeNotifier,
    );
    expect(
      classifier.classify(clazz(name: 'AuthProvider')),
      NodeKind.provider,
    );
  });

  test('counts classified kinds', () {
    final classified = classifier.classifyAll([
      clazz(name: 'PortfolioService'),
      clazz(name: 'PortfolioRepository'),
      clazz(
        name: 'PortfolioBloc',
        superclassName: 'Bloc<Object, Object>',
      ),
      clazz(
        name: 'PortfolioScreen',
        superclassName: 'StatelessWidget',
      ),
    ]);

    final counts = classifier.countByKind(classified);
    expect(counts[NodeKind.service], 1);
    expect(counts[NodeKind.repository], 1);
    expect(counts[NodeKind.bloc], 1);
    expect(counts[NodeKind.screen], 1);
  });
}
