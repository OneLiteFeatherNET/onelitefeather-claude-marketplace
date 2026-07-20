# Guira: full class inventory

SKILL.md covers the workflow (SetupDataService, custom SetupData, categories, lifecycle events). This file lists
every class for quick lookup.

## `net.onelitefeather.guira`

| Class | Role |
|---|---|
| `SetupDataService` (interface) / `SetupDataServiceImpl` | Verified full surface: `create()` (static factory), `isEmpty()`, `clear()`, `add(UUID, SetupData)`, `remove(UUID) -> Optional<SetupData>`, `get(UUID) -> Optional<SetupData>`, `getView() -> @UnmodifiableView Map<UUID, SetupData>`. |

## `net.onelitefeather.guira.data`

| Class | Role |
|---|---|
| `SetupData` (interface) | Verified full surface: `save()`, `reset()`, `loadData()`, `getId() -> UUID`. Implement this yourself for project-specific setup data. |
| `MapSetupData<T extends BaseMap>` (abstract) | Verified: implements `SetupData`, adds `hasMapFile()`, `getEntry() -> MapEntry`, `getMap() -> Optional<T>`. Depends on Aves' `net.theevilreaper.aves.map` types (`BaseMap`, `MapEntry`) — see the `aves` skill. |

## `net.onelitefeather.guira.category`

| Class | Role |
|---|---|
| `Category` (interface) | Verified full surface: `key() -> Key`, `displayName() -> String`, `material() -> Material`, `color() -> TextColor`. |
| `BasicCategory` (record) | Verified: `record BasicCategory(Key key, String displayName, Material material, TextColor color) implements Category`. |
| `SetupCategories` | Verified: holder class with example constants `NAME`, `AUTHOR`, `SPAWN` under the `"guira"` namespace — a pattern to copy, not a fixed taxonomy (see SKILL.md). |

## `net.onelitefeather.guira.event`

| Class | Role |
|---|---|
| `SetupCreateEvent` | Verified: `implements Event, CancellableEvent`, constructor `(SetupData data)`, `getData()`. Never fired automatically — see SKILL.md. |
| `SetupFinishEvent` | Verified: same shape as `SetupCreateEvent` — `implements Event, CancellableEvent`, constructor `(SetupData setupData)`, `getData()`. |

## `net.onelitefeather.guira.functional`

| Class | Role |
|---|---|
| `SetupDataGetter` (functional interface) | Verified: `@Nullable SetupData getData(@NotNull UUID uuid)`. |
| `OptionalSetupDataGetter` (functional interface) | Verified: `Optional<SetupData> get(UUID uuid)`. |

## Real consumers seen in the OneLiteFeatherNET org (useful as further examples beyond SKILL.md)

`Bounce`, `Tamias`, and `Cygnus` are sibling Minestom minigame projects (same family as `ManisGame`) that each have
their own `setup` module combining Guira with Aves (`MapProvider`) and Pica (dialogs) — e.g. `Bounce`'s
`setup/src/main/java/net/theevilreaper/bounce/setup/BounceSetup.java`. Worth reading one of these end-to-end when a
new setup flow needs to see how Guira, Aves, and Pica are wired together in one real feature, not just each library
in isolation.
