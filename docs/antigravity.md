# Using this marketplace with Antigravity (`agy`)

Every plugin in this repo ships an `.antigravity-plugin/plugin.json`
alongside its `.claude-plugin/plugin.json` — same `skills/` directory,
both manifests point at it.

**Confidence level: unverified.** This was written and the manifests were
built without an `agy` CLI available to test against. Everything below is
a best-effort description of how it *should* work, based on public
documentation and how the `superpowers` plugin (a much larger,
cross-harness-tested project) handles the same situation — not something
run end-to-end here. Treat it as a starting point, not a guarantee, and
please report back (issue or PR) once someone with `agy` installed has
actually tried it.

## What you get, and what you don't

| Plugin | Skills that should port | What's Claude Code-only (not ported) |
|---|---|---|
| `framework` | `vault-knowledge-graph` | The 9-plugin `claude-plugins-official` dependency bundle, `/framework:setup`, `/framework:doctor`, the Outline MCP server declaration |
| `framework-code-navigation` | `code-navigation` | The Serena MCP server declaration |
| `minestom-knowledge` | `cyano`, `gradle`, `boms`, `guira`, `aves`, `xerus`, `pica`, `coris` | Nothing — this plugin has no MCP servers or commands, it's pure skill content |

The skill files describe actions, not Claude-Code-specific tool names, so
in principle they don't need edits to run under Antigravity. What
definitely doesn't carry over is Claude Code's plugin-installation
mechanics: dependency resolution, slash commands, and the `mcpServers`
field in `.claude-plugin/plugin.json`.

## Install

```bash
agy plugin install https://github.com/OneLiteFeatherNET/onelitefeather-claude-marketplace.git
```

Whether `agy` treats this whole repo as one installable unit or expects a
single-plugin repo (in which case you'd point it at a plugin subdirectory,
e.g. `.../onelitefeather-claude-marketplace.git#plugins/minestom-knowledge`
or a local checkout path) is exactly the part that needs live
verification — try the whole-repo URL first, and if `agy` doesn't
recognize it, fall back to pointing it at one `plugins/<name>/` directory
at a time.

If `agy plugin install` doesn't work against a remote URL at all in your
version, clone locally first and install from the local path:

```bash
git clone https://github.com/OneLiteFeatherNET/onelitefeather-claude-marketplace.git
agy plugin install ./onelitefeather-claude-marketplace/plugins/minestom-knowledge
```

## Configuring the MCP servers separately

Same as for Codex (see `docs/codex.md`) — if `vault-knowledge-graph` or
`code-navigation` should actually act, not just narrate instructions,
configure the underlying MCP server on Antigravity separately:

- **Outline**: `https://outline.onelitefeather.dev/mcp`
- **Serena**: the `uvx`-based command in
  `plugins/framework-code-navigation/.claude-plugin/plugin.json`, pinned
  to `v1.6.0`

## Verifying it worked

Ask the model directly: *"What skills do you have available?"* If nothing
shows up, the install didn't register the `skills/` directory the way
this manifest assumes — check `agy plugin validate` or the equivalent
diagnostic command for what it actually loaded.

## If this doesn't work as written

Antigravity's plugin/install surface is new enough that its exact
conventions may have moved since this was written. If `agy plugin
install` behaves differently than described here, the fix is almost
certainly in this doc or in `.antigravity-plugin/plugin.json` — not in
the skill content itself (`plugins/*/skills/*/SKILL.md`), which is
intentionally harness-agnostic. Please open an issue or PR with what you
found.
