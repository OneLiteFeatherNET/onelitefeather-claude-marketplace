# onelitefeather-claude-marketplace

OneLiteFeather's Claude Code marketplace — the team's developer framework.

## The plugins

| Plugin | Purpose |
|--------|---------|
| **framework** | Team framework: knowledge graph in our Outline "Vault" collection (research material, project knowledge, targeted context recall instead of dumping whole docs), plus `superpowers` (from `claude-plugins-official`) for shared team workflows. |
| **framework-code-navigation** | Optional companion to `framework`: Serena (LSP symbol search) for JVM/Java-Kotlin projects, so the agent navigates code on purpose instead of spamming grep/find/read. Install only on projects where it fits. |

`context-layer`, `benchmark-stack`, and `workflow` were removed from this
marketplace. Code navigation has already been rebuilt as
`framework-code-navigation`; the rest will be rebuilt from scratch later,
directly as part of this framework instead of as separate plugins.

## Install

```bash
# Register the marketplace (from this git repo)
/plugin marketplace add OneLiteFeatherNET/onelitefeather-claude-marketplace

# Core framework: Outline vault + superpowers
/plugin install framework@onelitefeather-claude-marketplace

# Optional, only on JVM/Java-Kotlin projects
/plugin install framework-code-navigation@onelitefeather-claude-marketplace
```

Run `/framework:setup` once afterwards to create the "Vault" collection and
its five categories.

## Prerequisites

- Outline account with access to the "Vault" collection (OAuth on first use)
- `uv` (for `uvx`) — only if you install `framework-code-navigation`

Per-plugin details in `plugins/<name>/README.md`.
