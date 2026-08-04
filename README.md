# BlastRadius

**Know your blast radius before you commit.**

A CLI static analysis tool for Flutter apps. Point it at a change and see which screens, routes, state managers, and repositories sit in the blast radius, before review, QA, or merge.

```text
────────────────────────────────────────────
BlastRadius

Changed
  PortfolioService.getPortfolio()

Affected Screens
  ✓ PortfolioScreen
  ✓ DashboardScreen
  ✓ StockDetailsScreen

Affected State Managers
  ✓ PortfolioBloc

Risk        HIGH
Confidence  91%
────────────────────────────────────────────
```

> Sample output. The full report pipeline is under active MVP development.

---

## Why

IDE "Find References" answers *who calls this*.

BlastRadius answers *what user-facing surface might break*.

Large Flutter codebases hide impact behind services, repositories, Blocs, and routers. Tracing that by hand is slow and easy to get wrong. BlastRadius builds a dependency graph and reports the likely fallout of a change.

## Status

**Early MVP, fail fast.** APIs and output will move. Heuristics are best-effort, not guarantees.

| Capability | State |
|------------|--------|
| CLI command parser | Ready |
| Project discovery | Ready |
| Portfolio fixture chain | Ready |
| AST extraction | Ready |
| Class classifiers | Ready |
| Dependency graph | Ready |
| Blast radius engine / `trace` | Ready |
| `diff` analysis | Ready |
| Console report | Ready |
| JSON / Markdown reports | Partial |

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

# Discover and index a Flutter project
blastradius -p path/to/flutter_app analyze
blastradius -p path/to/flutter_app analyze -v

# Trace blast radius (live)
blastradius -p path/to/flutter_app trace method getPortfolio
blastradius -p path/to/flutter_app trace file lib/services/portfolio_service.dart
blastradius -p path/to/flutter_app trace class PortfolioRepository

# Diff blast radius for local git changes
blastradius -p path/to/flutter_app diff
blastradius -p path/to/flutter_app diff --base main
```

Global flags: `--project` (`-p`), `--verbose` (`-v`), `--version` (`-V`).

| Exit code | Meaning |
|-----------|---------|
| `0` | Success |
| `1` | Usage / symbol resolution error |
| `2` | Project / git discovery failed |

See [CHANGELOG.md](CHANGELOG.md).

## Supported patterns (MVP target)

- Repository / service layers
- Bloc & Cubit
- Provider / ChangeNotifier
- GoRouter, Navigator, MaterialPageRoute

**Not in MVP:** Riverpod, GetX, MobX, Redux, AutoRoute, runtime execution, autofix.

## How it works

```text
CLI → project index → Dart analyzer → dependency graph → blast walk → report
```

Static analysis only. No app execution. Confidence scores are advisory.

## Test fixture

`test/fixtures/sample_flutter_app` models the MVP blast chain:

```text
PortfolioService.getPortfolio()
  → PortfolioRepository
    → PortfolioBloc
      → PortfolioScreen / DashboardScreen / StockDetailsScreen
        → GoRouter (+ legacy MaterialPageRoute)
```

Use it as the `--project` target while building graph and trace behavior.

## Contributing

Small progressive commits. Keep the changelog short. Match existing style. Do not use em dashes.

## License

MIT. See [LICENSE](LICENSE).
