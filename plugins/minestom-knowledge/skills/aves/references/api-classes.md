# Aves: full class inventory

SKILL.md covers the workflow per subsystem. This file lists every class found in each package for quick lookup —
classes marked "not read in detail" weren't opened during research; check the source before relying on their exact
method names.

## `inventory` (the largest package)

| Class | Role |
|---|---|
| `InventoryBuilder` (abstract) | Base class, verified: `type` field, `inventoryLayout`/`dataLayout` state, `openFunction`/`closeFunction`/`inventoryClick` hooks. |
| `GlobalInventoryBuilder` / `PersonalInventoryBuilder` | Concrete flavors — shared vs. per-player instance. `PersonalInventoryBuilder` verified via the real example in SKILL.md (constructor `(Component, InventoryType, Player)`, `setLayout`, `register()`). |
| `GlobalTranslatedInventoryBuilder` / `PersonalTranslatedInventoryBuilder` | Per-locale variants of the above two, not read in detail. |
| `CustomInventory` | Verified via test file: constructor `(InventoryHolder, InventoryType, Component title)`, `getHolder()`, `getTitle()`. |
| `InventoryListenerHandler` | Not read in detail — likely wires Minestom inventory events to the builder's click/open/close functions. |
| `InventorySlot` | Not read in detail. |
| `click.ClickHolder` | Not read in detail — referenced as the click-handling attach point in SKILL.md. |
| `exception.ListenerStateException` | Thrown for invalid listener state transitions (name-inferred, not read in detail). |
| `function.ApplyLayoutFunction` / `DefaultApplyLayoutFunction` | Layout application hooks. |
| `function.CloseFunction` / `OpenFunction` / `InventoryClick` | The three behavior-hook functional interfaces mentioned in SKILL.md. |
| `holder.InventoryHolder` / `InventoryHolderImpl` | The holder abstraction `CustomInventory` is built from. |
| `layout.InventoryLayout` / `InventoryLayoutImpl` | Verified: `InventoryLayout.fromType(InventoryType)`, `setItem(int slot, ItemStack)`, `setItem(int slot, ItemStack, InventoryClick)`. |
| `pageable.PageableInventory` / `PageableInventoryBuilder` / `OpenableInventory` / `PlayerPageableInventoryImpl` | Multi-page inventory support (see SKILL.md). |
| `pageable.PageableControls` / `DefaultPageableControls` / `PageAction` | Page-navigation controls (next/previous page actions). |
| `pageable.TitleData` / `TitleDataBuilder` / `TitleDataImpl` / `TitleMapper` | Per-page title support (e.g. "Shop (2/5)"). |
| `slot.ISlot` / `Slot` / `EmptySlot` / `TranslatedSlot` | Slot abstraction — fixed item, placeholder, or per-locale variant. |
| `util.InventoryConstants` / `LayoutCalculator` | Verified: `LayoutCalculator.from(int...)` and `LayoutCalculator.repeat(int start, int end)` compute slot-index arrays (see SKILL.md example). |

## `file`

| Class | Role |
|---|---|
| `ModernFileHandler` / `ModernGsonFileHandler` | **Use these** (see SKILL.md) — `save(Path, T)`, `load(Path, Class<T>) -> Optional<T>`. |
| `FileHandler` / `GsonFileHandler` | **Deprecated since 1.9.0, slated for removal** — verified via javadoc. Don't recommend these. |
| `gson.ItemStackGsonTypeAdapter` / `ItemStackSerializerHelper` / `KeyGsonAdapter` / `MiniMessageComponentGsonAdapter` / `PositionGsonAdapter` / `UUIDGsonAdapter` | The type adapters bundled with `ModernGsonFileHandler` — `ItemStack`, `Key`, MiniMessage `Component`, `Pos`, `UUID`. |

## `hotbar`

| Class | Role |
|---|---|
| `HotBarLayout` | Not read in detail — hotbar-specific layout helper, likely analogous to `InventoryLayout` scoped to the 9-slot hotbar. |

