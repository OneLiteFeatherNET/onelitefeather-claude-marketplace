---
name: diataxis-docs
description: 'Owns the structure of technical documentation using Diátaxis (tutorial, how-to, reference, explanation): planning a documentation set for a project, deciding which quadrant a given page or paragraph belongs in, writing a page in the voice its quadrant demands, splitting an overloaded README or wiki into the four modes, and marking which reference pages must be generated from source instead of hand-written. Use this skill whenever documentation is being planned, written, restructured or reviewed: "write docs for this plugin", "Doku schreiben", "where does this section go", "our README is a mess", "config reference", "Konfigurationsreferenz", "getting started guide", "should this be a tutorial or a how-to", "document this feature", "wiki aufräumen". Trigger it even when Diátaxis is never mentioned, as soon as more than one documentation page is in play or an existing docs set is being reorganised.'
---

# Diátaxis for technical documentation

Diátaxis (Daniele Procida, diataxis.fr, formerly the Divio documentation system) splits documentation into four modes along two axes: whether the reader is *studying* or *working*, and whether the content is *practical* or *theoretical*. That gives tutorial, how-to, reference and explanation.

The framework is not a filing convention. Its claim is that these four serve mutually incompatible reader needs, so a page that tries to serve two serves neither. That is why the typical failure mode is not a missing page but a README that opens with installation steps, drifts into a feature list, drops a permissions table in the middle and ends with a rationale for why forks are unsupported. Every paragraph in it is correct. As a whole it is unusable, because no reader is ever in all four states at once.

The job of this skill is to keep those four apart, and to keep the reference quadrant honest by generating it instead of typing it.

## Modes

**Planning.** A project has no docs, or only a README. Produce the four-quadrant map with real page titles from the project, then the directory layout. See "Planning a documentation set".

**Routing.** A single question: where does this page, section or paragraph go? Apply the routing test below. This is the most frequent mode and usually needs two sentences, not a procedure.

**Writing.** Draft or revise a page in a named quadrant. Read `references/quadrants.md` for the voice and the hard constraints of that quadrant, and `assets/page-templates.md` for the skeleton.

**Auditing.** An existing README, wiki or docs folder needs review: mixed modes, drift, duplication, missing quadrants. See `references/auditing.md`.

Infer the mode rather than asking. "Write docs for X" is Planning, "does this belong in the tutorial" is Routing, "our wiki is a mess" is Auditing. When Planning and Writing are both plausible, plan first and show the map: an agreed map makes the pages nearly free to write, while pages written without one have to be re-sorted later.

## The four quadrants

| Quadrant | Reader is | Serves | Voice |
|---|---|---|---|
| Tutorial | studying, practical | acquisition of skill | "we", "you will", one path only |
| How-to | working, practical | a stated goal | imperative, verb-first title |
| Reference | working, theoretical | a lookup | neutral, stereotyped, no advice |
| Explanation | studying, theoretical | understanding | discursive, may argue and compare |

The two that get confused in practice are tutorial and how-to, because both are step lists. The difference is who chose the goal. In a tutorial the author chose it and guarantees the outcome, so the reader can follow it without knowing anything. In a how-to the reader chose it and already knows the product, so alternatives and prerequisites belong there and nowhere else.

The two that get merged in practice are reference and explanation, because both are "the docs". Keep them apart ruthlessly: reference contains only facts that a generator could in principle produce, explanation contains everything a generator never could.

## The routing test

For any piece of content, three questions in order:

1. **Is the reader at the keyboard right now?** No means explanation. Yes continues.
2. **Do they already know what they want to achieve?** No means tutorial. Yes continues.
3. **Are they carrying out a task, or looking up a value?** Task means how-to, value means reference.

If a paragraph answers differently in different sentences, it is two paragraphs on two pages. Split it and cross-link rather than compromising.

Two recurring signals that routing went wrong:

- A tutorial containing the word "or", or an "optionally", or a table of alternatives. A tutorial has exactly one path. Move the alternatives to a how-to.
- A reference page containing "we recommend", "best practice", "usually you want". Recommendations belong in explanation. Facts do not drift, recommendations do, and a stale recommendation in a reference table is read as a fact.

## Planning a documentation set

Produce two artefacts, in this order.

**The quadrant map.** Real page titles taken from the actual project, not placeholders. Six to eight how-to titles, each beginning with a verb. One tutorial, and only one: a second tutorial almost always means the first one was really a how-to. Reference pages named after what is looked up, not after the code structure. Explanation pages named after the question they answer, including the ones the maintainers are tired of answering in chat.

For every reference page, decide immediately whether it is hand-written or generated, and mark it. See "Generate the reference".

