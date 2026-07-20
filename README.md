# onelitefeather-claude-marketplace

OneLiteFeather's Claude Code marketplace — plugins that work together to
**cut API calls and tokens** and make the effect **measurable**, plus a
team knowledge base layer.

## The plugins

| Plugin | Purpose |
|--------|---------|
| **context-layer** | Retrieval layer between docs & code: Serena (LSP symbol search) + routing skills, so the agent navigates on purpose instead of spamming grep/find/read. |
| **benchmark-stack** | Small OpenTelemetry stack (Docker Compose: Collector + Prometheus + Grafana) + a report generator for the before/after comparison (tokens, calls, cost). |
| **workflow** | Day-to-day control: enforces the layer (SessionStart/grep hooks + routing skill) and produces trend reports over time. Depends on the other two. |
| **framework** | Knowledge graph in our Outline "Vault" collection: research material, project knowledge, targeted context recall instead of dumping whole docs. Ships `superpowers` (from `claude-plugins-official`) as a dependency. |

## Install

```bash
# Register the marketplace (from this git repo)
/plugin marketplace add OneLiteFeatherNET/onelitefeather-claude-marketplace

# Install the plugins
/plugin install context-layer@onelitefeather-claude-marketplace
/plugin install benchmark-stack@onelitefeather-claude-marketplace
/plugin install workflow@onelitefeather-claude-marketplace   # pulls the other two as dependencies
/plugin install framework@onelitefeather-claude-marketplace # independent, needs Outline access
```

## Recommended order

1. Install **context-layer** → Serena + routing active, calls drop immediately.
2. **benchmark-stack** → run one A/B pass and prove the effect for a presentation.
3. **workflow** → for continuous use: keeps routing on in daily work and shows the trend.
4. **framework** → independent of the other three; install whenever you want Claude to read from and write to our Outline knowledge base. Run `/framework:setup` once afterwards to create the "Vault" collection and its five categories.

## Prerequisites

- `uv` (Serena via `uvx`) — https://docs.astral.sh/uv/
- Docker + Compose (benchmark-stack dashboard only)
- Python 3 + `matplotlib` (benchmark-stack report only)
- Outline account with access to the "Vault" collection (framework only, OAuth on first use)

Per-plugin details in `plugins/<name>/README.md`.
