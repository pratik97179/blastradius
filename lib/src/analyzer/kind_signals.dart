import '../model/node_kind.dart';

/// Pre-defined structural signals used for [NodeKind] classification.
///
/// Classification prefers framework types, router destinations, and known
/// project folder segments over class-name suffixes or prefixes.
class KindSignals {
  const KindSignals._();

  /// Framework / package base types (matched on extends / with / implements).
  static const Set<String> cubitBases = {'Cubit'};
  static const Set<String> blocBases = {'Bloc'};
  static const Set<String> changeNotifierBases = {'ChangeNotifier'};
  static const Set<String> notifierBases = {
    'Notifier',
    'AsyncNotifier',
    'StreamNotifier',
    'FamilyNotifier',
    'FamilyAsyncNotifier',
    'FamilyStreamNotifier',
    'StateNotifier',
  };
  static const Set<String> widgetBases = {
    'StatelessWidget',
    'StatefulWidget',
    'Widget',
    'ConsumerWidget',
    'ConsumerStatefulWidget',
    'HookConsumerWidget',
  };

  /// Node kinds treated as state managers in blast summaries.
  static const Set<NodeKind> stateManagerKinds = {
    NodeKind.bloc,
    NodeKind.cubit,
    NodeKind.changeNotifier,
    NodeKind.provider,
  };

  /// Constructors whose builder / pageBuilder / child args define screens.
  static const Set<String> routeConstructors = {
    'GoRoute',
    'MaterialPageRoute',
    'CupertinoPageRoute',
  };

  /// Named arguments on route constructors that hold destination widgets.
  static const Set<String> routeDestinationArgs = {
    'builder',
    'pageBuilder',
    'child',
  };

  /// Path segments that mark layer / UI kinds (exact directory names).
  static const Set<String> screenFolders = {'screens', 'pages'};
  static const Set<String> repositoryFolders = {'repositories', 'repository'};
  static const Set<String> serviceFolders = {'services', 'service'};
  static const Set<String> providerFolders = {'providers', 'provider'};

  /// Widgets whose type arguments reference consumed state / data types.
  static const Set<String> stateConsumerTypes = {
    'BlocBuilder',
    'BlocProvider',
    'BlocListener',
    'BlocConsumer',
    'BlocSelector',
    'RepositoryProvider',
    'Provider',
    'Consumer',
    'ChangeNotifierProvider',
    'ListenableProvider',
    'ValueListenableBuilder',
    'NotifierProvider',
    'AsyncNotifierProvider',
    'StreamNotifierProvider',
    'StateNotifierProvider',
    'FutureProvider',
    'StreamProvider',
    'StateProvider',
  };

  /// Provider container type names used by `ref.watch(provider)` resolution.
  ///
  /// Runtime types often end with `ProviderImpl` / `ProviderBase` and are
  /// matched by suffix in the extractor as well.
  static const Set<String> riverpodProviderTypes = {
    'Provider',
    'FutureProvider',
    'StreamProvider',
    'StateProvider',
    'StateNotifierProvider',
    'NotifierProvider',
    'AsyncNotifierProvider',
    'StreamNotifierProvider',
    'NotifierProviderBase',
    'AsyncNotifierProviderBase',
    'StreamNotifierProviderBase',
  };

  /// Extension-style lookups that carry a consumed type argument or provider.
  static const Set<String> stateLookupMethods = {
    'read',
    'watch',
    'select',
    'listen',
  };
}
