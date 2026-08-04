# BlastRadius

**Know your blast radius before you commit.**

A CLI static analysis tool for Flutter apps. Point it at a change and see which screens, routes, state managers, and repositories sit in the blast radius — before review, QA, or merge.

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

IDE “Find References” answers *who calls this*.

BlastRadius answers *what user-facing surface might break*.

Large Flutter codebases hide impact behind services, repositories, Blocs, and routers. Tracing that by hand is slow and easy to get wrong. BlastRadius builds a dependency graph and reports the likely fallout of a change.

## Status

**Early MVP — fail fast.** APIs and output will move. Heuristics are best-effort, not guarantees.

| Capability | State |
|------------|--------|
| CLI scaffold | Ready |
| Command parser (`trace` / `diff` / `analyze`) | Ready (stubs) |
| Project discovery | Next |
| `trace` / `diff` analysis | Planned |
| Console / JSON / Markdown reports | Planned |

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
blastradius -p path/to/flutter_app trace method getPortfolio
blastradius trace file lib/services/portfolio_service.dart
blastradius trace class PortfolioRepository --file lib/repositories/portfolio_repository.dart
blastradius diff --base HEAD
blastradius analyze --verbose
```

Global flags: `--project` (`-p`), `--verbose` (`-v`), `--version` (`-V`).

Analysis backends are not wired yet; commands parse args and exit with code `3` (`not implemented`). See [CHANGELOG.md](CHANGELOG.md).

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

## Contributing

Small progressive commits. Keep the changelog short. Match existing style.

## License

MIT — see [LICENSE](LICENSE).
