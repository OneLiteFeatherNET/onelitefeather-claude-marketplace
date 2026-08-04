# Using this marketplace with Antigravity

Every plugin in this repo except `agent-orchestrator` ships an
`.antigravity-plugin/plugin.json` alongside its `.claude-plugin/plugin.json`
— same `skills/` directory, both manifests point at it. `agent-orchestrator`
is Claude Code only (it relies on the `Agent` tool's model overrides,
worktree isolation, and task tracking) and deliberately ships no
`.antigravity-plugin/plugin.json`. That manifest targets a plugin-installer
mechanism (`agy plugin install`) that hasn't been verified live in this
repo. Antigravity's own published docs describe a second, simpler path
that needs no installer at all: skills are loaded straight from a
directory Antigravity scans on disk. **That's the recommended option
below** — it's confirmed against Antigravity's current documentation,
not just best-effort.

## What you get, and what you don't

| Plugin | Skills that port | What's Claude Code-only (not ported) |
|---|---|---|
| `framework` | `vault-knowledge-graph` | The 9-plugin `claude-plugins-official` dependency bundle, `/framework:setup`, `/framework:doctor`, the Outline MCP server declaration |
| `framework-code-navigation` | `code-navigation` | The Serena MCP server declaration |
| `minestom-knowledge` | `cyano`, `gradle`, `boms`, `guira`, `aves`, `xerus`, `pica`, `coris` | Nothing — this plugin has no MCP servers or commands, it's pure skill content |
| `release-engineering` | `release-please`, `renovate`, `workflows` | Nothing — this plugin has no MCP servers or commands, it's pure skill content |
| `requirement-engineering` | `requirement-engineering` | Nothing — this plugin has no MCP servers or commands, it's pure skill content |
| `micronaut-standards` | `dependency-management`, `observability`, `service-layer`, `entity-design`, `configuration`, `dto`, `response-modeling`, `openapi`, `routing`, `exception-handling`, `security`, `liquibase`, `testcontainers`, `logging` | Nothing — this plugin has no MCP servers or commands, it's pure skill content |
| `git-hygiene` | `git-hygiene` | The `/git-hygiene:setup` command and the `PreToolUse` guard hook — `hooks/` and `commands/` do not carry over |

The skill files describe actions, not Claude-Code-specific tool names, so
they don't need edits to run under Antigravity. What definitely doesn't
carry over is Claude Code's plugin-installation mechanics: dependency
resolution, slash commands, and the `mcpServers` field in
`.claude-plugin/plugin.json`.

## Install (recommended) — drop the skill folder in place

Antigravity reads skills directly from a folder, no install command
needed: workspace-scoped skills live at
`<workspace-root>/.agents/skills/<skill-name>/`, global ones (available
in every workspace) at `~/.gemini/antigravity/skills/<skill-name>/`. Pick
whichever scope fits, then symlink so you stay on the latest version as
this repo updates:

```bash
git clone https://github.com/OneLiteFeatherNET/onelitefeather-claude-marketplace.git /tmp/olf-marketplace

# global — available in every workspace
ln -s /tmp/olf-marketplace/plugins/framework/skills/vault-knowledge-graph ~/.gemini/antigravity/skills/vault-knowledge-graph

# or workspace-scoped — only this project
ln -s /tmp/olf-marketplace/plugins/framework/skills/vault-knowledge-graph <workspace-root>/.agents/skills/vault-knowledge-graph
```

Same pattern for any other skill in this repo (`code-navigation`, the
`minestom-knowledge` skills, etc.) — just swap the source path.

## Install (alternative, unverified) — `agy plugin install`

```bash
agy plugin install https://github.com/OneLiteFeatherNET/onelitefeather-claude-marketplace.git
```

This route uses the `.antigravity-plugin/plugin.json` manifests instead
and was **not** tested against a live `agy` CLI, so treat it as a
starting point, not a guarantee — whether `agy` treats this whole repo as
one installable unit or expects a single-plugin repo (in which case
you'd point it at a plugin subdirectory, e.g.
`.../onelitefeather-claude-marketplace.git#plugins/minestom-knowledge`,
or a local checkout path) is exactly what needs live verification. If it
doesn't work, use the recommended option above instead — it doesn't
depend on `agy` at all. Please report back (issue or PR) once someone
with `agy` installed has actually tried this path.

## Configuring the MCP servers separately

Skills alone only give Antigravity instructions to read — for
`vault-knowledge-graph` or `code-navigation` to actually *act*, register
the underlying MCP server too. Antigravity does have a guided add flow —
an "Add MCP" button backed by the **MCP Store**, a searchable list of
known servers you install with one click (in Antigravity IDE/2.0), or an
"Interactive MCP Manager" via the `/mcp` command (Antigravity CLI). Both
only help for servers that are *listed* there, though — our self-hosted
Outline server isn't, so for it (and for Serena) you still end up at
manual JSON: open the Agent panel's "..." menu → MCP Servers → Manage MCP
Servers → View raw config, or edit the file directly. That file is
`~/.gemini/config/mcp_config.json` for a global setup, or
`.agents/mcp_config.json` at a workspace root to scope it to one project
— either way, a single `mcpServers` object. Remote HTTP servers use
`serverUrl` rather than `url`:

- **Outline** (`vault-knowledge-graph`):

  ```json
  {
    "mcpServers": {
      "outline": {
        "serverUrl": "https://outline.onelitefeather.dev/mcp"
      }
    }
  }
  ```

- **Serena** (`code-navigation`) runs locally via `uvx`, so it needs
  `command` + `args` instead of `serverUrl` — same invocation as
  `plugins/framework-code-navigation/.claude-plugin/plugin.json` (pinned
  to Serena `v1.6.0`), but swap `--context claude-code` for Serena's
  `ide` context (Antigravity is an IDE-style client, so this strips tools
  it already provides natively) and replace `${CLAUDE_PROJECT_DIR}` —
  Antigravity has no equivalent shorthand — with a literal absolute path:

  ```json
  {
    "mcpServers": {
      "serena": {
        "command": "uvx",
        "args": ["--from", "git+https://github.com/oraios/serena@v1.6.0", "serena", "start-mcp-server", "--context", "ide", "--project", "/absolute/path/to/your/project"]
      }
    }
  }
  ```

  Merge this into the same `mcpServers` object as Outline rather than
  overwriting the file.

## Verifying it worked

Ask the model directly: *"What skills do you have available?"* If
nothing shows up after the symlink approach, double-check the symlink
target and that you used the right scope (workspace vs. global) for how
you're running Antigravity. If you went the `agy plugin install` route
instead, check `agy plugin validate` or the equivalent diagnostic command
for what it actually loaded.

## If something here is wrong

The symlink-based skill loading and the MCP config format above are
sourced from Antigravity's own current docs, not guessed — but "current"
moves fast in this space, and the `agy plugin install` / manifest path
was never tested live at all. If either doesn't match what you see,
the fix is almost certainly in this doc or in `.antigravity-plugin/plugin.json`
— not in the skill content itself (`plugins/*/skills/*/SKILL.md`), which
is intentionally harness-agnostic. Please open an issue or PR with what
you found.
