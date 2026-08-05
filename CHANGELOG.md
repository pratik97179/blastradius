# Changelog

All notable changes to BlastRadius are documented in this file.

## [0.2.1]

### Added

- Second Flutter fixture `shop_flutter_app`: catalog domain with
  `ChangeNotifier`, Provider consumers, and `pages/` route destinations.
- Blast regression for `CatalogService.fetchItems` reaching catalog/cart
  pages and suggesting `catalog_controller_test`.

### Changed

- Package version set to `0.2.1`.

## [0.2.0]

### Added

- Dart package discovery: any `pubspec.yaml` root is accepted; Flutter is
  optional enrichment via `ProjectContext.isFlutter`.
- `analyze` prints `Platform  dart|flutter`.
- CLI coverage for `dart_call_chain` as a first-class Dart target.

### Changed

- Product positioning is Dart-first with Flutter KindSignals on the same
  pipeline (no Flutter-only discovery gate).
- Console and Markdown reports omit empty affected sections so Dart traces
  are not padded with unused Flutter labels.
- Risk scoring also considers total affected surface count (repos, services,
  state managers, screens, widgets), not screens alone.
- Empty-walk copy refers to graph dependents, not only user-facing surfaces.
- Package version set to `0.2.0`.

## [0.1.3]

### Added

- Top-level function call scope so router factories like `createAppRouter`
  record call edges to constructed screens.
- DI type-usage edges from field declarations and simple constructor
  parameters (for example `PortfolioBloc` -> `PortfolioRepository`).

### Changed

- Type-usage graph wiring supports method-only origins (top-level functions)
  without a containing class.
- Package version set to `0.1.3`.

## [0.1.2]

### Added

- Type-usage extraction for state consumers (`BlocBuilder`, `BlocProvider`,
  `Provider`, `context.read` / `watch` / `select`, and related widgets).
- Graph `uses` edges from consumer widgets/methods to referenced bloc /
  repository / notifier types.
- Fixture blast regression covering `DashboardScreen` via `BlocBuilder`.

### Changed

- Package version set to `0.1.2`.

## [0.1.1]

### Added

- Route destination extraction from `GoRoute`, `MaterialPageRoute`, and
  `CupertinoPageRoute` (`builder` / `pageBuilder` / `child`).
- Shared `KindSignals` for framework bases, route constructors, and folder
  segments used during classification.

### Changed

- Node classification no longer uses class-name suffixes (`*Screen`, `*Bloc`,
  `*Repository`, etc.).
- Screens are inferred from router destinations and `pages` / `screens`
  folders.
- Bloc / Cubit / ChangeNotifier require matching framework base types.
- Repository / service / provider kinds come from `repositories`, `services`,
  and `providers` folder segments.
- Package version set to `0.1.1`.

## [0.1.0]

### Added

- Full JSON blast-radius reports via `--format json` (structured affected groups,
  risk, confidence, suggested tests).
- Full Markdown blast-radius reports via `--format md` (checklist-style sections
  for PR comments and reviews).
- Shared `ReportRenderer` used by both `trace` and `diff`.

### Changed

- Package version set to `0.1.0` for the first MVP-complete report surface.

## [0.0.8]

### Added

- Git diff integration: `diff` reads working-tree changes vs a base ref (default
  `HEAD`), maps hunks to methods/classes, and unions their blast radius.
- Diff hunk parser that scopes changes to the analyzed project even when the
  git root is a parent directory.
- Console report `Changed Files` section for diff-driven runs.

### Changed

- AST declarations now capture start/end line ranges for hunk-to-symbol mapping.

## [0.0.7]

### Added

- Blast radius engine with reverse-graph traversal, confidence scoring, and
  risk heuristics.
- Live `trace method`, `trace class`, and `trace file` commands with console
  reports (lightweight `json` / `md` output stubs included).
- Symbol resolver with ambiguity errors when a method/class name matches more
  than once without `--file`.
- Best-effort suggested tests from `*_test.dart` names that match affected
  symbols.

## [0.0.6]

### Added

- Dependency graph builder with class/method nodes, call/uses/extends edges, and
  a reverse index for dependent lookups.
- `analyze` reports graph node and edge counts after classification.
- Graph builder regression test on the `dart_call_chain` fixture
  (`getPortfolio` <- `fetchHoldings` <- `load`).

## [0.0.5]

### Added

- Class classifiers for common Flutter layers: service, repository, bloc, cubit,
  changeNotifier, provider, widget, and screen.
- Hierarchy-aware labeling using `extends` / `with` / `implements` type names,
  with Screen/Page naming preferred over generic widgets.
- `analyze` prints a non-zero kind breakdown after AST extraction (`-v` lists
  each classified class).

## [0.0.4]

### Added

- AST extraction through `AstExtractor` using `package:analyzer`
  `AnalysisContextCollection` for classes, methods, and call sites.
- Resolved call capture for method invocations and constructor creates when the
  target project has a valid package config.
- `analyze` reports class, method, and call counts after discovery (`-v` lists
  resolved call edges).
- Plain Dart `dart_call_chain` fixture for reliable resolved-call tests without
  a Flutter SDK.

## [0.0.3]

### Added

- Expanded `sample_flutter_app` into the MVP portfolio dependency chain: service,
  repository, Bloc, screens, GoRouter routes, and a legacy `MaterialPageRoute`.
- Fixture layout regression test that locks the on-disk chain and route wiring.
- Suggested-test placeholder files `portfolio_bloc_test.dart` and
  `portfolio_screen_test.dart`.

### Changed

- Excluded `test/fixtures/**` from the tool package analyzer so Flutter fixture
  sources do not fail host-package analysis.
- Limited `dart test` paths so fixture-app placeholder tests are not executed by
  the host package test runner.

## [0.0.2]

### Added

- Flutter project discovery through `ProjectAnalyzer`: resolves the package root,
  validates `pubspec.yaml`, detects Flutter projects, and indexes Dart sources
  under `lib/` and `test/`.
- Generated-source excludes for `.dart_tool`, `build`, `*.g.dart`,
  `*.freezed.dart`, `*.mocks.dart`, and `*.config.dart`.
- `analyze` prints a discovery summary (root, package name, pubspec path, and
  indexed file count; `-v` lists each file).
- Test fixtures under `test/fixtures/` for a minimal Flutter-shaped app and a
  plain Dart package used to assert rejection.
- Exit code `2` when project discovery fails.

### Changed

- `trace` and `diff` validate the target Flutter project before reporting that
  analysis is not implemented yet.

## [0.0.1]

### Added

- Initialized the BlastRadius Dart CLI package.
- Added MIT license, README, and a tight stack-specific `.gitignore`.
- Added a CLI command runner with `trace`, `diff`, and `analyze` stubs.
- Added `trace` subcommands for `method`, `file`, and `class`.
- Added global flags `--project` / `-p`, `--verbose` / `-v`, and `--version` / `-V`.
