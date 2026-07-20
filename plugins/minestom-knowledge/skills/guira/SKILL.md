---
name: guira
description: How to use Guira, OneLiteFeather's internal library for building setup flows on Minestom servers (github.com/OneLiteFeatherNET/Guira) — SetupDataService, custom SetupData types, categories, and the setup lifecycle events. Use this whenever implementing a setup/configuration flow for a game, minigame, or custom feature on a Minestom server at OneLiteFeather (e.g. "let the map builder configure spawn points and rules before the game starts"), or when reviewing/debugging code that already uses Guira's SetupDataService, SetupData, Category, or Setup*Event types.
---

# Guira: setup flows on Minestom

Guira is a lightweight library for building setup processes — a builder/admin walking through configuring a map,
game, or other feature before it goes live. It deliberately doesn't impose a fixed setup structure: you define what
your own setup data contains, and Guira just gives you a solid way to store, track, and manage it during the setup
session.

## The core building blocks

**`SetupDataService`** tracks in-progress setups by the UUID of whoever owns them (usually the player running the
setup):

```java
SetupDataService service = SetupDataService.create();

UUID owner = player.getUuid();
MySetupData data = new MySetupData(owner, /* ... */);
service.add(owner, data);

Optional<MySetupData> current = service.get(owner);
service.remove(owner);       // when the setup finishes or is abandoned
service.isEmpty();
service.clear();             // e.g. on shutdown
service.getView();           // unmodifiable Map<UUID, SetupData> if you need to inspect everything at once
```

One `SetupDataService` instance is typically enough per setup *kind* — create it once (e.g. as a field on the
feature/plugin that owns this setup flow), not per player.

**Example** (generalized from a real setup-flow entry point that combines Guira with Aves' map system):

```java
public final class GameSetup {

    private final MapProvider mapProvider;
    private final SetupDataService setupDataService;

    public GameSetup() {
        this.mapProvider = new SetupMapProvider(Path.of(""));
        this.setupDataService = SetupDataService.create();
    }

    // registered as a Minestom event listener elsewhere
    public void onSetupFinish(SetupFinishEvent event) {
        SetupData data = event.getData();
        if (event.isCancelled()) return; // library never blocks this for you — check it yourself
        data.save();
        setupDataService.remove(data.getId());
    }
}
```

The shape that recurs across real setup flows: one `SetupDataService` field owned by whatever class represents "the
setup process" for a feature, combined with a Guira/Aves-aware `MapProvider` when the setup is map-centered, and a
listener on `SetupFinishEvent` that does the actual persistence (`data.save()`) and cleans up the in-progress entry
— only after confirming the event wasn't cancelled.

**`SetupData`** is the interface you implement yourself for whatever your setup actually needs to track — Guira only
requires:

```java
public interface SetupData {
    void save();      // persist the collected data somewhere (file, database, ...)
    void reset();      // discard/restart the in-progress setup
    void loadData();   // (re)load from wherever save() wrote to
    UUID getId();       // the owner
}
```

If the setup is centered on a map, extend `MapSetupData<T extends BaseMap>` instead of implementing `SetupData`
directly — it wires up the map/`MapEntry` bookkeeping (`hasMapFile()`, `getEntry()`, `getMap()`) on top of Aves'
map types (`net.theevilreaper.aves.map`), so you only need to add whatever's specific to your setup. This is the one
place Guira leans on Aves — see the `aves` skill for the map system itself.

## Categories

`Category` groups related setup items for display (think: sections in a setup GUI, likely built with Aves'
inventory system — see the `aves` skill). It's a small interface (`key()`, `displayName()`, `material()`, `color()`),
with `BasicCategory` as a ready-made record implementation:

```java
Category myCategory = new BasicCategory(
    Key.key("mygame", "map_data/rules"),
    "Rules",
    Material.BOOK,
    NamedTextColor.GREEN
);
```

`SetupCategories` ships a few example categories (`NAME`, `AUTHOR`, `SPAWN`) under the `guira` namespace — treat
these as a pattern to follow (define your own `XyzCategories` holder class with `Key.key("<your-namespace>", ...)`
constants), not as categories every project is expected to reuse as-is.

## Setup lifecycle events

Guira defines `SetupCreateEvent` and `SetupFinishEvent`, both implementing Minestom's `Event` and
`CancellableEvent`, each carrying the relevant `SetupData`.

**Guira never fires these itself.** You call the setup process's own start/finish logic, and it's your responsibility
to construct the event and pass it to Minestom's event handler at the right point:

```java
SetupCreateEvent event = new SetupCreateEvent(data);
MinecraftServer.getGlobalEventHandler().call(event);
if (event.isCancelled()) {
    // your code decided to reject the setup start — handle that here
}
```

The same applies to cancellation: setting `setCancelled(true)` on the event only records the state. Nothing in Guira
reacts to it automatically — whatever logic starts or finishes the setup needs to check `isCancelled()` itself and
act accordingly (e.g. don't call `service.remove(owner)` if `SetupFinishEvent` came back cancelled).

## Pluggable retrieval strategies

If setup data needs to be looked up through something other than a direct `SetupDataService.get()` call (e.g.
resolving it through a cache or another system), Guira offers two functional interfaces to depend on instead of a
concrete service: `SetupDataGetter` (returns `@Nullable SetupData`) and `OptionalSetupDataGetter` (returns
`Optional<SetupData>`). Prefer these over depending directly on `SetupDataService` when the retrieval logic could
reasonably differ from "look it up in this one service instance."

## Testing

Guira's own service logic is plain in-memory bookkeeping — tests that only exercise `SetupDataService`/`SetupData`
don't need Cyano's `MicrotusExtension` at all, plain JUnit5 is enough (see `SetupDataServiceTest` in the Guira repo
for the pattern: `@BeforeAll` creates the service once, `@AfterEach` calls `service.clear()` to keep tests
independent). Only reach for Cyano (see the `cyano` skill) once a test actually touches Minestom state — e.g. firing
the setup events through a real `Instance`/`Player`.

## Further reference

`references/api-classes.md` has the full class inventory (every class in every package, with verified method
signatures) and points to real consumer projects in the org for more end-to-end examples.
