# framework-code-navigation

Optional extension to `framework`: Serena (LSP symbol search) for JVM
projects (Java/Kotlin), so the agent navigates by definition/reference
instead of spamming grep/find/read.

**Deliberately its own plugin, not part of `framework` itself:** not every
project on the team is JVM-based. Installing `framework-code-navigation`
means a Serena connection attempt on every project and requires `uv` (for
`uvx`) — that shouldn't happen to anyone who only needs the vault.
Installing the plugin is itself the signal "I work on JVM code"; the skill
additionally checks at runtime whether the current project actually looks
JVM-based and Serena responds, and stays out of the way otherwise (see
SKILL.md, "Before anything else" section).

## What's inside

- **MCP server `serena`** — LSP symbol search via `uvx` (definitions,
  references, structure, symbol-based editing), including JavaDoc at the
  symbol when `-sources` jars are present. Pinned to a specific release tag
  (currently `v1.6.0`) rather than the moving `git+https://...` HEAD, so
  every install pulls the same known-good version instead of whatever
  upstream happens to contain that day. Bump the tag in
  `.claude-plugin/plugin.json` deliberately when upgrading.
- **Skill `code-navigation`** — routing policy: Serena symbol tools instead
  of grep/find/read, but only when the project looks JVM-based (`pom.xml`,
  `build.gradle(.kts)`, `.java`/`.kt` files) *and* Serena actually responds.
  Otherwise the skill doesn't intervene.

## Install

### Claude Code

```bash
/plugin install framework-code-navigation@onelitefeather-claude-marketplace
```

Prerequisite: [`uv`](https://docs.astral.sh/uv/) (for `uvx`).

### Codex / Antigravity (`agy`)

This plugin also ships `.codex-plugin/plugin.json` and
`.antigravity-plugin/plugin.json`, both pointing at the same `skills/`
directory, so the `code-navigation` routing policy itself ports as-is —
it already checks at runtime whether Serena's tools are actually reachable
before using them (see SKILL.md), so it degrades safely wherever Serena
isn't configured. **The Serena MCP server declaration itself is not
ported** — set up a Serena MCP connection separately on whichever platform
you're using (same `uvx`-based command as in `.claude-plugin/plugin.json`,
pinned to the same release tag).

The Codex manifest is per Codex's documented format (verified). The
Antigravity one is a **best-effort approximation, not verified live** in
this session (no `agy` CLI available to test against) — confirm with
`agy plugin install` before relying on it.

## Test recipe (manual, once installed)

This skill was built without a real Serena connection available in that
session — please verify live once you have one:

1. **JVM project:** in a real Java/Kotlin repo, ask something like "find the
   definition of `<ClassName>`" or "who calls `<method>`". Expected: Claude
   uses `mcp__serena__find_symbol` / `find_referencing_symbols`, not grep.
2. **Non-JVM project** (e.g. a plain Python/TS repo, even with the plugin
   installed): ask the same kind of question. Expected: Claude recognizes
   Serena doesn't apply here and uses normal grep/read — without commenting
   on it or apologizing.
3. If step 2 still tries to use Serena, or step 1 sticks to grep: tighten
   the detection heuristic in SKILL.md (too weak/too aggressive).
