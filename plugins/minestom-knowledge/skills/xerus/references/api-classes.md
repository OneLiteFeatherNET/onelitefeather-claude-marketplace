# Xerus: full class inventory

SKILL.md covers the workflow (component pattern, kits, teams, phase system, events). This file lists every class
for quick lookup.

## `api` (root) and `api.component`

| Class | Role |
|---|---|
| `Joinable` (interface) | Verified: `addPlayer(Player)` (default, delegates to the consumer overload with `null`), `addPlayer(Player, @Nullable Consumer<Player>)`, plus set-based bulk variants (`addPlayers(...)`). Implemented by `Team`. |
| `Componentable` (interface) | Verified: `<T extends ObjectComponent> add(Class<T>, T)`, `has(Class<T>)`, plus a getter keyed the same way. |
| `ObjectComponent` (interface) | Marker interface, no members. |
| `ColorData`, `ItemShiftOption` | Not read in detail. |
| `component.Componentable`/`component.ObjectComponent` are the same types listed above (package `api.component`) — not a separate hierarchy. |
| `component.team.ColorComponent` | Not read in detail — presumably an `ObjectComponent` for team color, attachable via `Team`'s `Componentable` surface. |

## `api.kit`

| Class | Role |
|---|---|
| `Kit` (interface, extends `Componentable`) | Verified: `apply(Player)`, `key() -> Key`. |
| `BaseKit` (abstract) | Verified: wires up the `Componentable` component map, constructor `(Key)`. |
| `KitService` (interface) | Verified: `of() -> KitService` (returns `DefaultKitService`), `add(Kit)`, `remove(Key) -> boolean`, `clear()`. Explicitly designed to be reimplemented, not extended, per its own javadoc. |
| `DefaultKitService` | Verified: package-private constructor (only reachable via `KitService.of()`), backed by an internal `List<Kit>`. |
| `event.PlayerKitChangeEvent` | Verified: `implements PlayerEvent, CancellableEvent`, constructor `(Player, @Nullable Kit currentKit, Kit newKit)`, `getPlayer()`. |

## `api.team`

| Class | Role |
|---|---|
| `Team` (interface, extends `Joinable`, `Componentable`, `Comparator<Team>`) | Verified: `EMPTY` (a no-op `Runnable` constant), `of(Key) -> Team`, `of(Key, int capacity) -> Team` (both return `DefaultTeam`). |
| `DefaultTeam` | The sole implementation returned by `Team.of(...)`, not read in detail beyond its constructor shape `(Key, int capacity)` (capacity `-1` = unlimited). |
| `TeamService` (interface, `@ApiStatus.NonExtendable`) | Verified: `of() -> TeamService` (returns `StandardTeamService`), `add(Team)`, `remove(Team)`, `remove(Key)`. |
| `StandardTeamService` | Verified: package-private constructor, backed by an internal `List<Team>`. |
| `distribution.TeamDistributor` (interface) | Verified: `distribute(List<Team>, List<Player>, int teamSize, ToIntFunction<Player> eloFunction, boolean evenTeams, boolean lowVariance)` and a shorter overload without the last two booleans. |
| `distribution.DefaultTeamDistributor` | Verified: throws `IllegalArgumentException` if `teams`/`players` is empty; wraps both into internal `DistributionTeam`/`DistributionPlayer` records for the balancing algorithm. |
| `distribution.DistributionTeam` / `DistributionPlayer` / `Splitter` | Internal types used by `DefaultTeamDistributor` — not part of the public API surface to call directly. |
| `event.TeamAction` (enum) | Verified: `ADD`, `REMOVE`. |
| `event.PlayerTeamEvent` / `MultiPlayerTeamEvent` | Carry a `TeamAction` (see SKILL.md) — not read in full detail beyond that they exist for single- vs. multi-player team changes. |

## `api.phase`

| Class | Role |
|---|---|
| `Phase` (abstract) | Verified full surface (see SKILL.md): `name`, `running`/`finished`/`skipping` flags, `finishedCallback`, `start()` (idempotent, calls abstract `onStart()`). |
| `GamePhase extends Phase` | Verified: internal `EventNode<Event>` + listener map, `addListener(Class<T>, Consumer<T>)`. |
| `TickedPhase extends GamePhase` (abstract) | Verified: abstract `onUpdate()`, does not schedule itself. |
| `TickingPhase extends TickedPhase` (abstract) | Verified full surface (see SKILL.md): schedules a repeating Minestom task in `onStart()`, cancels it in `finish()`, both `@MustBeInvokedByOverriders`; `getInterval()`, `getTemporalUnit()`, `getScheduledTask()`/`setScheduledTask(Task)`. |
| `TimedPhase extends TickingPhase` (abstract) | Verified full surface (see SKILL.md): tick counter with `TickDirection`, `endTicks`, `paused`; abstract `onFinish()`; `setPaused`/`isPaused`, `setTickDirection`/`getTickDirection`, `setEndTicks`/`getEndTicks`, `setCurrentTicks`/`getCurrentTicks`. |
| `TickDirection` (enum) | Verified: `UP`, `DOWN`. |
| `PhaseCollection<T extends Phase>` (abstract) | Verified: `extends Phase implements Iterable<T>, List<T>` — delegates all `List` operations to an internal `LinkedList<T>`. |
| `LinearPhaseSeries<T extends Phase> extends PhaseCollection<T>` | Verified: `currentPhase`/`currentPhaseIndex` fields, `paused` flag; constructors `(String name)` and `(String name, List<T> phases)`. |
| `CyclicPhaseSeries<T extends Phase> extends LinearPhaseSeries<T>` | Verified full surface (see SKILL.md): `advance()` override that restarts at index 0 instead of finishing, `skipIteration()`, `setMaxIterations(int)`/`getMaxIterations()`, `getIterations()`. |

## `api.event` (game-level, not team/kit-specific)

| Class | Role |
|---|---|
| `GamePreLaunchEvent` | Verified: `implements Event`, no fields — plain marker fired before game start. |
| `GameFinishEvent<T>` | Verified: `implements Event`, constructor `(T reason)`, `getReason() -> T`. |

## Real consumers seen in the OneLiteFeatherNET org (useful as further examples beyond SKILL.md)

- **Voyager** has its own internal `.claude/skills/create-phase.md` documenting how *they* scaffold new
  `TimedPhase`/`TickingPhase` subclasses (SKILL.md's phase example is generalized from this) — worth reading their
  actual `MinestomLobbyPhase`/`MinestomGamePhase`/`MinestomEndPhase`/`GamePhaseFactory` classes for a complete,
  in-production phase pipeline rather than the single generalized example here.
- **Voyager**'s `docs/decisions/0008-cyclic-phase-series-for-practice-retry.md` documents why they built a custom
  cyclic phase series instead of using Xerus's `CyclicPhaseSeries` (see SKILL.md's note on its limits) — good
  reading for understanding where the built-in one stops being sufficient.
- **Tamias**, **Bounce**, **ManisGame**, **Cygnus** are sibling minigame projects, each with their own `game`
  module using `Team`/`Kit`/phases end-to-end (e.g. `ManisGame`'s `extensions/game/.../PlayingPhase.java`).
