# framework

The team framework: builds and maintains a **knowledge graph** in the
Outline collection **"Vault"** — research material, project knowledge,
concepts, sources, and people as linked documents, with targeted context
loading instead of dumping whole documents into context — and brings
**superpowers** along as a shared team workflow.

> `context-layer`, `benchmark-stack`, and `workflow` were removed from this
> marketplace and will be rebuilt from scratch as needed. Code navigation
> has already been rebuilt — as its own optional plugin,
> `framework-code-navigation` (see below), not as part of `framework`
> itself, since not every project is JVM-based.

## What's inside

- **Dependencies from `claude-plugins-official`** — installed automatically
  alongside `framework`:
  - `superpowers` — shared team workflows like brainstorming before
    implementation, systematic debugging, TDD, and structured code review.
  - `skill-creator` — build and iterate on new skills (this is how
    `vault-knowledge-graph` and `framework-code-navigation` were built).
  - `claude-md-management` — audit and improve `CLAUDE.md` files, capture
    session learnings.
  - `code-review` — automated multi-agent PR review.
  - `code-simplifier` — simplifies recently changed code for clarity and
    maintainability without changing behavior.
  - `security-guidance` — pattern-based and LLM-reviewed security checks on
    Claude-generated code.
  - `frontend-design` — production-grade frontend interfaces with high
    design quality.
  - `context7` — up-to-date, version-specific library/framework docs
    lookup.
  - `ralph-loop` — self-referential iterative development loops.
- **MCP server `outline`** — Anthropic's official Outline MCP server
  (built into every Outline workspace since February 2026), connected via
  HTTP/OAuth to `https://outline.onelitefeather.dev/mcp`.
- **Skill `vault-knowledge-graph`** — tells the agent how to create
  documents in the vault as graph nodes (metadata table, categories,
  backlinks) and later load them back in a targeted way (search → load →
  follow one hop → condense).
- **Command `/framework:setup`** — full onboarding check: verifies the nine
  bundled dependency plugins are installed and enabled, checks the Outline
  MCP connection, and creates the vault collection and its five category
  documents if they're missing. Idempotent, safe to re-run any time (e.g.
  after onboarding a new team member).
- **Command `/framework:doctor`** — read-only version of the same checks.
  Reports what's working and what needs attention without changing
  anything; safe to run anytime just to confirm the setup is still intact.

## Install

### Claude Code

```bash
/plugin install framework@onelitefeather-claude-marketplace
```

Installs all nine dependency plugins from `claude-plugins-official`
automatically (this requires `claude-plugins-official` to already be
registered as a marketplace — true for most setups; if not, the installer
reports it and suggests `/plugin marketplace add`).

The first time you touch Outline, a browser OAuth login opens — every team
member needs their own Outline account with access to the "Vault"
collection. Afterwards, run `/framework:setup` once to verify everything and
create the collection and its five categories.

### Codex / Antigravity (`agy`)

This plugin also ships `.codex-plugin/plugin.json` and
`.antigravity-plugin/plugin.json`, both pointing at the same `skills/`
directory — so the `vault-knowledge-graph` skill's content ports as-is (it
only names actions, not Claude-Code-specific tool names). **What does not
port automatically:**

- The nine `claude-plugins-official` dependency bundle (`superpowers`,
  `skill-creator`, etc.) — that's Claude Code marketplace-specific
  dependency resolution.
- The `/framework:setup` and `/framework:doctor` commands.
- The Outline MCP server declaration — configure an MCP connection to
  `https://outline.onelitefeather.dev/mcp` separately on whichever platform
  you're using; the skill itself checks for the Outline tools at runtime
  rather than assuming they exist.

The Codex manifest is per Codex's documented format (verified). The
Antigravity one is a **best-effort approximation, not verified live** in
this session (no `agy` CLI available to test against) — confirm with
`agy plugin install` before relying on it.

## Self-hosted Outline instance

The URL in `.claude-plugin/plugin.json` is deliberately hardcoded to
`outline.onelitefeather.dev` — this plugin isn't a generic Outline tool,
it's our team's knowledge-graph setup. If the instance ever migrates, only
that URL needs to change.

## Tested

Iteratively verified against the real Vault collection with `skill-creator`:
category structure, metadata table format (survives Outline's markdown
storage reliably), German special characters, LaTeX formulas, and the
capture/recall workflow. Details in the commit history.
