<!-- EXAMPLE, not copy-ready. This page shows the state AFTER a generator and its CI gate exist:
     the 🤖 banner below is only correct because, in this fictional project, `docs-generate` really
     does write the page. A page you transcribe by hand gets the ✍️ pending banner instead — see
     references/reference-pages.md, "There are two banners and they must never be confused".
     Copy the entry structure, the field order and the voice; never copy the banner. -->

# Configuration

> **🤖 Generated** from `src/main/resources/config.yml` by the `docs-generate` Gradle task. Do not
> edit by hand; run `./gradlew generateDocs` to update.

All settings live in `plugins/<Plugin>/config.yml`. Unless stated otherwise, a change takes
effect after `/arcm reload`.

## check

### `check.mode`

| | |
|---|---|
| Type | enum |
| Default | `dynamic` |
| Allowed values | `dynamic`, `static` |
| Reload | `/arcm reload` |
| Since | 2.1.0 |
| Source | `Config.check.mode` |

Selects the detection strategy. The trade-off between the two is described in
[detection modes](../explanation/detection-modes.md).

```yaml
check:
  mode: 'static'
```

### `check.ignoredWorlds`

| | |
|---|---|
| Type | list of strings, world names |
| Default | `['world']` |
| Reload | `/arcm reload` |
| Since | 1.0.0 |
| Source | `Config.check.ignoredWorlds` |

Worlds in which detection does not run.

```yaml
check:
  ignoredWorlds:
    - world
    - creative_plots
```

### `check.hopper`

| | |
|---|---|
| Type | boolean |
| Default | `true` |
| Reload | `/arcm reload` |
| Since | 2.4.0 |
| Source | `Config.check.hopper` |

Detects hopper clocks, a pair of hoppers facing each other and passing an item back and forth.

```yaml
check:
  hopper: false
```

## clock

### `clock.endDelay`

| | |
|---|---|
| Type | integer, ticks |
| Default | `300` |
| Reload | `/arcm reload` |
| Since | 1.0.0 |
| Source | `Config.clock.endDelay` |

Ticks without a state change after which a detection is dropped from the cache. At 20 TPS,
300 ticks is 15 seconds.

```yaml
clock:
  endDelay: 600
```
