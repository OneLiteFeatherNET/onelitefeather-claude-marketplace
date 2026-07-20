# onelitefeather-claude-marketplace

OneLiteFeather's Claude Code marketplace — the team's developer framework.

## The plugins

| Plugin | Purpose |
|--------|---------|
| **framework** | Team framework: knowledge graph in our Outline "Vault" collection (research material, project knowledge, targeted context recall instead of dumping whole docs), plus `superpowers` (from `claude-plugins-official`) for shared team workflows. |
| **framework-code-navigation** | Optional companion to `framework`: Serena (LSP symbol search) for JVM/Java-Kotlin projects, so the agent navigates code on purpose instead of spamming grep/find/read. Install only on projects where it fits. |
| **minestom-knowledge** | Accurate knowledge of our internal Minestom libraries (Cyano, Aves, Xerus, Guira, Pica, Coris) and tooling (Gradle conventions, BOM hierarchy) — too internal/new to be in general training data. No MCP servers, pure skill content. |

`context-layer`, `benchmark-stack`, and `workflow` were removed from this
marketplace. Code navigation has already been rebuilt as
`framework-code-navigation`; the rest will be rebuilt from scratch later,
directly as part of this framework instead of as separate plugins.

## Install

### Claude Code

```bash
# Register the marketplace (from this git repo)
/plugin marketplace add OneLiteFeatherNET/onelitefeather-claude-marketplace

# Core framework: Outline vault + superpowers
/plugin install framework@onelitefeather-claude-marketplace

# Optional, only on JVM/Java-Kotlin projects
/plugin install framework-code-navigation@onelitefeather-claude-marketplace

# Minestom library knowledge, no MCP servers needed
/plugin install minestom-knowledge@onelitefeather-claude-marketplace
```

Run `/framework:setup` once afterwards to create the "Vault" collection and
its five categories.

### Codex / Antigravity (`agy`)

Every plugin also ships a `.codex-plugin/plugin.json` and an
`.antigravity-plugin/plugin.json` pointing at the same `skills/` directory
Claude Code uses — skill content is written to name actions, not
Claude-Code-specific tool names, so it carries over as-is. What does **not**
carry over: the `claude-plugins-official` dependency bundle, the
`/framework:*` commands, and the two plugins' MCP server declarations
(Outline, Serena) — configure those separately per platform. The Codex
manifest shape is per Codex's documented plugin format (verified); the
Antigravity one is a **best-effort approximation, not verified live** (no
`agy` CLI available in the session that authored it) — confirm with
`agy plugin install` before relying on it, and see each plugin's own
README for specifics.

## Prerequisites

- Outline account with access to the "Vault" collection (OAuth on first use)
- `uv` (for `uvx`) — only if you install `framework-code-navigation`

Per-plugin details in `plugins/<name>/README.md`.
