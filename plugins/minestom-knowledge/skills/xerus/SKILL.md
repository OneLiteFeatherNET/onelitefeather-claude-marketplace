---
name: xerus
description: How to use Xerus, OneLiteFeather's core minigame library for Minestom (github.com/OneLiteFeatherNET/Xerus) — kits, teams (including ELO-based team distribution), the phase system for game state flow, and the associated events. Use this whenever building a Minecraft minigame on Minestom at OneLiteFeather — implementing player loadouts/kits, team management or balanced team assignment, or a sequence of game states (lobby → countdown → active → end). Xerus only works with Minestom and Minestom forks, never with Paper/Bukkit — don't apply its patterns to a Paper project.
---

# Xerus: core minigame library

Xerus provides the recurring building blocks a Minecraft minigame needs on top of Minestom: kits, teams, and a
phase system for game flow. It's Minestom-only — trying to use it on Paper/Bukkit fails outright due to the
different server architecture.

## The component pattern (shared by Kit and Team)

Both `Kit` and `Team` extend `Componentable`, a small composition mechanism used throughout Xerus instead of
subclassing for every variation:

```java
<T extends ObjectComponent> void add(Class<T> componentClass, T component);
<T extends ObjectComponent> boolean has(Class<T> componentClass);
// plus a getter, keyed the same way
```

`ObjectComponent` is just a marker interface — define your own component types (e.g. a `CooldownComponent`, a
`PriceComponent`) and attach them to a `Kit` or `Team` instance rather than adding fields/subclasses for every
feature a kit or team might optionally have.

## Kits

- **`Kit`** (interface, extends `Componentable`): `apply(Player)` gives the player the kit's loadout, `key()`
  identifies it.
- **`BaseKit`** is the abstract base to extend for a concrete kit — it already wires up the component map from
  `Componentable`, so a new kit implementation only needs to implement `apply(Player)` and provide a `Key`.
- **`KitService`**: `KitService.of()` gives you the default in-memory implementation (`DefaultKitService`) —
  add/remove(by `Key`)/clear/list. If the default (plain in-memory list) doesn't fit — e.g. kits need to be
  persisted or resolved dynamically — implement `KitService` yourself; it's designed to be swapped out, not
  extended.
- **`PlayerKitChangeEvent`** (`PlayerEvent`, `CancellableEvent`) fires when a player switches kits — carries the
  player, the current kit (nullable — no kit yet), and the new kit. Cancel it to block the switch (e.g. kit locked
  during an active round).

## Teams

- **`Team`** (interface, extends `Joinable`, `Componentable`, `Comparator<Team>`): `Team.of(key)` for unlimited
  capacity, `Team.of(key, capacity)` to cap it — both return the default `DefaultTeam` implementation.
- **`TeamService`** is marked `@ApiStatus.NonExtendable` — always go through `TeamService.of()`
  (→ `StandardTeamService`), don't implement the interface yourself the way you might with `KitService`.
- **`Joinable`** (also implemented by `Team`) standardizes adding players: `addPlayer(player)` /
  `addPlayer(player, consumer)` for a callback after the add, plus set-based bulk variants. Use the `Consumer`
  overload when something needs to react to the add (announce, apply team cosmetics, etc.) instead of adding the
  player and then separately checking team membership.
- **Team events**: `MultiPlayerTeamEvent` / `PlayerTeamEvent` carry a `TeamAction` (`ADD` or `REMOVE`) so one
  listener can handle both joining and leaving instead of needing separate event types.

### Balanced team distribution

`TeamDistributor` (default impl `DefaultTeamDistributor`) solves the "split these players into fair teams" problem
using per-player ELO ratings rather than a naive round-robin:

```java
TeamDistributor distributor = new DefaultTeamDistributor();
distributor.distribute(teams, players, teamSize, player -> eloService.get(player), true, true);
```

The `eloFunction` (`ToIntFunction<Player>`) is how you plug in wherever ELO/skill ratings actually come from —
Xerus doesn't store ratings itself. `evenTeams` aims for equal team sizes, `lowVariance` aims to keep per-team
average ELO close across teams rather than just filling teams in order. Both `teams` and `players` must be
non-empty — the default implementation throws `IllegalArgumentException` otherwise, so validate before calling this
in a context where empty lists are possible (e.g. not enough players queued).

## Phase system (game flow)

A `Phase` is one unit of game flow — a lobby wait, a countdown, the active round, results. The hierarchy has five
levels, each adding one capability on top of the last — **pick the shallowest one that does what the phase needs,
don't reach for `TimedPhase` out of habit when a phase never needs a duration:**

- **`Phase`** — bare state machine: `start()`/`finish()`, `running`/`finished`/`skipping` flags, an optional
  `finishedCallback`. Extend directly only if the phase needs neither events nor per-tick logic.
- **`GamePhase extends Phase`** — adds Minestom event listener registration/cleanup scoped to the phase's lifetime
  (an internal `EventNode`, via `addListener(eventClass, consumer)`). Use this for phases driven by player
  actions/events rather than time (e.g. "phase ends when N players reach the goal").
