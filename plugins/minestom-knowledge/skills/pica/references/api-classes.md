# Pica: full class inventory

SKILL.md covers the workflow (confirm dialogs, input fields, registry, event). This file lists every class for
quick lookup.

## `dialog` (root)

| Class | Role |
|---|---|
| `DialogTemplate` (interface) | Verified: `of(Key, net.minestom.server.dialog.Dialog) -> DialogTemplate` (wraps a raw Minestom dialog), `open(Player)`, `key()`. |
| `MinestomDialogTemplate` | The sole implementation returned by `DialogTemplate.of(...)`. |
| `DialogRegistry` (interface) | Verified: `of() -> DialogRegistry`, `add(DialogTemplate)`, `remove(Key) -> @Nullable DialogTemplate`, `contains(Key) -> boolean`, plus a getter (not fully read, used as `registry.get(key)` in SKILL.md). |
| `DefaultDialogRegistry` | The sole implementation returned by `DialogRegistry.of()`. |
| `DialogConstants` | Verified referenced constants/validation: `DEFAULT_ACTION_WIDTH`, `DEFAULT_WIDTH`, `validateWidth(int)`. |

## `dialog.type`

| Class | Role |
|---|---|
| `DialogType` (interface) | Verified: `confirm(Key) -> ConfirmDialog` (static factory), `meta(Consumer<DialogMeta>) -> DialogType`, `build() -> DialogTemplate`. |
| `ConfirmDialog` (interface, extends `DialogType`) | Verified: overrides `meta(...)` to return `ConfirmDialog`, adds `yesButton(Consumer<ActionButton>)`, `noButton(Consumer<ActionButton>)`. |
| `ConfirmationDialog` | The sole implementation returned by `DialogType.confirm(key)`. |

## `dialog.action`

| Class | Role |
|---|---|
| `ActionButton` (interface) | Verified via `ActionButtonBuilder`: `label(Component)`, `tooltip(Component)`, `width(int)` (validated via `DialogConstants`), and (per SKILL.md's real example) `action(DialogAction)`. |
| `ActionButtonBuilder` | The implementation, package-private constructor — obtained via the builder consumers in `.yesButton(...)`/`.noButton(...)`. |

## `dialog.display`

| Class | Role |
|---|---|
| `BodyTemplate` | Not read in detail — the type behind `dialogMeta.messageBody(template -> ...)`. |
| `component.ComponentTemplate` / `PlainMessageBuilder` | Verified: `ComponentTemplate.builder().contents(Component).build()` used for `DialogMeta.EMPTY`'s body. |
| `item.ItemTemplate` / `ItemTemplateBuilder` | Not read in detail — likely the item-display counterpart to `ComponentTemplate` for dialogs showing an item. |

## `dialog.event`

| Class | Role |
|---|---|
| `PlayerOpenDialogEvent` | Verified full surface (see SKILL.md): `implements PlayerEvent, CancellableEvent`, constructor `(Player, Key)`, `getKey()`. |

## `dialog.input`

| Class | Role |
|---|---|
| `InputTemplate` (interface) | Not read in detail — likely the shared parent interface for the four input template types below. |
| `bool.BooleanTemplate` / `BooleanInputBuilder` | Verified full surface (see SKILL.md): `label(Component)`, `initialValue(boolean)`, `onTrue(String)`, `onFalse(String)`; constructor takes a `String key`. |
| `option.SingleOptionTemplate` / `SingleOptionBuilder` | Not read in detail beyond its role (pick-one-of-N). |
| `range.RangeTemplate` / `RangeTemplateBuilder` | Verified full surface (see SKILL.md): `key`, `width` (defaults to `DialogConstants.DEFAULT_WIDTH`), `label`, `labelFormat` (defaults to `"options.generic_value"`), `start`/`end`/`initial`/`step` (float). |
| `text.TextInputTemplate` / `TextInputBuilder` | Verified via SKILL.md's real example: attached through `DialogMeta.text(String key, Consumer<TextInputTemplate>)`, builder methods seen in use: `maxLength(int)`, `initial(String)`. |

## `dialog.meta`

| Class | Role |
|---|---|
| `DialogMeta` (sealed interface, permits `DialogMetaData`, `@ApiStatus.NonExtendable`) | Verified members: `EMPTY` (a `DialogBody` constant), `title(Component)`, `externalTitle(Component)`. Verified via real usage (not the interface declaration itself): `closeWithEscape(boolean)`, `pause(boolean)`, `afterAction(DialogAfterAction)`, `messageBody(Consumer<BodyTemplate>)`, `emptyMessage()`, `text(String key, Consumer<TextInputTemplate>)`. Other input-registering methods (for boolean/range/single-option) likely follow the same `<methodName>(key, consumer)` shape as `text(...)` — verify the exact method name in the interface before assuming it. |
| `DialogMetaData` | The sole implementation of `DialogMeta`. |

## Real consumers seen in the OneLiteFeatherNET org (useful as further examples beyond SKILL.md)

`ManisGame`, `Tamias`, `Cygnus` each have a `setup/.../dialog/` package with several `*Dialogs` utility classes
(e.g. `DayDialogs`, `AuthorDialogs`, `MapDialogs` — SKILL.md's example is generalized from `ManisGame`'s
`DayDialogs`) — reading a couple of these side by side is the fastest way to see the range of `DialogMeta` methods
actually used in production, beyond the single example in SKILL.md.