## `i18n`

| Class | Role |
|---|---|
| `TextData` (record) | Verified full surface (see SKILL.md): `(String key, Component... args)`, `of(key, Component...)`, `of(key, String...)`, no-args-`key`-only constructor, `createComponent() -> TranslatableComponent`. |

## `item`

| Class | Role |
|---|---|
| `IItem` (sealed interface, permits `Item`, `TranslatedItem`) | Verified: `AIR` constant, `get() -> ItemStack` (locale-ignoring default), `get(Locale) -> ItemStack`. |
| `Item` (non-sealed) | Verified: `of(ItemStack.Builder)`, `of(ItemStack)`, `of(Material)` factories; locale-ignoring `get(Locale)`. |
| `TranslatedItem` | Not read in detail — the per-locale counterpart to `Item`, per `IItem`'s javadoc. |

## `map`

| Class | Role |
|---|---|
| `BaseMap` | Verified full surface: `(String name, @Nullable Pos spawn, @Nullable List<String> builders)`, `builder()`, `builder(BaseMap)`, `getSpawnOrDefault(Pos)`. |
| `BaseMapBuilder` | The builder returned by `BaseMap.builder()` — not read in detail beyond its role. |
| `MapEntry` (sealed, permits `BaseMapEntry`) | Verified: `MAP_FILE = "map.json"` constant, `of(Path)`, `of(Path, String customFileName)`, `createFile()`, `hasStandardEnding()`, `hasMapFile()`. |
| `BaseMapEntry` | The sole implementation of `MapEntry` — not read in detail. |
| `provider.MapProvider` (interface) / `AbstractMapProvider` | The extension point for resolving/loading a `BaseMap` from storage (see SKILL.md). Real consumers implement this as e.g. `SetupMapProvider` (seen in `Bounce`). |

## `resourcepack`

| Class | Role |
|---|---|
| `ResourcePackHandler` | Verified: constructors `(ResourcePackInfo)` and `(ResourcePackInfo, ResourcePackCondition)`, `setCondition(ResourcePackCondition)`, internal `Set<UUID>` acceptance cache, reacts to `PlayerResourcePackStatusEvent`. |
| `ResourcePackCondition` (interface) / `DefaultResourcePackCondition` | The pluggable accept/decline/fail handling passed to `ResourcePackHandler`. |

## `util` and subpackages

| Class | Role |
|---|---|
| `Items` | Verified full surface: `MAX_STACK_SIZE = 64`, `getAmountFromItem(Player, ItemStack) -> int`, `getFreeSpace(Player) -> int`. |
| `Broadcaster`, `Components`, `Futures`, `Players`, `Positions`, `Strings`, `TimeFormat` | Not read in detail — smaller focused helpers, check by name before writing a new one-off utility. |
| `collection.ProbabilityCollection` | Not read in detail — weighted random selection (see SKILL.md). |
| `vector.Vec2D` / `Vectors` | Not read in detail — 2D vector math alongside Minestom's `Pos`/`Vec`. |
| `exception.ThrowingException` | Not read in detail. |
| `functional.*` (`BaseMapBiFunction`, `BaseMapFunction`, `ItemBiFunction`, `ItemFunction`, `ItemPlacer`, `ItemStackBiFunction`, `ItemStackFunction`, `PathFilter`, `PlayerConsumer`, `ThrowingFunction`, `VoidConsumer`) | Minestom-flavored functional interfaces used throughout the inventory/item/map APIs above. |

## Real consumers seen in the OneLiteFeatherNET org (useful as further examples beyond SKILL.md)

`Manouria`, `Kali`, `Bounce`, `Titan`, `Cygnus` all build real inventory menus on top of `InventoryBuilder`/
`InventoryLayout` — e.g. `Manouria`'s `lobby/src/main/java/net/theevilreaper/manouria/lobby/inventory/` package
(the source of SKILL.md's `ProfileInventory` example) has several sibling inventory classes worth reading for more
variety than one example shows.