- **`TickedPhase extends GamePhase`** — adds an abstract `onUpdate()` for per-tick logic. **It does not schedule
  itself** — this level only defines the method; nothing calls it yet. Rarely extended directly.
- **`TickingPhase extends TickedPhase`** — this is the one that actually makes `onUpdate()` run: `onStart()`
  schedules a repeating Minestom task (`MinecraftServer.getSchedulerManager().buildTask(this::onUpdate).repeat(interval, unit).schedule()`) and `finish()` cancels it. Use this for a phase that runs indefinitely until something
  else decides it's done — the phase's own logic calls `finish()` when its exit condition is met.
- **`TimedPhase extends TickingPhase`** — adds a tick counter with a `TickDirection` (`UP`/`DOWN`) that
  auto-finishes when it reaches a configured `endTicks`, plus `setPaused(boolean)`. Use this for a phase with a
  fixed duration — a lobby countdown, a results screen shown for N seconds.
  **`onFinish()` is abstract here** (not just `finish()`) — implement it for cleanup, and note `finish()` calls
  `onFinish()` before delegating up the chain, so don't call `onFinish()` yourself.

Both `TickingPhase` and `TimedPhase` mark their lifecycle overrides `@MustBeInvokedByOverriders` — if a phase
overrides `onStart()` or `finish()`, it **must** call `super.onStart()`/`super.finish()`, or the scheduled task
never gets created/cancelled and the phase silently breaks.

**Example** (a fixed-duration countdown phase, generalized from a real internal phase-authoring pattern):

```java
public final class CountdownPhase extends TimedPhase {

    private static final int DEFAULT_DURATION_TICKS = 200;

    private final int durationTicks;
    private final Runnable onFinishCallback;

    public CountdownPhase(int durationTicks, Runnable onFinishCallback) {
        super("countdown", TimeUnit.SERVER_TICK, 20);
        this.durationTicks = durationTicks;
        this.onFinishCallback = onFinishCallback;
        setEndTicks(0);
        setCurrentTicks(durationTicks);
        setTickDirection(TickDirection.DOWN);
    }

    @Override
    public void onStart() {
        setCurrentTicks(durationTicks);
        super.onStart(); // schedules the repeating task — must call this
    }

    @Override
    public void onUpdate() {
        broadcastRemainingTime(getCurrentTicks());
    }

    @Override
    protected void onFinish() {
        if (onFinishCallback != null) onFinishCallback.run();
    }
}
```

A phase with no fixed duration — e.g. the active round, which ends when a win condition is met rather than a
timer — extends `TickingPhase` instead and calls `finish()` itself from inside `onUpdate()` once that condition is
true; it has no `endTicks`/`TickDirection` to configure.

### Running phases in sequence

**`PhaseCollection<T extends Phase>`** is the shared base for phase sequences — it's a `Phase` itself that also
implements `List<T>`, delegating storage to an internal list. Two concrete series build control logic on top of it:

- **`LinearPhaseSeries<T>`** — advances to the next phase automatically when the current one finishes, runs through
  the list once, and supports pausing/skipping/manual advance.
- **`CyclicPhaseSeries<T> extends LinearPhaseSeries<T>`** — repeats the whole phase list up to a configured
  `setMaxIterations(int)`: when the last phase finishes, it restarts at index 0 instead of finishing, until the
  iteration count is reached, then the series itself finishes. `skipIteration()` jumps straight to the next
  iteration without waiting for the current phase to finish naturally.

**Xerus's `CyclicPhaseSeries` only supports "repeat this exact list N times."** If a game needs a more elaborate
loop — e.g. an intro that runs once, then a cycle of phases that repeats an unbounded number of times until some
external condition breaks it, then an outro — that's a different shape than what `CyclicPhaseSeries` provides.
At least one internal project hit exactly this limit and built its own cyclic series with `intro`/`cycle`/`outro`
phase lists and an explicit `breakCycle()` rather than stretching Xerus's version to fit; that's a reasonable path
to reach for if `setMaxIterations` genuinely doesn't model the flow, rather than working around it with phases that
manipulate the series' internal state.

## Game-level events

- **`GamePreLaunchEvent`** — plain marker event, fired before the actual game starts, for last-moment preparation.
  Exactly when/why it's called is left to the implementation using Xerus, not fixed by the library.
- **`GameFinishEvent<T>`** — generic over the "reason" the game ended (`getReason()`); define your own reason type
  (e.g. an enum `TIME_UP`, `LAST_TEAM_STANDING`, `ABORTED`) rather than reusing a generic `String` or `Object`
  reason, so listeners can pattern-match on it meaningfully.

## i18n

Xerus supports internationalized text in the parts of the API that render to players (per its README). If a game
needs multi-language kit names, team names, etc., check whether the relevant type already accepts translatable
content before building a separate i18n layer on top — and see the `aves` skill for `TextData`/`IItem`, which Xerus
projects commonly use for this alongside Xerus itself.

## Further reference

`references/api-classes.md` has the full class inventory (every class in every package, with verified method
signatures) and points to real consumer projects — including Voyager's own phase-authoring skill and ADR — for
deeper examples than the single generalized one above.
