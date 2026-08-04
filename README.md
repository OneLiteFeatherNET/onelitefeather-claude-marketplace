# onelitefeather-claude-marketplace

OneLiteFeather's Claude Code marketplace — the team's developer framework.

## The plugins

| Plugin | Purpose |
|--------|---------|
| **framework** | Team framework: knowledge graph in our Outline "Vault" collection (research material, project knowledge, targeted context recall instead of dumping whole docs), plus `superpowers` (from `claude-plugins-official`) for shared team workflows and `git-hygiene` for commit/PR hygiene. |
| **framework-code-navigation** | Optional companion to `framework`: Serena (LSP symbol search) for JVM/Java-Kotlin projects, so the agent navigates code on purpose instead of spamming grep/find/read. Install only on projects where it fits. |
| **minestom-knowledge** | Accurate knowledge of our internal Minestom libraries (Cyano, Aves, Xerus, Guira, Pica, Coris) and tooling (Gradle conventions, BOM hierarchy) — too internal/new to be in general training data. No MCP servers, pure skill content. |
| **release-engineering** | OneLiteFeather's CI/CD standard: Release Please, the central Renovate preset plus general Renovate config help, and the reusable GitHub Actions workflows (build, publish, Docker, Gradle specifics). No MCP servers, pure skill content. |
| **agent-orchestrator** | Decomposes complex tasks into independent subtasks and delegates each to the cheapest viable model tier (haiku, sonnet, opus, fable — fable gated behind explicit confirmation), escalating only when needed. Claude Code only — uses the `Agent` tool's model overrides, worktree isolation, and task tracking. |
| **requirement-engineering** | OneLiteFeather's Requirement-Engineering standard for Outline project docs: User Stories (staged by Ausbaustufen) + EARS acceptance-criteria syntax + MoSCoW prioritization, for game concepts and technical projects alike. Creates new requirements docs and restructures superficial prose-only concept docs. No MCP servers of its own — pairs with `framework`'s Outline connection. |
| **git-hygiene** | Keeps commit messages, branch names, PR titles and bodies, issue comments and release notes free of AI tool branding, session URLs, machine typography and machine phrasing. Ships the attribution settings, a PreToolUse safety net, and an optional commit-msg hook. No MCP servers, pure skill content plus a setup command. |

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

# CI/CD standard: Release Please, Renovate, reusable workflows
/plugin install release-engineering@onelitefeather-claude-marketplace

# Complex-task delegation: haiku -> sonnet -> opus -> fable escalation
/plugin install agent-orchestrator@onelitefeather-claude-marketplace

# Requirement Engineering standard: User Stories + EARS + MoSCoW for Outline docs
/plugin install requirement-engineering@onelitefeather-claude-marketplace

# Clean commits and PRs: no tool branding, no session URLs, ASCII typography
/plugin install git-hygiene@onelitefeather-claude-marketplace
```

`git-hygiene` is now bundled as a `framework` dependency, so installing
`framework` fresh installs and enables it automatically — the explicit
`/plugin install git-hygiene@...` step above is only needed to install it
standalone. If you *already* have `framework` installed, you will **not**
get `git-hygiene` automatically: auto-update is off by default for
non-Anthropic marketplaces. Either enable auto-update for this marketplace
in `/plugin`, or run `claude plugin update framework` followed by
`/reload-plugins`.

Run `/framework:setup` once afterwards to create the "Vault" collection and
its five categories.

### Codex / Antigravity (`agy`)

Every plugin except `agent-orchestrator` also ships a
`.codex-plugin/plugin.json` and an `.antigravity-plugin/plugin.json`
pointing at the same `skills/` directory Claude Code uses — skill content
is written to name actions, not Claude-Code-specific tool names, so it
carries over as-is. `agent-orchestrator` is Claude Code only (it relies on
the `Agent` tool's model overrides, worktree isolation, and task
tracking), so it deliberately ships neither manifest. What does **not**
carry over for the plugins that do port: the `claude-plugins-official`
dependency bundle, the `/framework:*` commands, and the two plugins' MCP
server declarations (Outline, Serena) — configure those separately per
platform.

Full step-by-step install instructions: [`docs/codex.md`](docs/codex.md)
and [`docs/antigravity.md`](docs/antigravity.md). Short version: for Codex,
either drop skills into `~/.codex/skills/` or install via the
`.codex-plugin/plugin.json` manifest (matches Codex's documented plugin
format, verified against a known working reference). For Antigravity, the
recommended path is the same idea — symlink skills straight into
`~/.gemini/antigravity/skills/` or `<workspace-root>/.agents/skills/`,
confirmed against Antigravity's own docs; `agy plugin install` via the
`.antigravity-plugin/plugin.json` manifest is offered as an alternative
but was **not verified live** (no `agy` CLI available in the session that
authored it) — please report back what you find if you try it.

None of the three tools walk you through *this* framework's setup the way
`/framework:setup` does (it's a custom command, specific to Claude Code) —
but their generic MCP-server setup is guided to different degrees: Codex's
`codex mcp add` interactively prompts for name/transport/URL; Antigravity
has a click-to-install MCP Store, but only for servers it already lists —
our self-hosted Outline server isn't, so that one still needs manual JSON
either way. Whichever path gets the MCP connection working, no further
setup step is needed after that: the `vault-knowledge-graph` skill creates
the "Vault" collection and its categories itself on first use.

## Prerequisites

- Outline account with access to the "Vault" collection (OAuth on first use)
- `uv` (for `uvx`) — only if you install `framework-code-navigation`

Per-plugin details in `plugins/<name>/README.md`.
