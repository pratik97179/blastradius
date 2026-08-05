# BlastRadius

**Know your blast radius before you commit.**

A CLI static analysis tool for Flutter apps. Point it at a change and see which screens, routes, state managers, and repositories sit in the blast radius, before review, QA, or merge.

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

BlastRadius answers *what user-facing surface might break*.

Large Flutter codebases hide impact behind services, repositories, Blocs, and routers. Tracing that by hand is slow and easy to get wrong. BlastRadius builds a dependency graph and reports the likely fallout of a change.

## Status

**MVP 0.1.0.** Heuristics are best-effort, not guarantees. Confidence scores are advisory.

| Capability | State |
|------------|--------|
| CLI command parser | Ready |
| Project discovery | Ready |
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
blastradius -p path/to/flutter_app analyze
blastradius -p path/to/flutter_app analyze -v

# Trace blast radius
blastradius -p path/to/flutter_app trace method getPortfolio
blastradius -p path/to/flutter_app trace file lib/services/portfolio_service.dart
blastradius -p path/to/flutter_app trace class PortfolioRepository

# Diff blast radius for local git changes
blastradius -p path/to/flutter_app diff
blastradius -p path/to/flutter_app diff --base main

# Formats
blastradius -p path/to/flutter_app trace method getPortfolio --format console
blastradius -p path/to/flutter_app trace method getPortfolio --format json
blastradius -p path/to/flutter_app diff --format md
```

Global flags: `--project` (`-p`), `--verbose` (`-v`), `--version` (`-V`).

| Exit code | Meaning |
|-----------|---------|
| `0` | Success |
| `1` | Usage / symbol resolution error |
| `2` | Project / git discovery failed |

See [CHANGELOG.md](CHANGELOG.md).

## Supported patterns (MVP)

Classification uses pre-defined structure, not class-name suffixes:

| Kind | Signal |
|------|--------|
| screen | Widget constructed in `GoRoute` / `MaterialPageRoute` / `CupertinoPageRoute`, or under a `pages` / `screens` folder |
| bloc / cubit / changeNotifier | Extends / mixes in `Bloc`, `Cubit`, or `ChangeNotifier` |
| repository / service / provider | File under a `repositories`, `services`, or `providers` folder |
| widget | Extends `StatelessWidget` / `StatefulWidget` / `Widget` (and is not a screen) |

**Not in MVP:** Riverpod, GetX, MobX, Redux, AutoRoute, runtime execution, autofix.

## How it works

```text
CLI → project index → Dart analyzer → dependency graph → blast walk → report
```

Static analysis only. No app execution.

## Test fixture

`test/fixtures/sample_flutter_app` models the MVP blast chain:

```text
PortfolioService.getPortfolio()
  → PortfolioRepository
    → PortfolioBloc
      → PortfolioScreen / DashboardScreen / StockDetailsScreen
        → GoRouter (+ legacy MaterialPageRoute)
```

```bash
dart run bin/blastradius.dart -p test/fixtures/sample_flutter_app trace method getPortfolio
dart run bin/blastradius.dart -p test/fixtures/sample_flutter_app trace method getPortfolio --format json
```

## Contributing

Small progressive commits. Keep the changelog short. Match existing style. Do not use em dashes.

## License

MIT. See [LICENSE](LICENSE).
