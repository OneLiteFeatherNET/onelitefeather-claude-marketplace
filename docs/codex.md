# Using this marketplace with Codex

Every plugin in this repo ships a `.codex-plugin/plugin.json` alongside its
`.claude-plugin/plugin.json` — same `skills/` directory, both manifests
point at it. This doc explains how to actually get those skills into a
Codex session, since Codex doesn't (yet) recognize this repo as a
registered marketplace the way `/plugin marketplace add` does in Claude
Code.

## What you get, and what you don't

| Plugin | Skills that port as-is | What's Claude Code-only (not ported) |
|---|---|---|
| `framework` | `vault-knowledge-graph` | The 9-plugin `claude-plugins-official` dependency bundle, `/framework:setup`, `/framework:doctor`, the Outline MCP server declaration |
| `framework-code-navigation` | `code-navigation` | The Serena MCP server declaration |
| `minestom-knowledge` | `cyano`, `gradle`, `boms`, `guira`, `aves`, `xerus`, `pica`, `coris` | Nothing — this plugin has no MCP servers or commands, it's pure skill content |

The skill files themselves don't need edits to work on Codex — they're
written to describe actions ("search the Vault", "check if Serena
responds"), not Claude-Code-specific tool names. What doesn't carry over
is everything that rides Claude Code's *plugin installation* mechanics
(dependency resolution, slash commands, the `mcpServers` field in
`.claude-plugin/plugin.json`).

## Install

Codex has no native concept of "add this GitHub repo as a marketplace" the
way Claude Code does (as of when this doc was written) — there are two
practical ways to get skills from here into Codex instead:

### Option 1 — copy/symlink individual skill directories

Codex looks for skills under `~/.codex/skills/`. Each skill here is
self-contained (a folder with `SKILL.md` plus an optional `references/`
subfolder), so you can grab just the ones you want:

```bash
git clone https://github.com/OneLiteFeatherNET/onelitefeather-claude-marketplace.git /tmp/olf-marketplace

# example: pull in the whole minestom-knowledge skill set
cp -r /tmp/olf-marketplace/plugins/minestom-knowledge/skills/* ~/.codex/skills/

# or just one skill
cp -r /tmp/olf-marketplace/plugins/minestom-knowledge/skills/cyano ~/.codex/skills/cyano
```

A symlink instead of a copy keeps you on the latest version as this repo
updates:

```bash
ln -s /path/to/onelitefeather-claude-marketplace/plugins/minestom-knowledge/skills/cyano ~/.codex/skills/cyano
```

### Option 2 — Codex's `/plugins` browser, per-plugin

Point Codex's plugin browser at an individual plugin directory (not the
marketplace root — Codex expects one `.codex-plugin/plugin.json` per
install target, and this repo has three, one per subdirectory under
`plugins/`). Check Codex's current docs for the exact "install from a
local path / git subdirectory" syntax, since this is the part most likely
to have changed since this doc was written.

## Configuring the MCP servers separately

If you want the `vault-knowledge-graph` or `code-navigation` skills to
actually *do* something (not just exist as instructions Codex reads but
can't act on), you need the underlying MCP server configured on Codex
too:

- **Outline** (`vault-knowledge-graph`): register Outline's official MCP
  server at `https://outline.onelitefeather.dev/mcp` through however Codex
  configures MCP servers (`.mcp.json` at your project root is the
  documented location — see Codex's plugin docs for the exact schema it
  expects there).
- **Serena** (`code-navigation`): same idea, using the `uvx`-based command
  in `plugins/framework-code-navigation/.claude-plugin/plugin.json` as the
  reference for the exact invocation (pinned to Serena `v1.6.0`).

## Verifying it worked

Ask Codex directly: *"What skills do you have available?"* or *"List your
skills."* If a skill you copied in doesn't show up, double-check it landed
in the directory Codex actually scans (confirm with Codex's own docs —
this repo doesn't control that path).

## This is new — expect rough edges

This integration was added without a live Codex CLI available to test
against end-to-end. The manifest shape (`.codex-plugin/plugin.json` with
`"skills": "./skills/"`, `"hooks": {}`) matches Codex's documented format
and a known working reference (the `superpowers` plugin ships the same
shape), but the exact install UX above wasn't run through a real Codex
session. If something in this doc is wrong or outdated, please open an
issue or PR against this repo.
