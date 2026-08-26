---
name: requirement-engineering
description: Use when a project's requirements need writing down or cleaning up — "requirements", "user stories", "acceptance criteria", "release stages", "non-functional requirements", or the German "Anforderungen", "Ausbaustufen", "Akzeptanzkriterien", "Abnahmekriterien"; when a concept for a game, feature or event exists only as prose; when a library or service has unclear scope; when a running system was never documented; or when someone asks about EARS or MoSCoW. Works for internal wiki-documented projects, public open-source repos and third-party projects alike. Not for prioritizing issues, not for test cases, not for choosing between options (decision-sparring), not for framing a vague request (problem-framing), not for documenting a finished feature (diataxis-docs).
---

# Requirement Engineering

Records **what** should be built and **how anyone can tell it is done** — for product and game concepts as much as for libraries, services and infrastructure tools.

## Two failure modes, equally bad

**Filling in the form.** The structure is there but the content is invented — five stages, thirty stories, numbers nobody ever decided. It looks like requirements and is fiction with table borders.

**Waving prose through.** The structure gets laid over an existing text without sharpening anything. "The game should stay exciting" becomes a table row — just as unverifiable as before, only more official.

The job is to turn what is known into checkable sentences and to mark what is not known **as a visible gap**, rather than inventing it.

## Establish the context first

Three things decide where the document goes, in which language it is written, and how much house style applies. Determine them before writing, from the repo and the request — do not ask if the answer is visible.

| Context | Typical signals | Home | Language |
|---|---|---|---|
| **Internal** | Private repo, an org wiki in use, existing project docs there | The wiki (for OneLiteFeather: Outline, see `references/outline-conventions.md`) | The language the existing docs use — German at OLF |
| **Open source** | Public repo, external contributors, review by diff | `docs/requirements/` in the repo, see `references/repo-layout.md` | English |
| **Third-party** | Someone else's project, unfamiliar conventions | Wherever that project already keeps decisions; ask if unclear | The project's own language |

**Language follows the project, not this skill.** English is the canonical form of the standard; any other language keeps the structure and translates the surface — the full German mapping and the rules for other languages are in `references/localization.md`. Mixing languages inside one document is never correct.

**House style is a layer, not the base.** Outline conventions, an org's ID scheme or a wiki's parent structure apply only where that org's project is being documented. On a third-party project, the structure below still holds; the storage conventions do not.

## Quick reference

**Acceptance criteria (EARS):**

| Pattern | Form |
|---|---|
| always applies | The \<system\> shall \<response\>. |
| point in time | **When** \<trigger\>, the \<system\> shall \<response\>. |
| period of time | **While** \<state\>, the \<system\> shall \<response\>. |
| error case | **If** \<condition\>, **then** the \<system\> shall \<response\>. |
| optional feature | **Where** \<feature is active\>, the \<system\> shall \<response\>. |
| combined | **While** …, **when** …, the \<system\> shall \<response\>. |

Subject before `shall` · obligation is `shall`/`shall not`, never `should` · priority lives only in the MoSCoW column.

**Sections:** header · 1 context and background · 2 goals and non-goals · 3 stakeholders and roles · 4 stage overview · 5 non-functional requirements · 6 open questions / risks / assumptions · 7 sign-off criteria · change history
**IDs:** `US-X.NN` · `EN-X.NN` (enablers) · `NFR-001` · `MAP-/RES-001` (maps, assets)
**Story status:** open · planned · in progress · done · dropped
**Section 6 status:** open · assumption · risk · resolved · disproved
**MoSCoW:** per stage, at most 60 % Must

## Scale the effort

| Input | Approach |
|---|---|
| A question about the standard | Answer it, create nothing |
| Two sentences of an idea, nothing decided | Frame it first — not yet a requirements job (see Handoffs) |
| A worked-out concept, one stage in sight | One document, story table as section 8 inside it, no child documents |
| A multi-stage project with clear scope | Full structure: main document plus one child per stage |

More structure than substance is a mistake, not diligence.

## The ingredients

| Ingredient | What it is | Details |
|---|---|---|
| User stories staged by release slices | "As a \<role\> I want \<goal\> so that \<benefit\>". A stage is **the whole product in its simplest usable form** — it touches every activity once instead of finishing one feature. | `references/story-mapping.md` |
| EARS sentence template | A fixed sentence shape for acceptance criteria so they are testable rather than interpretable. The quick reference above is a memory aid, **not a substitute** for the reference. | `references/ears-patterns.md` |
| MoSCoW | Must/Should/Could/Won't, assigned per stage. | `references/story-mapping.md` |
| NFR checklist | Non-functional requirements — everything that is not a feature rule: speed, failure, language, fairness, operations. Ten categories, each considered once, none without a check criterion. | `references/nfr-categories.md` |
| Quality check | Ten-point review, language smells, sign-off, traceability, upkeep. | `references/quality-check.md` |
| A filled-in example | Real rows in the target format when the shape is unclear. | `references/example-economy-system.md` |
| Localization | Section names, status values and EARS forms in another language. | `references/localization.md` |

