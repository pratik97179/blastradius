# BlastRadius

**Know your blast radius before you commit.**

A CLI static analysis tool for Dart and Flutter packages. Point it at a change and see which callers, repositories, services, state managers, and screens sit in the blast radius, before review, QA, or merge.

Dart is the base. Flutter signals (widgets, routes, Blocs) are enrichment on the same pipeline.

```text
────────────────────────────────────────────

BlastRadius

Changed

✓ PortfolioService.getPortfolio

Affected Repositories

✓ PortfolioRepository

Affected State Managers

✓ PortfolioBloc

Affected Screens

✓ PortfolioScreen
✓ StockDetailsScreen

Suggested Tests

✓ portfolio_bloc_test
✓ portfolio_screen_test

Risk

MEDIUM

Confidence

100%

────────────────────────────────────────────
```

---

## Why

IDE "Find References" answers *who calls this*.

BlastRadius answers *what else in the package might break*.

Large codebases hide impact behind services, repositories, state managers, and routers. Tracing that by hand is slow and easy to get wrong. BlastRadius builds a dependency graph and reports the likely fallout of a change.

## Status

**MVP 0.2.0.** Heuristics are best-effort, not guarantees. Confidence scores are advisory.

| Capability | State |
|------------|--------|
| CLI command parser | Ready |
| Project discovery (Dart + Flutter) | Ready |
| AST extraction + classifiers | Ready |
| Dependency graph | Ready |
| `trace method\|file\|class` | Ready |
| `diff` (git working tree) | Ready |
| Console / JSON / Markdown reports | Ready |

## Install

```bash
git clone <repo-url> blastradius
cd blastradius
dart pub get
dart pub global activate --source path .
```

Run without global activate:

```bash
dart run bin/blastradius.dart
```

## Usage

```bash
blastradius --help
blastradius --version

# Discover / index / classify / graph summary
blastradius -p path/to/package analyze
blastradius -p path/to/package analyze -v

# Trace blast radius
blastradius -p path/to/package trace method getPortfolio
blastradius -p path/to/package trace file lib/services/portfolio_service.dart
blastradius -p path/to/package trace class PortfolioRepository

# Diff blast radius for local git changes
blastradius -p path/to/package diff
blastradius -p path/to/package diff --base main

# Formats
blastradius -p path/to/package trace method getPortfolio --format console
blastradius -p path/to/package trace method getPortfolio --format json
blastradius -p path/to/package diff --format md
```

Global flags: `--project` (`-p`), `--verbose` (`-v`), `--version` (`-V`).

| Exit code | Meaning |
|-----------|---------|
| `0` | Success |
| `1` | Usage / symbol resolution error |
| `2` | Project / git discovery failed |

See [CHANGELOG.md](CHANGELOG.md).

## Supported patterns (MVP)

Classification uses structure and framework signals, not class-name suffixes:

| Kind | Signal |
|------|--------|
| screen | Widget constructed in `GoRoute` / `MaterialPageRoute` / `CupertinoPageRoute`, or under a `pages` / `screens` folder |
| bloc / cubit / changeNotifier | Extends / mixes in `Bloc`, `Cubit`, or `ChangeNotifier` |
| repository / service / provider | File under a `repositories`, `services`, or `providers` folder |
| widget | Extends `StatelessWidget` / `StatefulWidget` / `Widget` (and is not a screen) |

On plain Dart packages, folder and call-graph signals still apply; Flutter-only kinds stay empty.

**Not in MVP:** Riverpod, GetX, MobX, Redux, AutoRoute, runtime execution, autofix.

## How it works

```text
CLI → project index → Dart analyzer → dependency graph → blast walk → report
```

Static analysis only. No app execution. Flutter is detected from `pubspec.yaml` and only enriches classification.

## Test fixtures

`test/fixtures/dart_call_chain` is a plain Dart package (service → repository → loader).

`test/fixtures/sample_flutter_app` models a Flutter blast chain:

```text
PortfolioService.getPortfolio()
  → PortfolioRepository
    → PortfolioBloc
      → PortfolioScreen / DashboardScreen / StockDetailsScreen
        → GoRouter (+ legacy MaterialPageRoute)
```

```bash
dart run bin/blastradius.dart -p test/fixtures/dart_call_chain analyze
dart run bin/blastradius.dart -p test/fixtures/dart_call_chain trace method getPortfolio
dart run bin/blastradius.dart -p test/fixtures/sample_flutter_app trace method getPortfolio
dart run bin/blastradius.dart -p test/fixtures/sample_flutter_app trace method getPortfolio --format json
```

## Contributing

Small progressive commits. Keep the changelog short. Match existing style. Do not use em dashes.

## License

MIT. See [LICENSE](LICENSE).
