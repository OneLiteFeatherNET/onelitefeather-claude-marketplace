# minestom-knowledge

Gives Claude accurate knowledge of OneLiteFeather's internal Minestom
libraries and tooling — things that are too internal or too new to be
represented (or represented correctly) in general training data.

## What's inside

- **Skill `cyano`** — how to write and structure tests for Minestom
  projects using [Cyano](https://github.com/OneLiteFeatherNET/Cyano), our
  JUnit5 testing extension for Minestom: the `MicrotusExtension`, creating
  instances/players, asserting on packets via `Collector`, cleanup, and a
  test-structuring pattern drawn from `ManisGame`'s test suite.
- **Skill `gradle`** — our `build.gradle.kts`/`settings.gradle.kts`
  conventions: single-module library template (Cyano/Aves/Xerus/Guira
  shape) vs. multi-module application template with `buildSrc` convention
  plugins (ManisGame shape), the inline version catalog, the private Maven
  repo credential split, and the `-Dminestom.inside-test=true` test flag.
- **Skill `boms`** — the `mycelium-bom` → `aonyx-bom` → `manis-bom` tiered
  Bill-of-Materials hierarchy: which BOM a new project should import, and
  how to add a new managed dependency to one.
- **Skill `guira`** — how to use [Guira](https://github.com/OneLiteFeatherNET/Guira)
  for setup flows on Minestom servers: `SetupDataService`, implementing
  your own `SetupData` (or `MapSetupData` for map-centered setups), the
  `Category` system, and the setup lifecycle events you have to fire
  yourself (Guira never fires them for you).
- **Skill `aves`** — how to use [Aves](https://github.com/OneLiteFeatherNET/Aves),
  the general utility library: GUI inventories (builders, pageable menus,
  click handling), JSON persistence via `ModernFileHandler`, translated
  text/items (i18n), maps, resource pack delivery, and misc utilities
  (item helpers, weighted random, vectors).
- **Skill `xerus`** — how to use [Xerus](https://github.com/OneLiteFeatherNET/Xerus),
  the core minigame library: kits, teams (including ELO-based balanced
  team distribution), the `Phase`/`GamePhase`/`TickedPhase`/
  `LinearPhaseSeries` game-flow system, and the shared `Componentable`
  composition pattern.
- **Skill `pica`** — how to use [Pica](https://github.com/OneLiteFeatherNET/pica),
  the Dialog API for Minestom's native dialog UI: confirmation dialogs,
  input-field dialogs (boolean/range/single-option/text), the
  `DialogRegistry`, and `PlayerOpenDialogEvent`.
- **Skill `coris`** — how to use [Coris](https://github.com/OneLiteFeatherNET/Coris)
  (experimental API), the floor/room/door/shape management system:
  `Shape`/`CuboidShape` areas, `Room`/`Floor`/`FloorRegistry`, Coris' own
  `Componentable` (separate from Xerus's), and doors whose open/close
  events you fire yourself.

## Install

### Claude Code

```bash
/plugin install minestom-knowledge@onelitefeather-claude-marketplace
```

No MCP servers or external dependencies — this plugin is pure knowledge
(skills), nothing to configure.

### Codex

This plugin ships `.codex-plugin/plugin.json` (pointing at the same
`skills/` directory used above), matching Codex's documented plugin
manifest format. Install it through Codex's own `/plugins` browser once
this marketplace is registered there, or — the more immediately usable
path — clone or symlink the individual skill directories you want
(`skills/cyano/`, `skills/aves/`, etc.) into `~/.codex/skills/`.

### Antigravity (`agy`)

This plugin also ships `.antigravity-plugin/plugin.json`. **Not verified
live in this environment** (no `agy` CLI available to test against) — the
manifest follows the same shape as the Codex one as a best-effort
approximation. Try `agy plugin install <this-repo-url>` and confirm the
skills actually surface before relying on it; please report back (or open
an issue) if the manifest needs adjusting.
