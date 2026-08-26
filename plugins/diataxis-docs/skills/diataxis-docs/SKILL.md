---
name: diataxis-docs
description: >-
  Owns the structure of technical documentation using Diátaxis (tutorial, how-to, reference,
  explanation): deciding which quadrant a given page or paragraph belongs in, writing a page in
  the voice its quadrant demands, splitting an overloaded README or wiki into the four modes,
  growing a documentation set one published improvement at a time, and marking which reference
  pages must be generated from source instead of hand-written. Use this skill whenever
  documentation is being planned, written, restructured or reviewed: "write docs for this
  plugin", "Doku schreiben", "where does this section go", "our README is a mess", "config
  reference", "Konfigurationsreferenz", "getting started guide", "should this be a tutorial or a
  how-to", "document this feature", "wiki aufräumen". Trigger it even when Diátaxis is never
  mentioned, as soon as more than one documentation page is in play or an existing docs set is
  being reorganised. Not for a single design document, implementation plan, incident writeup,
  runbook or ADR - that is the operational record rather than user documentation, and the
  documenting-in-outline skill owns where it goes.
---

# Diátaxis for technical documentation

Four modes of documentation, split by whether the reader is acquiring skill or applying it, and
whether the content is action or cognition: tutorial, how-to, reference, explanation. The claim
is not that this is a filing convention but that the four serve mutually incompatible reader
needs, so a page serving two serves neither. The work is keeping them apart.

Three things this skill adds on top of the framework, marked as such where they appear: the
reference quadrant is generated from source rather than typed, the operational record is kept out of
the quadrants entirely, and the publishing targets — in particular the Outline hub-document layout —
are OLF conventions rather than framework features.

## How the work actually goes

Diátaxis is not a plan to execute. It discourages top-down workflows in favour of small responsive
iterations, so the default unit of work is one improvement, shipped now — not a restructuring
proposal. Never create empty quadrant directories, and never write a page whose only justification
is that a quadrant is empty.

The loop, applied to whatever is in front of you (when nothing suggests itself, `references/auditing.md` gives the order to pick in):

1. **Assess it** with the four questions: what user need does this serve? How well does it serve
   it? What can be added, moved, removed or changed to serve it better? Do its language and logic
   meet the requirements of that mode of documentation?
2. **Choose one next action** — the smallest change that leaves the page better.
3. **Make it and publish it.** Every step in the right direction is worth publishing immediately.
4. **Repeat.**

"Publish" means whatever shipping the change looks like on the target, and it is gated by the
approval rule under "Modes": on a shared target you prepare the change and show it, the user
performs the push. Publishing without asking applies only to a local working tree the user is
already reviewing.

Documentation is never finished but should always be complete: useful to its readers, appropriate
to the project's current stage, structurally sound. A subject with two how-tos and nothing else is
a complete docs set for what it covers. An empty quadrant needs no placeholder — a page saying
"TBD" is worse than the absence, because it promises something and delivers nothing.

Quadrants appear in a predictable order: how-to first, because someone asked; reference once values
are being repeated in chat; explanation once the same "why is it like that" question comes back a
third time; tutorial last and often never, because it only pays off where newcomers keep arriving.

**Never write a value you did not read.** Defaults, permissions, version ranges, command syntax
and error codes come from the source, never from inference. A fabricated default in a reference
table is the single most damaging thing this skill can produce, because it is trusted. If the
source cannot be found, leave the field out and say so.

**Move, then link, then remove.** Never delete a README section, a wiki page or an Outline
document before the page replacing it exists and is linked from where the old one was.

## Modes

**Routing.** Where does this page, section or paragraph go? Apply the routing test below and answer
from this file alone — do not load reference files, and do not open the project's docs set.

Answer in two sentences: the quadrant, and the one line of the test that decided it. When the
content answers the test differently in different parts, do not force one quadrant — that split is
what the test exists to find. Give one line per fragment, at most four, each as
`"<first few words>" → <quadrant>, because <the line of the test that decided it>`.

