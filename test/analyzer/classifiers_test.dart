import 'package:blastradius/src/analyzer/classifiers.dart';
import 'package:blastradius/src/model/ast_model.dart';
import 'package:blastradius/src/model/node_kind.dart';
import 'package:test/test.dart';

void main() {
  final classifier = ClassClassifier();

  DeclaredClass clazz({
    required String name,
    required String filePath,
    String? superclassName,
    List<String> mixinNames = const [],
    List<String> interfaceNames = const [],
  }) {
    return DeclaredClass(
      name: name,
      filePath: filePath,
      methods: const [],
      superclassName: superclassName,
      mixinNames: mixinNames,
      interfaceNames: interfaceNames,
    );
  }

  test('classifies repository and service from folder segments', () {
    expect(
      classifier.classify(
        clazz(
          name: 'PortfolioRepository',
          filePath: 'lib/repositories/portfolio_repository.dart',
        ),
      ),
      NodeKind.repository,
    );
    expect(
      classifier.classify(
        clazz(
          name: 'PortfolioService',
          filePath: 'lib/services/portfolio_service.dart',
        ),
      ),
      NodeKind.service,
    );
    expect(
      classifier.classify(
        clazz(
          name: 'PortfolioRepository',
          filePath: 'lib/portfolio_repository.dart',
        ),
      ),
      NodeKind.other,
    );
  });

  test('classifies bloc and cubit from hierarchy only', () {
    expect(
      classifier.classify(
        clazz(
          name: 'PortfolioBloc',
          filePath: 'lib/bloc/portfolio_bloc.dart',
          superclassName: 'Bloc<PortfolioEvent, PortfolioState>',
        ),
      ),
      NodeKind.bloc,
    );
    expect(
      classifier.classify(
        clazz(
          name: 'SettingsCubit',
          filePath: 'lib/settings_cubit.dart',
        ),
      ),
      NodeKind.other,
    );
    expect(
      classifier.classify(
        clazz(
          name: 'SettingsCubit',
          filePath: 'lib/cubit/settings_cubit.dart',
          superclassName: 'Cubit<SettingsState>',
        ),
      ),
      NodeKind.cubit,
    );
  });

  test('classifies screens from routes or pages/screens folders', () {
    expect(
      classifier.classify(
        clazz(
          name: 'OtpVerificationStep',
          filePath: 'lib/features/auth/presentation/widgets/otp_step.dart',
          superclassName: 'StatefulWidget',
        ),
        routeDestinationNames: {'OtpVerificationStep'},
      ),
      NodeKind.screen,
    );
    expect(
      classifier.classify(
        clazz(
          name: 'HomeView',
          filePath: 'lib/features/home/presentation/pages/home_view.dart',
          superclassName: 'StatelessWidget',
        ),
      ),
      NodeKind.screen,
    );
    expect(
      classifier.classify(
        clazz(
          name: 'HoldingTile',
          filePath: 'lib/features/home/presentation/widgets/holding_tile.dart',
          superclassName: 'StatelessWidget',
        ),
      ),
      NodeKind.widget,
    );
    expect(
      classifier.classify(
        clazz(
          name: 'PortfolioScreen',
          filePath: 'lib/widgets/portfolio_screen.dart',
          superclassName: 'StatelessWidget',
        ),
      ),
      NodeKind.widget,
    );
  });

  test('classifies ChangeNotifier from hierarchy and providers from folders', () {
    expect(
      classifier.classify(
        clazz(
          name: 'SessionModel',
          filePath: 'lib/session_model.dart',
          mixinNames: ['ChangeNotifier'],
        ),
      ),
      NodeKind.changeNotifier,
    );
    expect(
      classifier.classify(
        clazz(
          name: 'AuthProvider',
          filePath: 'lib/features/auth/presentation/providers/auth_provider.dart',
          superclassName: 'StatelessWidget',
        ),
      ),
      NodeKind.provider,
    );
  });

  test('classifies Riverpod Notifier and ConsumerWidget screens', () {
    expect(
      classifier.classify(
        clazz(
          name: 'CatalogNotifier',
          filePath: 'lib/providers/catalog_notifier.dart',
          superclassName: 'Notifier<List<String>>',
        ),
      ),
      NodeKind.provider,
    );
    expect(
      classifier.classify(
        clazz(
          name: 'CatalogPage',
          filePath: 'lib/pages/catalog_page.dart',
          superclassName: 'ConsumerWidget',
        ),
      ),
      NodeKind.screen,
    );
  });

  test('counts classified kinds', () {
    final classified = classifier.classifyAll(
      [
        clazz(
          name: 'PortfolioService',
          filePath: 'lib/services/portfolio_service.dart',
        ),
        clazz(
          name: 'PortfolioRepository',
          filePath: 'lib/repositories/portfolio_repository.dart',
        ),
        clazz(
          name: 'PortfolioBloc',
          filePath: 'lib/bloc/portfolio_bloc.dart',
          superclassName: 'Bloc<Object, Object>',
        ),
        clazz(
          name: 'PortfolioScreen',
          filePath: 'lib/screens/portfolio_screen.dart',
          superclassName: 'StatelessWidget',
        ),
      ],
      routeDestinationNames: const {'PortfolioScreen'},
    );

    final counts = classifier.countByKind(classified);
    expect(counts[NodeKind.service], 1);
    expect(counts[NodeKind.repository], 1);
    expect(counts[NodeKind.bloc], 1);
    expect(counts[NodeKind.screen], 1);
  });
}
