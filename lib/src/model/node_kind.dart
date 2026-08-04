enum NodeKind {
  service,
  repository,
  bloc,
  cubit,
  changeNotifier,
  provider,
  widget,
  screen,
  other,
}

extension NodeKindLabel on NodeKind {
  String get label => switch (this) {
        NodeKind.service => 'service',
        NodeKind.repository => 'repository',
        NodeKind.bloc => 'bloc',
        NodeKind.cubit => 'cubit',
        NodeKind.changeNotifier => 'changeNotifier',
        NodeKind.provider => 'provider',
        NodeKind.widget => 'widget',
        NodeKind.screen => 'screen',
        NodeKind.other => 'other',
      };
}