Then stop. If the question was *which page* rather than *which quadrant*, say that answering it
needs the docs set read, offer that as the next step, and stop there too. A routing question is not
authorisation to open, move or rewrite anything.

**Writing.** Draft or revise a page in a named quadrant. Read `references/quadrants.md` for the
voice and constraints of that quadrant, and `assets/page-templates.md` for the skeleton. For a
reference page also read `references/reference-pages.md` — it holds the field order, the two
banners, and how to derive `Since` and `Reload` without inventing them.

**Auditing.** An existing README, wiki or docs folder needs review: mixed modes, drift,
duplication, missing quadrants. Read `references/auditing.md`.

**Planning.** A whole documentation set is being mapped before the pages are written — because
nothing exists yet, or because what exists is a single overloaded README. This is the exception,
not the lead mode. Read `references/planning.md`, then the target file under "Publishing targets".

Infer the mode from what exists, not from the wording of the request:

- The request **names one page or one quadrant** — "schreib mir eine Konfigurationsreferenz", "we
  need a getting-started guide" — that is **Writing**, even where a README exists. Read the README
  as a source for that page and mention anything it contradicts, but do not turn the request into
  an audit of it.
- The request is **open** — "write docs for X", "schreib Doku für dieses Plugin" — and the project
  already publishes a docs set (a wiki with pages, a `docs/` tree, an Outline hub): that is
  **Auditing**. Start from what is there, under the five-page cap in `references/auditing.md`.
- The request is **open** and there is nothing, or only a README: **Planning**.

An open request is not permission to ignore the documentation the project already has.

**Confirm before writing, and this outranks "publish it now".** Show the page list, the target and
the parent location in one message, and wait. Required for: more than two documents; any write into
a shared Outline instance, a wiki, or any repository where you do not have standing permission to
push; and any deletion or reduction of an existing page. Reading always needs no approval.
Nineteen speculative documents in the team wiki is a worse outcome than no documentation.

## The four quadrants

| Quadrant | Serves | Axis | Voice |
|---|---|---|---|
| Tutorial | acquisition of skill, through action | acquisition + action | "in this tutorial we will …", one path only |
| How-to | applying skill to a goal | application + action | imperative, verb-first title, may branch |
| Reference | applying knowledge, lookup | application + cognition | neutral, stereotyped, led by the product |
| Explanation | acquiring understanding | acquisition + cognition | discursive, may argue and compare |

The axis names are canon: *acquisition* (study) versus *application* (work), and *action*
(practical steps, doing) versus *cognition* (propositional knowledge, thinking). Use them
flexibly — the point is the distinction, not the vocabulary.

The two that get confused are tutorial and how-to, because both are step lists. The difference is
who chose the goal. In a tutorial the author chose it and guarantees the outcome, so the reader can
follow it without knowing anything. In a how-to the reader chose it and already knows the product,
so alternatives, branches and prerequisites belong there and nowhere else.

The two that get merged are reference and explanation, because both are "the docs". Keep them apart:
reference describes the machinery neutrally, explanation supplies the understanding around it.
Explanatory material sprinkled into reference damages both — the reference is interrupted by
digressions, and the explanation never gets to develop and do its own work.

## The routing test

**0. Is this a page kept current for people using the subject, or a record frozen at the moment it
was written?** Two tests: who is it for, and is it still true next quarter. A page describing how
the system behaves, maintained as the system changes, is user documentation and routing continues.
A page recording what the team decided, what was rejected and why, correct only as of its date, is
the operational record — design doc, implementation plan, incident writeup, runbook, ADR, release
process, contribution guide — and none of the four quadrants apply. "Dokumentier die neue X-
Architektur" is the second unless the requester names a reader outside the team.

When it is the operational record, stop routing and hand the task to the `documenting-in-outline`
skill, which owns the placement including the collection and the parent document. Name the kind out
loud — "that is an incident writeup" — name that skill, and stop. Do not open
`references/publishing/outline.md` to look the destination up: its table names parent documents
without the collections they sit in, so it can only give you a half-address, and stating one
confidently is worse than handing the question on.

