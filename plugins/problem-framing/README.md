# problem-framing

Turns a vague, shifting or solution-shaped request into a short written
problem brief before the expensive work starts: an explicit goal,
in-scope and out-of-scope lists, constraints, testable acceptance
criteria, an agreed glossary and marked open questions.

Underspecified requests do not fail loudly. They produce a fluent,
confident answer to a question nobody asked, and the cost only surfaces
after the work is done. The skill steers between the two ways of getting
that wrong — interrogating the person with ten clarifying questions, and
silently filling every gap with a plausible default.

## What's inside

- **Skill `problem-framing`** — when a request is not yet framed, a
  three-questions-per-turn budget where every question carries a default,
  a routing table from symptom to lens, the brief format, EARS-style
  acceptance criteria, and the drift protocol for when the target moves
  mid-task.
- `references/lenses.md` — the lenses the routing table points at: IS/IS
  NOT specification for defects, the goal ladder for technique requests,
  artifact-first for "I don't know what I want", measure-first for
  baseline-free comparatives.
- `references/term-finding.md` — the six-rung ladder for a thing
  described by its function but not named, including the German variants
  and the guardrail against collecting agreement instead of information.

Two parts are worth calling out because they are what the skill is really
for. **The anti-paraphrase rule**: restating someone's circumlocution in
confident technical vocabulary reads as helpfulness but is in fact a
silent commitment to one referent, and it is where fabricated detail
usually enters. A supplied term is a proposal and gets marked as one.
**The out-of-scope list**: written before the in-scope list, because it
is easier to see what is tempting than what is necessary, and the
tempting adjacent work is what silently doubles the effort.

## Install

### Claude Code

```bash
/plugin install problem-framing@onelitefeather-claude-marketplace
```

Also bundled as a `framework` dependency, so a fresh `framework` install
brings it along. No MCP servers or external dependencies — pure skill
content, nothing to configure.

Pairs with `decision-sparring`: once a framed problem turns out to be a
choice between options, the brief is that skill's input.

### Codex

Ships `.codex-plugin/plugin.json` pointing at the same `skills/`
directory. Install through Codex's `/plugins` browser once this
marketplace is registered there, or clone/symlink
`skills/problem-framing/` into `~/.codex/skills/`.

### Antigravity (`agy`)

Also ships `.antigravity-plugin/plugin.json`. **Not verified live in this
environment** (no `agy` CLI available to test against) — same shape as
the Codex manifest as a best-effort approximation. Confirm the skill
surfaces before relying on it.
