---
name: aves
description: How to use Aves, OneLiteFeather's general utility library for Minestom servers (github.com/OneLiteFeatherNET/Aves) — GUI inventories, file persistence, i18n/translated text and items, maps, resource packs, and misc utilities (items, vectors, probability collections). Use this whenever building a GUI/menu, persisting data to JSON, sending translated messages or items, defining a game map, handling resource pack delivery, or reaching for a small utility (item counting, weighted random pick, vector math) in a OneLiteFeather Minestom project — Aves is internal-only and covers ground that would otherwise be reinvented per project.
---

# Aves: general Minestom utilities

Aves is a grab-bag utility library — each area below is independent, so jump to the one relevant to the task rather
than reading top to bottom. All of it targets Minestom specifically (imports `net.minestom.server.*`, Adventure
components), not generic Java.

## Inventories (GUIs)

The largest subsystem: a fluent builder API for custom inventory menus.

- **`InventoryBuilder`** is the abstract base with three concrete flavors: `GlobalInventoryBuilder` (one shared
  inventory instance for all viewers), `PersonalInventoryBuilder` (one instance per player), and their
  `...Translated...` variants for per-locale content/titles.
- **`CustomInventory`** wraps the actual Minestom `Inventory`, created with a type, holder, and title
  (`Component`).
- Slots are `ISlot` (`Slot` for a fixed item, `EmptySlot` for a placeholder gap), placed via an `InventoryLayout`
  (built through `LayoutCalculator`/`InventoryConstants` for consistent sizing).
- Click handling goes through `ClickHolder` and the `function` package's `InventoryClick`/`OpenFunction`/
  `CloseFunction`/`ApplyLayoutFunction` — register behavior as functions on the builder rather than subclassing
  Minestom's inventory listeners directly.
- **Pageable inventories** (`PageableInventory`, `PageableInventoryBuilder`, `PageableControls`,
  `DefaultPageableControls`) handle multi-page menus — `TitleData`/`TitleDataBuilder`/`TitleMapper` let the title
  reflect the current page (e.g. "Shop (2/5)") without you tracking that by hand.

**Example** (generalized from a real per-player profile menu — a subclass extending `PersonalInventoryBuilder`
directly rather than using it as a standalone builder instance):

```java
public final class ProfileInventory extends PersonalInventoryBuilder {

    private static final int[] STAT_SLOTS = LayoutCalculator.from(21, 22, 23, 24);

    ProfileInventory(@NotNull Player player) {
        super(Component.empty(), InventoryType.CHEST_4_ROW, player);

        InventoryLayout layout = InventoryLayout.fromType(getType());
        setLayout(layout);

        applyStatSlots(layout);
        register(); // registers the inventory/click listeners — required before it's usable
    }

    private void applyStatSlots(@NotNull InventoryLayout layout) {
        for (int i = 0; i < STAT_SLOTS.length; i++) {
            layout.setItem(STAT_SLOTS[i], someStatItem(i));
        }
    }
}

// elsewhere: a static factory hides construction behind a stable call site
public static @NotNull InventoryBuilder createProfileInventory(@NotNull Player player) {
    return new ProfileInventory(player);
}
```

The recurring shape: subclass the flavor that matches the audience (`PersonalInventoryBuilder` here — one instance
per player), build the `InventoryLayout` from the inventory's own `getType()`, place items via
`layout.setItem(slot, item)` (or `layout.setItem(slot, item, clickLogic)` for clickable slots — see `ClickHolder`/
`InventoryClick`), and call `register()` at the end of the constructor. `LayoutCalculator.from(...)`/
`LayoutCalculator.repeat(...)` compute slot-index arrays so slot numbers don't have to be hand-counted.

## Persisting data (file)