1. **Is the reader acquiring skill or applying it?** Acquiring (studying, away from the work) means
   tutorial or explanation. Applying (working) means how-to or reference. "At the keyboard right
   now" is a useful intuition pump for this, and an unreliable one: a comparison matrix or an error
   code gets looked up on a phone during triage and is still reference.
2. **Is it action or cognition?** Carrying out steps means tutorial or how-to. Knowing something
   means explanation or reference.
3. Combine: acquisition + action is tutorial, application + action is how-to, application +
   cognition is reference, acquisition + cognition is explanation.

Apply this at whatever granularity the question has — a whole document, a section, a sentence. If a
paragraph answers differently in different sentences, it is two paragraphs on two pages. Split and
cross-link rather than compromising. The test also works on intentions: *am I about to write for a
reader who is studying, or one who is working?*

**Tutorial versus how-to is not basic versus advanced.** A tutorial can teach something complex to
an expert; a how-to can cover something elementary. "A lesson on the new deployment model for
senior engineers" is a tutorial — those readers are at study, however much they know.

**When intuition and the test disagree, the test wins.** Intuition is fast and sometimes
confidently wrong, which is why the two axis questions are worth applying literally.

Two recurring signals that routing went wrong:

- A tutorial that asks the reader to choose. One path, no options, no "either … or", no table of
  alternatives. Move the alternatives to a how-to. (Grep for "or", "optionally", "depending on" as
  a hint — the rule is the intent, not the token.)
