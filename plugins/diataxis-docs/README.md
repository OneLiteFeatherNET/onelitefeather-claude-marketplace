# diataxis-docs

Owns the structure of technical documentation using
[Diátaxis](https://diataxis.fr): routing content into the right quadrant,
writing pages in the voice each quadrant demands, auditing an existing
README or wiki, growing a docs set one published improvement at a time,
and generating the reference quadrant from source instead of typing it.

Diátaxis splits documentation into four modes along two axes — whether the
reader is *acquiring* skill or *applying* it, and whether the content is
*action* or *cognition*. That gives tutorial, how-to, reference and
explanation. The claim is not that this is a nice filing convention, but
that the four serve mutually incompatible reader needs, so a page trying
to serve two serves neither. The typical failure it prevents is the README
that opens with installation steps, drifts into a feature list, drops a
permissions table in the middle and ends with a rationale for why forks
are unsupported: every paragraph correct, the whole thing unusable.

The framework is deliberately anti-plan: it prefers small responsive
iterations to top-down restructuring, and this skill follows that. The
default unit of work is one improvement, published now — not a migration
proposal, and never four empty quadrant directories.

## What's inside

- **Skill `diataxis-docs`** — the working loop and its four assessment
  questions, the modes (routing, writing, auditing, planning), the routing
  test built on the two canonical axes, the writing conventions per
  quadrant, and the rule that reference is generated from source with a CI
  drift gate rather than hand-written.
- `references/quadrants.md` — per quadrant: what belongs, what does not,
  the voice, the failure modes, worked before/after examples.
- `references/reference-pages.md` — the standard reference entry template
  plus generator patterns (annotation processor, JSON Schema, build
  definition, CLI parser) and the CI drift gate.
- `references/planning.md` — mapping a whole set from scratch or from
  one overloaded README: what to read before naming a page, how many
  pages to actually write, and the layout per publishing target.
- `references/auditing.md` — assessing an existing set page by page,
  splitting an overloaded README or wiki, drift detection, the mechanical
  review pass.
- `references/large-docs-sets.md` — nesting inside a quadrant, the
  quadrants-against-audience case, contents-list limits and landing pages,
  for sets too big for four flat directories.
- `references/publishing/` — one file per publishing target
  (`outline.md`, `github-wiki.md`, `gitbook.md`): structure, naming, how
  generated pages get published, and when that target is the wrong choice.
  `outline.md` is written against our actual Outline instance: which
  collection a subject belongs in, the hub-document-per-subject layout
  with quadrants as title prefixes, and where the operational record
  (design docs, incidents, runbooks, ADRs) sits instead.
- `assets/page-templates.md` — copy-ready skeletons for all four page
  types plus the index page.
- `assets/nav-templates/` — `_Sidebar.md` and `_Footer.md` for a wiki,
  `SUMMARY.md` for GitBook, `outline-structure.md` for an Outline hub
  document and its children, including the page-ID mapping file.
- `examples/minecraft-plugin/` — a documentation map produced from a single
  overloaded README, with four of its pages written out in full as voice
  models plus the index, and the audit table showing where each README
  section went and which reference pages became generated.

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

- **No unsorted-bucket category.** FAQ, "misc", "tips" and "advanced
  usage" are refused and routed into how-to or explanation instead,
  because they refill with unsorted content as fast as they are emptied.
  This is not a ban on nesting or on a page titled "Troubleshooting X" —
  both are fine. A project that wants a genuine catch-all anyway records
  the exception in its own `CLAUDE.md`; the skill defers to a
  project-level instruction that names it explicitly, and is never
  edited in place for one project.
- **Publication language.** German in Outline (internal), English with
  translation via Crowdin for anything published from a repository.
  Projects with a different convention record that in their own
  `CLAUDE.md`.
- **Outline as the default target.** The skill follows the OLF convention
  that prose lives in Outline and a repository carries code plus a link.
  Projects that genuinely need a `docs/` directory — public open-source
  docs shipping with the code — are covered as the documented exception,
  but a project with a different baseline records that in its own
  `CLAUDE.md`.

## Relationship to Diátaxis itself

Everything about the four quadrants, the axes, the working loop and the
per-quadrant constraints is Diátaxis as published at
[diataxis.fr](https://diataxis.fr). Three things in this plugin are not,
and are marked as such in the skill:

- **Generating the reference quadrant and gating it in CI.** Diátaxis
  governs whether documentation is the right *kind* and is explicit that
  it cannot give documentation accuracy — it exposes lapses in accuracy,
  it does not prevent them. Generation is how OneLiteFeather prevents them
  for the quadrant where staleness is most dangerous.
- **The operational-record carve-out.** Design docs, implementation plans,
  incidents, runbooks and ADRs are not user documentation and do not go in
  the quadrants. Diátaxis says nothing about them; the
  `documenting-in-outline` skill owns where they go.
- **The publishing targets**, in particular the Outline hub-document
  layout, which is a OneLiteFeather convention rather than a framework
  feature.