**Use `ModernFileHandler` / `ModernGsonFileHandler`, not `FileHandler`/`GsonFileHandler` — the older pair is
deprecated since 1.9.0 and slated for removal.** Both handle JSON load/save (`save(Path, T)`,
`load(Path, Class<T>) -> Optional<T>`); the Gson variant comes with Aves' own type adapters
(`file/gson/`) so common Minestom/Adventure types serialize correctly out of the box: `ItemStack`
(`ItemStackGsonTypeAdapter`), `Key`, MiniMessage `Component`, `Pos`, and `UUID`. Reach for these adapters instead of
writing custom Gson (de)serialization for these types — that's exactly the boilerplate they exist to remove.

## Translated text and items (i18n)

- **`TextData`** is a `(key, Component... args)` record for a translatable message —
  `TextData.of("some.key", arg1, arg2).createComponent()` gives you Adventure's `Component.translatable(key, args)`.
  There's also a `String...` overload that wraps plain strings into `Component.text(...)` args automatically.
- **`IItem`** is the translated-item counterpart: a sealed interface with two implementations —
  `Item` for items that don't need translation (`get()`/`get(locale)` both return the same stack) and
  `TranslatedItem` for items whose name/lore should vary per player locale. Use `IItem.AIR` for an explicit "no
  item" placeholder instead of `null` or `ItemStack.AIR` directly, so intent is clear at the call site.

## Maps

- **`BaseMap`**: name, optional spawn `Pos`, optional builder list — the common shape every game map needs, built
  via `BaseMap.builder()...` (or `BaseMap.builder(existing)` to copy-and-modify). Extend it (don't wrap it) when a
  game needs more than these three fields.
- **`MapEntry`** ties a map to its on-disk representation: a directory plus a data file (`map.json` by default).
  `MapEntry.of(directoryRoot)` uses the default filename; pass a second argument for a custom one.
  `hasMapFile()`/`hasStandardEnding()`/`createFile()` let you check and initialize the on-disk state without
  hand-rolling path/file-existence logic.
- `map/provider` (`MapProvider`, `AbstractMapProvider`) is the extension point for actually resolving/loading a
  `BaseMap` from storage — implement this rather than loading map files ad hoc when a feature needs map data.

This is also what Guira's `MapSetupData<T extends BaseMap>` builds on for map-centered setup flows — see the `guira`
skill.

## Resource packs

**`ResourcePackHandler`** manages sending a resource pack to players and tracking who has one already (an internal
`Set<UUID>` cache, so it won't needlessly re-push). Give it a `ResourcePackCondition` (or use
`DefaultResourcePackCondition`) to define what happens on `PlayerResourcePackStatusEvent` — accepted, declined,
failed, etc. — instead of subscribing to that event directly in your own code.

## Utilities

Grab only what's needed — these are independent one-off helpers, not a cohesive API:

- **`Items`** — inventory-level item helpers: `getAmountFromItem(player, item)` counts matching stacks across a
  player's inventory, `getFreeSpace(player)` sums remaining stack capacity.
- **`util.collection.ProbabilityCollection`** — weighted random selection; reach for this instead of hand-rolling
  cumulative-weight logic for loot tables, random rewards, etc.
- **`util.vector.Vec2D`** / **`Vectors`** — 2D vector math helpers alongside Minestom's own `Pos`/`Vec`.
- **`Broadcaster`, `Components`, `Players`, `Positions`, `Strings`, `TimeFormat`, `Futures`** — smaller focused
  helpers; check here before writing a new one-off utility method, since a Minestom-flavored equivalent may already
  exist.
- **`util.functional`** — Minestom-flavored functional interfaces (`ItemFunction`, `ItemStackBiFunction`,
  `PlayerConsumer`, `ThrowingFunction`, `PathFilter`, etc.) used throughout the inventory/item APIs above — useful
  when writing code that plugs into those APIs, not generally needed standalone.

## Further reference

`references/api-classes.md` has the full class inventory for all 7 subsystems (including classes not detailed
above) and points to real consumer projects in the org for more inventory-menu examples.