- A reference page containing "we recommend", "best practice", "usually you want", "it's a good
  idea". Value judgements belong in explanation; unlike facts, they go stale silently and are read
  as facts. Constraints and warnings are not recommendations and do belong in reference. The test
  is what happens when the reader ignores the sentence: if the software refuses, fails, rejects the
  value or corrupts something, it is a constraint and stays in reference ("Values above 100 are
  rejected at startup", "Never combine this with `x`"). If ignoring it merely produces an outcome
  the reader could reasonably choose to accept, it is a recommendation and moves to explanation
  ("staying below 100 keeps latency predictable"). A sentence carrying both splits at that line.

## Publishing targets

The quadrants stay the same everywhere; only how they are encoded changes. Determine the target with
this ordered rule, first match wins, and state the result in one line before writing anything:

1. **The project already publishes documentation somewhere** — a `docs/` tree, `SUMMARY.md`,
   `.gitbook.yaml`, `mkdocs.yml`, a GitHub wiki with pages in it, an Outline hub. That is the
   target. Do not migrate a project to a different one as part of a documentation task.
2. **The repository is public and its documentation is user-facing.** The repository, because its
   users cannot read an internal wiki. Determine visibility with
   `gh repo view --json visibility -q .visibility`; if `gh` is unavailable or the project is not on
   GitHub, ask rather than inferring it from the remote URL or the project's name.
3. **Otherwise, for an OLF project, Outline.** A project is an OLF project when its git remote is
   under `OneLiteFeatherNET` or its own `CLAUDE.md` says so — check the remote; never infer it from
   the language the user is writing in.
4. **Otherwise the repository.**

| Target | Quadrants encoded as | Read |
|---|---|---|
| Outline | title-prefixed children under one hub document per subject | `references/publishing/outline.md` |
| Repository Markdown | directories under `docs/` | nothing extra |
| GitHub wiki | title prefixes plus `_Sidebar.md` | `references/publishing/github-wiki.md` |
| GitBook | page groups in `SUMMARY.md` | `references/publishing/gitbook.md` |
| Other static-site generator (MkDocs, Docusaurus, Hugo, Antora) | directories under the docs root plus the generator's own nav file (`mkdocs.yml` `nav:`, `sidebars.js`, `nav.adoc`) | nothing extra |

An existing `docs/` tree organised by feature or by version is still rule 1 — it is the target — and
reorganising it is an Auditing job.

Behind rules 2 and 3: at OLF prose lives in Outline by default and a repository carries code plus a
link, so creating a `docs/` directory is the usual misfire. But the repository wins wherever
documentation must ship with the software, be readable offline, be diffed in review, or reach people
without an Outline account. Both at once is fine when split by audience, never duplicated.

Two rules hold across all targets. The repository is the source of truth for anything generated,
and every other target is a publication of it, never a place where it is typed. And the reader never
has to learn the word Diátaxis: hub and group names are "getting started", "how-to guides",
"reference", "background". Templates for the targets that need a hand-maintained navigation file are in `assets/nav-templates/`.

A reader may enter the documentation anywhere. The tutorial → how-to → reference → explanation
order is a presentation order, not a funnel, so every page has to work as a landing page.

## Planning a documentation set

Only when a whole set is being mapped. The map is a running inventory of what exists and what is
missing, never a scaffold of empty pages to fill. The procedure — what to read before naming a
single page, how many how-tos to actually write, and what the layout is made of per target — is in
`references/planning.md`.

Two rules from it that decide whether the rest goes wrong, so they live here too:

**No dumping grounds.** Do not create a category defined by *not fitting elsewhere* — FAQ,
"Sonstiges", "Misc", "Tips", "Advanced usage". They refill as fast as they are emptied, and an FAQ
entry is always a how-to or an explanation in disguise; route each entry, then propose the emptied FAQ for removal once the replacements are published and linked. This is not a
ban on structure: nesting inside a quadrant is expected (`how-to/install/{local,docker,vm}`), an
audience layer is fine where the audiences are effectively different products, a page titled
"Troubleshooting deployments" is a perfectly good how-to, and "Getting started" is the correct
reader-facing name for the tutorial group. Only the unsorted bucket is forbidden. For sets large
enough that this is a live question, see `references/large-docs-sets.md`.

**Directories arrive with their first page.** The four-quadrant tree is the shape a docs set ends
up in, not the shape it starts as.

## The reference quadrant

Reference is the one quadrant led by the product rather than by reader need. Its structure mirrors
the machinery — the config tree, the module/class/method hierarchy, the command tree, the endpoint
groups — so a reader can work through product and documentation in parallel, and so gaps become
visible. Do not reorganise reference around guessed user intents; keep "named after what is looked
up" for top-level page titles ("Configuration", "Permissions"), not for the structure inside them.

**Generate what is machine-derivable.** This is an OLF policy on top of Diátaxis, not part of the
framework: Diátaxis addresses whether documentation is the right *kind*, and states plainly that it
cannot deliver accuracy — it exposes lapses in accuracy and nothing more. Generation is how those
lapses get prevented rather than merely found. Treat as generated by default:

- configuration options: keys, types, defaults, allowed values
- CLI or command syntax and arguments
- permissions and scopes
- supported versions and compatibility matrices
- API surface, endpoints, schemas
- error and exit codes

The rule is that these fall out of the same source the software itself reads — annotated config
classes, a JSON Schema, the build definition, the CLI parser. Patterns per stack are in
`references/reference-pages.md`.

**Where the values come from when sources disagree.** Read every configuration source and take them
in this precedence, first that exists wins: the typed config class or schema the software reads at
runtime; then the code's inline fallback (`getConfig().getInt("x", 5)`); then the shipped default
file (`src/main/resources/config.yml`). Document the value the running software actually uses.
Where a lower-precedence source disagrees, do not silently pick — report the disagreement to the
user by key and keep the losing value off the page, because a shipped default that no longer
matches the code is exactly the contradiction this work exists to surface. This holds in every
mode.

**Marking is the documentation task; building the generator is a separate one.** Mark each reference
page generated or hand-written, and for the generated ones name the source file the values must come
from. Write the page's current content by hand *from that source* and banner it with the **pending**
banner in `references/reference-pages.md` — never the generated one, which claims a generator
exists and would make the follow-up look done. Hand the generator and its CI gate back as a named
follow-up. Only build the generator when asked: a request for documentation is not authorisation to
add a build task and a CI workflow.

**Not everything in reference is generated.** The effect sentence, correct usage, constraints
between options, warnings and the per-entry example are hand-written and still reference — see
`references/reference-pages.md`. And generation does not discharge the documentation obligation: a
project whose docs are entirely a generated API listing has three empty quadrants, not a finished
job.

## Writing conventions

- **How-to titles start with a verb** in the reader's task language: "Send alerts to Discord", not
  "Discord integration". A noun title means the page is drifting toward reference. In German this is
  an infinitive phrase with the verb at the end — `How-To: Renovate-Preset einbinden` — see
  `references/publishing/outline.md`.
- **One page, one mode.** A cross-link is always better than a paragraph borrowed from another
  quadrant.
- **No duplicated values.** A how-to names the key and links to the reference; it does not restate
  the default. Restated values are the second source of drift after hand-written reference.
- **Tutorials end by handing off**, naming which how-to comes next. That is what stops readers from
  treating the tutorial as the manual.
- **Explanation is allowed to say what the software is not.** Scope boundaries ("this is not a
  performance tool", "forks are unsupported") are explanation, never reference, and stating them
  prevents a class of bug report.

Full constraint lists per quadrant are in `references/quadrants.md`.

## Language

Match the user's working language when discussing structure. For the documents themselves, the
language follows the target, not the project:

- **Outline is internal and German.** Documents are written in German, including the ones a Diátaxis
  task produces. Two things stay English: the four quadrant title prefixes, because they are the
  established convention there, and anything quoted from code — keys, flags, commands, error
  strings.
- **Published documentation is English**, with translation through Crowdin, matching the code and
  commit convention. That covers the repository, wiki and GitBook targets.

## Canon, policy and the licence to deviate

Diátaxis itself is deliberately undogmatic: take what is useful, and if applying it produces
something that feels uncomfortable or ugly, apply it differently. You are authoring for a human
reader, not satisfying a scheme.

Several rules above are OLF policy rather than framework — the three additions named at the top of
this file, plus the conventions below. What separates the two lists is not provenance but
**overridability**. These three a project may override outright, by saying so explicitly in its own
`CLAUDE.md`:

- the ban on unsorted-bucket categories (FAQ, "misc", "tips", "advanced usage" — not a page titled
  "Troubleshooting X", which is a how-to and always allowed)
- the language split: German in Outline, English in repositories
- Outline rather than the repository as the default target

The rest — generation of machine-derivable reference, the operational-record carve-out, and the
routing test itself — are not project preferences and do not yield to one. A project-level exception
is recorded in that project, never by editing this skill.

## Worked example

`examples/minecraft-plugin/` is a documentation map produced from a single overloaded README, with
four of its pages written out in full as voice models plus the index, and the routing table showing
where each README section went and which reference pages became generated. Read it when planning
from an existing README, or when a page needs a model for the voice of its quadrant.

## References

- `references/quadrants.md` — per quadrant: what belongs, what does not, the voice, the failure
  modes, worked before/after examples.
- `references/reference-pages.md` — the standard reference entry template, generator patterns and
  the CI drift gate.
- `references/planning.md` — mapping a whole set: what to read first, how many pages to actually
  write, and the layout per target.
- `references/auditing.md` — assessing an existing docs set, splitting an overloaded README,
  drift detection.
- `references/large-docs-sets.md` — nesting, audience axes, contents-list limits, landing pages.
- `references/publishing/github-wiki.md`, `outline.md`, `gitbook.md` — one per target.
- `assets/page-templates.md` — copy-ready skeletons for all four page types plus the index.
- `assets/nav-templates/` — `_Sidebar.md` and `_Footer.md`, `SUMMARY.md`, `outline-structure.md`.
- `examples/minecraft-plugin/` — the worked set and the audit table that produced it.
