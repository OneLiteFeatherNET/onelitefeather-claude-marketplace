# diataxis-docs

Owns the structure of technical documentation using
[Diátaxis](https://diataxis.fr): planning a docs set, routing content into
the right quadrant, writing pages in the voice each quadrant demands,
auditing an existing README or wiki, and generating the reference quadrant
from source instead of typing it.

Diátaxis splits documentation into four modes along two axes — whether the
reader is *studying* or *working*, and whether the content is *practical*
or *theoretical*. That gives tutorial, how-to, reference and explanation.
The claim is not that this is a nice filing convention, but that the four
serve mutually incompatible reader needs, so a page trying to serve two
serves neither. The typical failure it prevents is the README that opens
with installation steps, drifts into a feature list, drops a permissions
table in the middle and ends with a rationale for why forks are
unsupported: every paragraph correct, the whole thing unusable.

## What's inside

- **Skill `diataxis-docs`** — the four modes (planning, routing, writing,
  auditing), the three-question routing test, the writing conventions per
  quadrant, and the rule that reference is generated from source with a CI
  drift gate rather than hand-written.
- `references/quadrants.md` — per quadrant: what belongs, what does not,
  the voice, the failure modes, worked before/after examples.
- `references/reference-pages.md` — the standard reference entry template
  plus generator patterns (annotation processor, JSON Schema, build
  definition, CLI parser) and the CI drift gate.
- `references/auditing.md` — splitting an overloaded README or wiki, drift
  detection, the review checklist for an existing docs set.
- `references/publishing/` — one file per publishing target
  (`outline.md`, `github-wiki.md`, `gitbook.md`): structure, naming, how
  generated pages get published, and when that target is the wrong choice.
  `outline.md` is written against our actual Outline instance: which
  collection a subject belongs in, the hub-document-per-subject layout
  with quadrants as title prefixes, and where the operational record
  (design docs, incidents, runbooks, ADRs) sits instead.
- `assets/page-templates.md` — copy-ready skeletons for all four page
  types plus the index page.
- `assets/nav-templates/` — `_Sidebar.md` for a wiki, `SUMMARY.md` for
  GitBook, `outline-structure.md` for an Outline collection including the
  page-ID mapping file.
- `examples/minecraft-plugin/` — a complete small docs set produced from a
  single overloaded README, including the audit table showing where each
  README section went and which reference pages became generated.

## Install

### Claude Code

```bash
/plugin install diataxis-docs@onelitefeather-claude-marketplace
```

Also bundled as a `framework` dependency, so a fresh `framework` install
brings it along. No MCP servers or external dependencies — pure skill
content, nothing to configure.

### Codex

This plugin ships `.codex-plugin/plugin.json` (pointing at the same
`skills/` directory used above), matching Codex's documented plugin
manifest format. Install it through Codex's own `/plugins` browser once
this marketplace is registered there, or clone/symlink
`skills/diataxis-docs/` into `~/.codex/skills/`.

### Antigravity (`agy`)

This plugin also ships `.antigravity-plugin/plugin.json`. **Not verified
live in this environment** (no `agy` CLI available to test against) — the
manifest follows the same shape as the Codex one as a best-effort
approximation. Try `agy plugin install <this-repo-url>` and confirm the
skill actually surfaces before relying on it.

## Project-specific adjustments

Two defaults are opinionated and may need changing per project:

- **No fifth category.** FAQ, troubleshooting and "advanced usage" are
  refused and routed into how-to or explanation instead, because they
  refill with unsorted content as fast as they are emptied. Projects that
  want to keep a troubleshooting page have to relax that rule in
  `SKILL.md`.
- **Publication language.** German in Outline (internal), English with
  translation via Crowdin for anything published from a repository.
  Change the "Language" section for projects with a different convention.
- **Outline as the default target.** The skill follows the OLF convention
  that prose lives in Outline and a repository carries code plus a link.
  Projects that genuinely need a `docs/` directory — public open-source
  docs shipping with the code — are covered as the documented exception,
  but a project with a different baseline needs the "Publishing targets"
  section adjusted.
