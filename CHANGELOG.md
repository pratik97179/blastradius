# Changelog

All notable changes to BlastRadius are documented in this file.

## [0.1.0]

### Added

- Full JSON blast-radius reports via `--format json` (structured affected groups,
  risk, confidence, suggested tests).
- Full Markdown blast-radius reports via `--format md` (checklist-style sections
  for PR comments and reviews).
- Shared `ReportRenderer` used by both `trace` and `diff`.
- Route destination extraction from `GoRoute`, `MaterialPageRoute`, and
  `CupertinoPageRoute` (`builder` / `pageBuilder` / `child`).

### Changed

- Package version set to `0.1.0` for the first MVP-complete report surface.
- Node classification uses pre-defined structural signals instead of class-name
  suffixes: framework base types (Bloc/Cubit/ChangeNotifier/Widget), router
  destinations, and folder segments (`pages`/`screens`, `repositories`,
  `services`, `providers`).

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