**The layout.** A flat directory per quadrant. The quadrant names are the directory names, because the structure is itself the signpost:

```
docs/
├── tutorial/
├── how-to/
├── reference/
├── explanation/
└── index.md
```

Do not invent a fifth directory. FAQ, troubleshooting, "advanced usage" and "getting started" are the usual smuggling routes for unsorted content, and they refill as fast as they are emptied. An FAQ entry is always a how-to or an explanation in disguise; route it and delete the FAQ.

`index.md` names the four entry points in the reader's language, not the framework's: learn, do a task, look something up, understand the background. Never make the reader learn the word Diátaxis to find a page.

## Generate the reference

Reference is the only quadrant where a machine outperforms a maintainer, and the only one where being out of date is worse than being absent, because a wrong default in a table is trusted. A hand-written configuration reference is wrong two releases after it was written.

Treat as generated by default:

- configuration options: keys, types, defaults, allowed values
- CLI or command syntax and arguments
- permissions and scopes
- supported versions and compatibility matrices
- API surface, endpoints, schemas
- error and exit codes

The rule is that the reference has to fall out of the same source the software itself reads. Annotated config classes, a JSON Schema, the build definition, the CLI parser. Patterns per stack are in `references/reference-pages.md`, together with the standard entry template.

Wire the generator into CI and fail the build when the checked-in output and the freshly generated output differ. Without that gate the generator is only a one-off script and the drift returns.

What stays hand-written in reference: the one-sentence effect of each item, because a default value explains what a knob is set to and never what it does. Put that sentence next to the field in the source, so the generator picks it up too.

## Writing conventions

- **How-to titles start with a verb** in the reader's task language: "Send alerts to Discord", not "Discord integration". A noun title means the page is drifting toward reference.
- **One page, one mode.** A cross-link is always better than a paragraph borrowed from another quadrant.
- **No duplicated values.** A how-to names the key and links to the reference; it does not restate the default. Restated values are the second source of drift after hand-written reference.
- **Tutorials end by handing off**, naming which how-to comes next. That is what stops readers from treating the tutorial as the manual.
- **Explanation is allowed to say what the software is not.** Scope boundaries ("this is not a performance tool", "forks are unsupported") are explanation, never reference, and stating them prevents a class of bug report.

## Language

Match the user's working language when discussing structure. For the documents themselves, follow the project's convention: for OLF projects that means English for all published documentation, with translation handled through Crowdin, matching the code and commit convention.

## Publishing targets

The quadrants stay the same everywhere; only how they are encoded changes. Decide the target before writing pages, because it determines whether the structure is directories, page-title prefixes or a hand-maintained navigation file.

| Target | Quadrants encoded as | Read |
|---|---|---|
| Repository Markdown | directories under `docs/` | nothing extra, this is the default |
| GitHub wiki | title prefixes plus `_Sidebar.md` | `references/publishing/github-wiki.md` |
| Outline | nested documents under four hub pages | `references/publishing/outline.md` |
| GitBook | page groups in `SUMMARY.md` | `references/publishing/gitbook.md` |

Two rules hold across all four. The repository is the source of truth for anything generated, and every other target is a publication of it, never a place where it is typed. And the reader never has to learn the word Diátaxis: hub and group names are "getting started", "how-to guides", "reference", "background".

Navigation file templates for all targets are in `assets/nav-templates/`.

## Worked example

`examples/minecraft-plugin/` is a complete small docs set produced from a single overloaded README, including the routing table that shows where each README section went and which reference pages became generated. Read it when planning a set from an existing README, or when a page needs a model for the voice of its quadrant. The four page files there are deliberately contrasted, and reading them in order (tutorial, how-to, reference, explanation) shows the shift in voice more directly than any rule.

## References

- `references/quadrants.md` — per quadrant: what belongs, what does not, the voice, the failure modes, worked before/after examples. Read before writing a page.
- `references/reference-pages.md` — the standard reference entry template plus generator patterns (annotation processor, JSON Schema, build definition, CLI) and the CI drift gate. Read when a reference page is in play.
- `references/auditing.md` — splitting an overloaded README or wiki, drift detection, the review checklist for an existing docs set. Read in Auditing mode.
- `references/publishing/github-wiki.md`, `outline.md`, `gitbook.md` — one per target: structure, naming, how generated pages get published, and when that target is the wrong choice. Read the one that applies.
- `assets/page-templates.md` — copy-ready skeletons for all four page types plus the index page.
- `assets/nav-templates/` — `_Sidebar.md` for a wiki, `SUMMARY.md` for GitBook, `outline-structure.md` for an Outline collection including the page-ID mapping file.
- `examples/minecraft-plugin/` — a full worked set with the audit table that produced it.
