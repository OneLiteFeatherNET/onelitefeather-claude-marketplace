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
| **framework** | Team onboarding bundle: pulls in context-layer, benchmark-stack, workflow and `superpowers` (from `claude-plugins-official`) in one install, plus its own knowledge graph in our Outline "Vault" collection (research material, project knowledge, targeted context recall). |

## Install

```bash
# Register the marketplace (from this git repo)
/plugin marketplace add OneLiteFeatherNET/onelitefeather-claude-marketplace

# One-shot onboarding: installs context-layer, benchmark-stack, workflow and superpowers too
/plugin install framework@onelitefeather-claude-marketplace

# Or install the individual plugins yourself
/plugin install context-layer@onelitefeather-claude-marketplace
/plugin install benchmark-stack@onelitefeather-claude-marketplace
/plugin install workflow@onelitefeather-claude-marketplace   # pulls the other two as dependencies
```

## Recommended order

1. **framework** → the fastest path for a new team member: one install brings in every plugin below plus superpowers and the Outline vault. Run `/framework:setup` once afterwards to create the "Vault" collection and its five categories.
2. Installing individually instead: **context-layer** first → Serena + routing active, calls drop immediately.
3. **benchmark-stack** → run one A/B pass and prove the effect for a presentation.
4. **workflow** → for continuous use: keeps routing on in daily work and shows the trend.

## Prerequisites

- `uv` (Serena via `uvx`) — https://docs.astral.sh/uv/
- Docker + Compose (benchmark-stack dashboard only)
- Python 3 + `matplotlib` (benchmark-stack report only)
- Outline account with access to the "Vault" collection (framework only, OAuth on first use)

Per-plugin details in `plugins/<name>/README.md`.
