# onelitefeather-claude-marketplace

OneLiteFeather's Claude Code marketplace — the team's **framework** plugin.

## The plugin

| Plugin | Purpose |
|--------|---------|
| **framework** | Team framework: knowledge graph in our Outline "Vault" collection (research material, project knowledge, targeted context recall instead of dumping whole docs), plus `superpowers` (from `claude-plugins-official`) for shared team workflows. |

`context-layer`, `benchmark-stack`, and `workflow` were removed from this
marketplace. They'll be rebuilt from scratch later, directly as part of
`framework` instead of as separate plugins.

## Install

```bash
# Register the marketplace (from this git repo)
/plugin marketplace add OneLiteFeatherNET/onelitefeather-claude-marketplace

# Install
/plugin install framework@onelitefeather-claude-marketplace
```

Run `/framework:setup` once afterwards to create the "Vault" collection and
its five categories.

## Prerequisites

- Outline account with access to the "Vault" collection (OAuth on first use)

Per-plugin details in `plugins/<name>/README.md`.