## Document structure

**Main document "Requirements: \<project\>"** — header (responsibilities, document status, review, date), sections 1–7, change history. Layout and columns are filled in inside the templates:

- `references/template-product-concept.md` — role "As a player/user", for games, events and user-facing features, including section 5b for maps, assets and balancing
- `references/template-technical-project.md` — role "As a developer/operator", with an extra interface/API column

**One child document per stage, "User Stories: Stage X"**: `ID` · `Activity` · `Story` · `Acceptance criterion (EARS)` · `Priority` · `Status`, plus an enabler table and a Won't table.

The **Activity** column is the story map's backbone in table form: reuse the same activity names across all stages. A stage that touches only one or two activities is a feature bundle, not a slice.

### Shared base requirements

Requirements that hold for **every** project in a family (returning to the lobby, chat and moderation rules, auth behaviour, asset delivery) live once in a "Base requirements" document with their own ID space `BASE-001…`. Project documents do not copy them; they link them from section 5 in a single line. A project that deviates gets a "Deviations from BASE" table with ID, deviation and reason — an unexplained deviation is a bug, not a requirement. If the base document does not exist, do not create it on the side; propose it.

### What does not belong in the document

A requirements document describes **what** the system must do for whom and **how you can tell** — not how it is built.

- **Solution design and architecture** — classes, schemas, library choices. Exception: a technology that is a genuine *constraint* belongs in section 2, or as an NFR under compatibility, with a reason.
- **Implementation detail** — algorithms, code snippets, configuration values without domain meaning. Balancing values *are* domain content and belong in (section 5b).
- **Schedules and estimates** — sprints, deadlines, story points. Ordering already lives in the stages and MoSCoW; dates belong in the issue. Exception: the fixed date of a time-boxed event is a constraint in section 2.
- **Test cases** — the EARS criterion says *what* must hold; how it is tested belongs in the test.

Rule of thumb: if the sentence contains a *how* that a developer could legitimately solve differently without any stakeholder noticing, it does not belong here.

## Ask or assume?

Before writing, check the six W's against the input: *who* uses it, *what* should happen, *why*, *when / under which condition*, *where* the system boundary runs, *how much*. When an answer is missing, the cost rule decides:

- **Ask** — at most **three** questions, bundled into *one* message, and only when a wrong assumption would destroy the **structure**: project type, roles, system boundary, how the stages are cut.
- **"Work independently" does not cancel the question, only the waiting.** When a structure-destroying uncertainty is open, ask it *and* still deliver the draft under the marked assumption — stating explicitly that a different answer means a re-cut, not a correction. Staying silent and picking one reading is not an option.
- **Assume and mark** everything else (numbers, edge cases, NFR detail, naming) — as a row in section 6 with status `assumption`, never silently.
- **Never invent without marking.** An unmarked number in the document is a defect, however plausible it looks.
- When restructuring, do not ask what the source text already says — read first, then ask.

## Where the document goes

First matching rule wins:

1. The user names a target → there.
2. Public repo, or review-by-diff wanted → Markdown in the repo, see `references/repo-layout.md`.
3. The project's org keeps its docs in a wiki and a parent for this project exists → child document underneath. For OneLiteFeather that is Outline; see `references/outline-conventions.md`.
4. The wiki's tools are unavailable → repo as well; propose the path and **never invent wiki URLs**.
5. Otherwise ask. Never choose silently.

### When an org's canon and this skill disagree

Where an organization keeps a written version of its own standard, that document decides **content** — which projects and parents exist, which roles, stages and conventions the team agreed on. On conflict the org's canon wins, but only if it was actually consulted; unchecked, this skill applies.

This skill decides the **shape of acceptance criteria**, because that is a matter of syntax rather than team preference. `When <condition>, shall <system> <behaviour>` is not valid EARS in any organization.

If an outdated shape turns up in an org's existing documents, **do not quietly rewrite them**. New material uses the correct shape, and when a table is being reworked, convert it fully — never mix inside one document. Name the finding once and offer a migration note; a human decides whether to apply it. OneLiteFeather's is prepared in `references/canon-migration.md`.

## Workflow

| Situation | Path |
|---|---|
| Look up the standard | Answer, cite the references |
| New project, content available | A |
| Existing prose document | B |
| System is running, no document | C |
| A stage is about to be built | D |
| Idea still fuzzy | Frame first, then A |

**Determine the project type:** product/game concept or technical project → picks the template variant. When unsure, make a sensible assumption and say so in the reply.

**Search before duplicating:** check whether a document for the project already exists — in the wiki, in `docs/`, in the README. Do not assume it is missing.

### A) Create a new requirements document

