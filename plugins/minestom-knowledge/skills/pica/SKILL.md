---
name: pica
description: How to use Pica, OneLiteFeather's lightweight Dialog API for Minestom's native dialog system (github.com/OneLiteFeatherNET/pica) — confirmation dialogs, custom dialogs with inputs (boolean, range, single-option, text), and the DialogRegistry/PlayerOpenDialogEvent. Use this whenever showing a player a native Minecraft dialog on a Minestom server at OneLiteFeather (a confirm/cancel prompt, a settings menu, an in-game form) instead of building a custom chat/inventory-based menu — Minestom's raw dialog API is verbose, Pica wraps it into a builder.
---

# Pica: native dialogs on Minestom

Pica wraps Minestom's native dialog system (the vanilla Minecraft dialog UI, not a chat menu or inventory GUI) in a
builder API. Reach for it whenever a native yes/no prompt or settings-style form fits better than an Aves inventory
menu — see the `aves` skill for the inventory-GUI alternative when a click-based menu is the better fit instead.

## Confirmation dialogs (with a text input field)

The common case — a yes/no prompt, here extended with a text field — goes through `DialogType.confirm(key)`.
**Example** (generalized from a real "create an item" dialog used in a setup flow):

```java
public static final Key CREATE_KEY = Key.key("mygame", "setup_create");

public static void openCreateDialog(Player player) {
    DialogTemplate dialog = DialogType.confirm(CREATE_KEY)
        .meta(meta -> {
            meta.closeWithEscape(false);
            meta.pause(false);
            meta.afterAction(DialogAfterAction.CLOSE);
            meta.title(Component.text("Create a new entry"));
            meta.messageBody(body -> body.contents(Component.text("Give it an id")));
            meta.text("entry_id", input -> input.maxLength(100).initial(""));
        })
        .yesButton(button -> button.width(101).label(Component.text("Save"))
            .action(new DialogAction.DynamicCustom(CREATE_KEY, emptyPayload())))
        .noButton(button -> button.width(101).label(Component.text("Cancel")))
        .build();

    dialog.open(player);
}
```

`DialogType.confirm(key)` returns a `ConfirmDialog` builder (itself a `DialogType`), so `.meta(...)` is always
available; `ConfirmDialog` adds `.yesButton(...)`/`.noButton(...)` on top. `.build()` produces an immutable
`DialogTemplate` — build once per call (or cache it if the content never varies), call `.open(player)` per player.
`meta.pause(false)` keeps the game unpaused behind the dialog (relevant on singleplayer-style pause semantics);
`meta.text(key, builder)` is how a `TextInputTemplate` attaches to the dialog — the same `key` is what the
resulting `DialogAction`/payload handling reads the submitted value back by.

For a dialog wrapping raw Minestom `Dialog` content directly (bypassing Pica's builders entirely), use
`DialogTemplate.of(key, minestomDialog)`.

## Other input field types

Beyond `.text(key, builder)`, `DialogMeta` has matching methods for the other input templates, each with its own
builder following the same fluent-setter shape as the text input above:

- **`BooleanTemplate`/`BooleanInputBuilder`** — a toggle: `.label(...)`, `.initialValue(bool)`,
  `.onTrue(String)`/`.onFalse(String)` to control what value gets submitted for each state.
- **`RangeTemplate`/`RangeTemplateBuilder`** — a numeric slider: `.start(...)`, `.end(...)`, `.initial(...)`,
  `.step(...)`. `labelFormat` defaults to `"options.generic_value"` (a vanilla Minecraft translation key) — override
  it only if the slider needs a different label format than vanilla's generic one.
- **`SingleOptionTemplate`/`SingleOptionBuilder`** — pick-one-of-N selection.

`DialogMeta` is a sealed, `@ApiStatus.NonExtendable` interface (only `DialogMetaData` implements it) — configure it
through the methods shown here rather than trying to implement it.

## Tracking open dialogs

**`DialogRegistry`** (`DialogRegistry.of()` → the default implementation) is optional bookkeeping for dialogs you
want to look up later by key rather than passing the `DialogTemplate` reference around everywhere it's needed:

```java
DialogRegistry registry = DialogRegistry.of();
registry.add(dialog);
registry.get(MY_KEY).open(player); // returns null via get() if not registered — check before calling .open()
```

Use it for dialogs that get opened from multiple, disconnected places in the codebase (e.g. a settings dialog
reachable from several menus); for a one-off dialog only opened from where it's built, just keep the
`DialogTemplate` reference directly and skip the registry.

## Reacting to dialog opens

**`PlayerOpenDialogEvent`** (`PlayerEvent`, `CancellableEvent`) fires when a dialog opens for a player — carries the
player and the dialog's `Key`. Cancel it to block a dialog from opening under some condition (e.g. player already
has one open, or lacks permission) rather than adding that check inside every place a dialog might be triggered.

## Further reference

`references/api-classes.md` has the full class inventory (every class in every package) and points to real consumer
projects (`ManisGame`, `Tamias`, `Cygnus`) with several `*Dialogs` utility classes worth reading beyond the single
example above.
