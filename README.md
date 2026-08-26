# onelitefeather-claude-marketplace

OneLiteFeather's Claude Code marketplace — the team's developer framework.

## The plugins

| Plugin | Purpose |
|--------|---------|
| **framework** | Team framework: knowledge graph in our Outline "Vault" collection (research material, project knowledge, targeted context recall instead of dumping whole docs), plus `superpowers` (from `claude-plugins-official`) for shared team workflows, `git-hygiene` for commit/PR hygiene, `diataxis-docs` for documentation structure, and `problem-framing` plus `decision-sparring` for how work gets scoped and decided. |
| **framework-code-navigation** | Optional companion to `framework`: Serena (LSP symbol search) for JVM/Java-Kotlin projects, so the agent navigates code on purpose instead of spamming grep/find/read. Install only on projects where it fits. |
| **minestom-knowledge** | Accurate knowledge of our internal Minestom libraries (Cyano, Aves, Xerus, Guira, Pica, Coris) and tooling (Gradle conventions, BOM hierarchy) — too internal/new to be in general training data. No MCP servers, pure skill content. |
| **release-engineering** | OneLiteFeather's CI/CD standard: Release Please, the central Renovate preset plus general Renovate config help, and the reusable GitHub Actions workflows (build, publish, Docker, Gradle specifics). No MCP servers, pure skill content. |
| **agent-orchestrator** | Decomposes complex tasks into independent subtasks and delegates each to the cheapest viable model tier (haiku, sonnet, opus, fable — fable gated behind explicit confirmation), escalating only when needed. Claude Code only — uses the `Agent` tool's model overrides, worktree isolation, and task tracking. |
| **requirement-engineering** | Requirement-engineering standard for any project: user stories on a story-map backbone (staged by release slices) + EARS acceptance criteria + MoSCoW per stage + an ISO-25010-based NFR checklist. Creates new docs, restructures prose-only concepts, reconstructs undocumented running systems, and turns a released stage into issues. Covers internal wiki projects, public open-source repos and third-party projects; English is canonical, with a localization mapping for other languages. No MCP servers of its own — pairs with `framework`'s Outline connection when writing to Outline. |
| **micronaut-standards** | OneLiteFeather's standard for Micronaut REST APIs: dependency management, observability, service layer, entity design, configuration, DTO/response modeling, OpenAPI docs, HTTP routing, exception handling, security baseline, Liquibase migrations, Testcontainers, and logging. No MCP servers, pure skill content. |
| **git-hygiene** | Keeps commit messages, branch names, PR titles and bodies, issue comments and release notes free of AI tool branding, session URLs, machine typography and machine phrasing. Ships the attribution settings, a PreToolUse safety net, and an optional commit-msg hook. No MCP servers, pure skill content plus a setup command. |
| **diataxis-docs** | OneLiteFeather's documentation standard: Diátaxis (tutorial, how-to, reference, explanation) for planning a docs set, routing content into the right quadrant, writing each page in the voice its quadrant demands, auditing an overloaded README or wiki, and generating the reference quadrant from source with a CI drift gate. Covers repository Markdown, GitHub wiki, Outline and GitBook as publishing targets. No MCP servers, pure skill content. |
| **problem-framing** | Turns a vague, shifting or solution-shaped request into a short written problem brief before the expensive work starts: goal, scope and non-goals, constraints, testable acceptance criteria, an agreed glossary and marked open questions. Detects the XY problem, target drift, and circumlocution — a thing described by its function because the term is missing — and resolves it by elicitation instead of silently paraphrasing it into confident vocabulary. No MCP servers, pure skill content. |
| **decision-sparring** | Stress-tests a decision that has already been made and delivers a verdict, not just objections: framing, assumptions, alternatives, evidence, motives, consequences, reversibility, then a deciding factor and a stated tipping condition. Scales effort by the one-way/two-way door test, so a cheap reversible call gets three questions and a reply, not a questionnaire. No MCP servers, pure skill content. |

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

# Requirement Engineering: story-mapped user stories + EARS + MoSCoW + NFR checklist, any project
/plugin install requirement-engineering@onelitefeather-claude-marketplace

# Micronaut REST API standard: dependency management, architecture, DTOs, OpenAPI, security, migrations
/plugin install micronaut-standards@onelitefeather-claude-marketplace

# Clean commits and PRs: no tool branding, no session URLs, ASCII typography
/plugin install git-hygiene@onelitefeather-claude-marketplace

# Documentation structure: Diátaxis quadrants, generated reference, docs audits
/plugin install diataxis-docs@onelitefeather-claude-marketplace

# Scoping and deciding: problem briefs, and verdicts on decisions already made
/plugin install problem-framing@onelitefeather-claude-marketplace
/plugin install decision-sparring@onelitefeather-claude-marketplace
```

`git-hygiene`, `diataxis-docs`, `problem-framing` and `decision-sparring`
are bundled as `framework` dependencies, so installing `framework` fresh
installs and enables them automatically — the explicit
`/plugin install ...` steps above are only needed to install them
standalone. If you *already* have `framework` installed, you will
**not** get them automatically: auto-update is off by default for
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

## Releases

Versions are per plugin, not per repository. Release Please watches `main`,
attributes each commit to a plugin by the files it touches, and opens a
release PR that bumps only the plugins that actually changed. Merging that
PR tags them (`diataxis-docs-v0.2.0`) and cuts a GitHub release per tag.

That means two things for a contributor:

- **Write [Conventional Commits](https://www.conventionalcommits.org/).**
  `feat:` bumps the minor version, `fix:` the patch, `feat!:` or a
  `BREAKING CHANGE:` footer the major. `chore:`, `docs:` and `refactor:`
  release nothing. Add the plugin as a scope — `feat(git-hygiene): ...` —
  so the changelog reads well.
- **Never edit a version by hand.** The `version` field in every
  `plugin.json` (`.claude-plugin`, `.codex-plugin`, `.antigravity-plugin`)
  and every `plugins/<name>/CHANGELOG.md` is written by Release Please.

Touch more than one plugin in a commit and it is attributed to all of
them, so keep a commit to one plugin where you can.

## Prerequisites

- Outline account with access to the "Vault" collection (OAuth on first use)
- `uv` (for `uvx`) — only if you install `framework-code-navigation`

Per-plugin details in `plugins/<name>/README.md`.