1. **Required reading before the first sentence** — the quick reference is not enough: `references/story-mapping.md` before cutting the stages, and `references/ears-patterns.md` before writing the first acceptance criterion. If the document language is not English, `references/localization.md` too.
2. Load the matching template and fill it with the project's content.
3. Walk the category checklist in `references/nfr-categories.md` once, completely.
4. Run the quality check in `references/quality-check.md` — fix violations **before** anything is created.
5. **Show the draft and get sign-off.** A shared wiki is not a scratchpad, and a tree of one main plus N child documents is not easily taken back.
6. After sign-off, create: main document under the project parent, then one child per stage. Patch the stage table with the real URLs afterwards.

### B) Restructure an existing prose document

The standard case for old concept docs.

1. Load the document and **read all of it**.
2. Required reading as in A) step 1.
3. **Derive the backbone:** name three to six activities in narrative order from the prose — that is the `Activity` column and the basis of every stage cut.
4. Extract the facts: pull out rules, constraints and implicit requirements, and phrase them as stories and NFRs.
5. **Present the draft before overwriting anything.** Prose concepts carry design decisions in subordinate clauses, and extraction shortens them wrongly.
6. Once confirmed: the original text (trimmed if needed) stays as section 1 instead of being deleted. Rework in place with a patching edit or as a new child document — never a blind full replace.

### C) Document a running system after the fact

The sources are code and observed use, not a text.

1. **First check whether material does exist after all** — search the wiki for the project name, look for a README or concept files in the repo. "There is nothing on this" is wrong surprisingly often, and a missed concept makes the whole reconstruction worthless.
2. Name the sources: repo and classes, config files, statements from users or the team.
3. **If what you find contradicts the brief, that is a blocking risk, not a detail.** Do not derive requirements from the brief then — present the contradiction with citations and have it resolved.
4. Every requirement gained this way is **observed actual behaviour**, not intent: status `done`, additionally marked "(reconstructed)".
5. **Code never answers the "so that".** If the benefit cannot be evidenced from observed use or the team, it stays an open question — do not fill it in plausibly.
6. Places where the actual behaviour is probably a bug go to section 6 as a risk, not in as a requirement.
7. Inventing stages retroactively is forbidden: everything that exists is "Stage 0 (as built)"; only planned work gets cut into stages.
8. The result goes to someone who knows the system, for confirmation. Reconstruction without a second reader is fiction with citations.

### D) From document to issues

Only when a stage is about to be built — not when the document is created, and not before sign-off.

1. One milestone per stage, never per feature.
2. One issue per story and per enabler, title starting with the ID: `US-1.03: <story text, shortened>`.
3. Order: enablers before the stories they unblock; then Must → Should → Could. Won't entries get no issue.
4. Issue body: first line links the section, then the EARS criteria as a checklist.
5. Set the story's status in the document to `planned`.

Issues are **not created automatically.** Propose the list; the user confirms creation.

## Guardrails

- Never overwrite an existing, detailed document without comment — sign-off precedes every restructuring.
- Never create documents in a shared wiki before the draft is signed off.
- No NFR without a check criterion; no number without a source or an assumption marker.
- One language per document; never mix an English keyword into a foreign-language sentence.
- Not every NFR category must be filled, but every one must have been considered once.

## Red flags — stop and go back to the draft

- I am writing a number into an NFR that nobody stated, and not marking it.
- I am creating documents without a signed-off draft.
- I am filling a stage with stories that do not appear in the source material.
- Every story is "Must".
- A stage touches only one activity.
- I am overwriting prose I only skimmed.
- I have a wiki URL that came from a pattern rather than from a tool response.
- I am writing criteria without having read `references/ears-patterns.md`.
- I am applying one org's house conventions to a project that is not theirs.

| Excuse | Reality |
|---|---|
| "The user explicitly allowed overwriting." | Allowed is not unreviewed. Showing the draft costs one message. |
| "The number is plausible, 20 TPS is standard." | Plausible ≠ decided. Mark it as an assumption. |
| "Without five stages the document looks empty." | One real stage beats four invented ones. |
| "The concept is short, I got the gist." | Short concepts carry their design decisions in subordinate clauses. |
| "Questions only slow things down." | Three bundled questions are allowed and cheaper than a wrongly structured document. |
| "Wiki URLs follow a pattern, I can build one." | The slug contains a random ID. Guessed links are dead links. |
| "I know the sentence shape, I can skip the reference." | That is exactly how criteria without an actor get written. |
| "It's all one standard, the German forms work everywhere." | The document's language follows the project. Check the context table first. |

## Handoffs

| Situation | Skill |
|---|---|
| The request is fuzzy, contradictory or solution-shaped — it is unclear *which problem* is being solved | `problem-framing` first; its brief (goal, in-scope, out-of-scope, constraints, done-when, glossary) feeds sections 1, 2 and 7 directly |
| The real question is a decision (technology choice, how to cut the stages, a contested Must) | `decision-sparring`; record architecture-binding outcomes as an ADR |
| It is about documentation for the *finished* thing (tutorial, how-to, reference) | `diataxis-docs`. Requirements are operational project state, not a Diátaxis quadrant |
| General project documentation in an OLF Outline wiki without requirements character | `documenting-in-outline` |
