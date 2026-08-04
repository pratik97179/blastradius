# Changelog

All notable changes to BlastRadius are documented in this file.

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
