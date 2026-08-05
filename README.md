# BlastRadius

[![CI](https://github.com/blastradius/blastradius/actions/workflows/ci.yml/badge.svg)](https://github.com/blastradius/blastradius/actions/workflows/ci.yml)

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

**MVP 0.3.0.** Heuristics are best-effort, not guarantees. Confidence scores are advisory.

| Capability | State |
|------------|--------|
| CLI command parser | Ready |
| Project discovery (Dart + Flutter) | Ready |
| AST extraction + classifiers | Ready |
| Dependency graph | Ready |
| `trace method\|file\|class` | Ready |
| `diff` (git working tree) | Ready |
| Console / JSON / Markdown reports | Ready |
| Visual dashboard (`view`) | Ready |
| GitHub Actions CI | Ready |

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

# Visual dashboard (local browser)
blastradius -p path/to/package view method fetchProfile
blastradius -p path/to/package view graph
blastradius -p path/to/package view diff
blastradius -p path/to/package view method fetchProfile --export ./blast-view
blastradius -p path/to/package view method fetchProfile --port 7423 --no-open
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

## Visual dashboard

`view` builds a graph payload and serves the React dashboard from `web/dashboard/dist` (no Node required at runtime).

```bash
dart run bin/blastradius.dart -p test/fixtures/dart_call_chain view method fetchProfile
dart run bin/blastradius.dart -p test/fixtures/shop_flutter_app view method fetchItems --export ./blast-view
```

Open the printed URL, or open `blast-view/index.html` after `--export`.

## How it works

```text
CLI → project index → Dart analyzer → dependency graph → blast walk → report / view
```

Static analysis only. No app execution. Flutter is detected from `pubspec.yaml` and only enriches classification.

## Test fixtures

`test/fixtures/dart_call_chain` is a plain Dart user-profile package:

```text
UserService.fetchProfile()
  → UserRepository
    → ProfileLoader
```

`test/fixtures/sample_flutter_app` is a Bloc + screens portfolio chain:

```text
PortfolioService.getPortfolio()
  → PortfolioRepository
    → PortfolioBloc
      → PortfolioScreen / DashboardScreen / StockDetailsScreen
        → GoRouter (+ legacy MaterialPageRoute)
```

`test/fixtures/shop_flutter_app` is a ChangeNotifier + pages catalog chain:

```text
CatalogService.fetchItems()
  → CatalogRepository
    → CatalogController
      → CatalogPage / CartPage
        → GoRouter (+ legacy MaterialPageRoute)
```

```bash
dart run bin/blastradius.dart -p test/fixtures/dart_call_chain analyze
dart run bin/blastradius.dart -p test/fixtures/dart_call_chain trace method fetchProfile
dart run bin/blastradius.dart -p test/fixtures/dart_call_chain view method fetchProfile
dart run bin/blastradius.dart -p test/fixtures/sample_flutter_app trace method getPortfolio
dart run bin/blastradius.dart -p test/fixtures/shop_flutter_app trace method fetchItems
dart run bin/blastradius.dart -p test/fixtures/sample_flutter_app trace method getPortfolio --format json
```

## Contributing

Small progressive commits. Keep the changelog short. Match existing style. Do not use em dashes.

Dashboard UI lives in `web/dashboard` (Vite + React + TypeScript). After UI changes:

```bash
cd web/dashboard
npm install
npm run build
```

Commit the updated `web/dashboard/dist` output so the CLI can serve it without Node.

## License

MIT. See [LICENSE](LICENSE).
