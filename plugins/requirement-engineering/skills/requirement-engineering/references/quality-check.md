# Quality check, traceability and upkeep

## Review checklist (before saving)

Derived from ISO/IEC/IEEE 29148:2018 (5.2.5 individual requirements, 5.2.6 the set) and the INCOSE *Guide to Writing Requirements*.

**Per requirement / user story:**

1. **Necessary** — if it were dropped, would the project actually lose something? Otherwise delete it.
2. **Singular** — exactly one capability. No "and"/"as well as" joining two behaviours.
3. **Unambiguous** — no word two readers would read differently (see the smell table).
4. **Complete** — actor, trigger, behaviour and object are named; no dangling pronoun.
5. **Verifiable** — an observation can be named that would disprove it.
6. **Feasible** — realistic within the stack, the team and the stage.
7. **Solution-free** — describes *what*, not *how*.

**For the document as a whole:**

8. **Complete (set)** — every goal in section 2 is covered by at least one story or NFR, and every story serves a goal.
9. **Consistent and uniform** — no pair contradicts another, and every domain term is used the same way throughout.
10. **Feasible as a whole** (includes "affordable") — nothing has crept in beyond the goals, and the Must requirements together fit the project's means.

Fix violations **before** the document is created — do not append them as a comment.

## Language smells

Following the requirements smells of Femmer et al., extended with our own patterns. A smell is **a reason to look, not an automatic defect** — in a given case the phrasing may be right. Where it is not, the right-hand column applies.

| Smell | Why it is a problem | Rewrite |
|---|---|---|
| Passive without an actor ("the points are awarded") | Nobody is responsible; unclear which component acts | "The scoring system awards …" — name the actor |
| "etc.", "and so on", "among others" | An open list cannot be signed off | List it fully or state the rule |
| Comparative without a reference ("faster", "better") | No point of comparison → not verifiable | "… within 200 ms" or "faster than stage 1 (2 s)" |
| Superlative ("optimal", "maximally stable") | Not achievable, not measurable | Set a concrete target value |
| Vague adjectives ("user-friendly", "robust", "performant") | Subjective; every reviewer measures differently | An observable criterion: "reachable within 3 clicks" |
| Nominalization ("after successful authentication") | Hides actor, timing and condition | "After the user has signed in, …" |
| Universal quantifier ("always", "all", "never") | Usually untrue; hides the real exceptions | Spell out the condition: "When X, the … shall …" |
| Loophole ("if applicable", "as far as possible", "normally", "where sensible") | Makes the requirement non-binding | Either phrase it as binding or delete it |
| Soft modal ("should", "could", "can") | Conflates obligation with priority | `shall` in the sentence, priority in the MoSCoW column |
| Unclear reference ("it", "this value", "the system") | The antecedent is ambiguous | Repeat the noun instead of using a pronoun |
| Two concepts in one sentence ("… process securely and quickly") | Half-passing is not testable | Split into two requirements with their own IDs |

## Sign-off

A requirements document is read by **two sides**:

- **The domain side** (game design or the requester): "Is this what was meant?"
- **The delivery side** (engineering): "Is this buildable and checkable as written?"

Only then does the header read `Signed off (YYYY-MM-DD)`. No issues are created before that.

If the two sides disagree — a contested Must, how the stages are cut, a technology choice — that is not a wording question. Hand over to `decision-sparring` and write the outcome back as a row in section 6.

For game concepts, section 7 contains at least one acceptance criterion that only a playtest can satisfy.

## Traceability (minimal, GitHub-based)

The story ID is the only key. No extra tooling, no traceability matrix.

| From | To | Convention |
|---|---|---|
| Story → issue | Issue title starts with the ID: `US-1.03: player can buy shares` | Searching issues for `US-1.03` finds everything |
| Issue → requirements document | The issue's first line links the section | Once, when the issue is created |
| Issue → commit/PR | PR description: `Closes #42` | Commit body optionally `Refs US-1.03` |
| Story → test | Test name or `@DisplayName("US-1.03: …")` carries the ID | grep is enough as a trace |
| Stage → milestone | One GitHub milestone per stage | Progress without extra upkeep |

**Deliberately not required:** a requirements traceability matrix, backward links from code into the document, or ID upkeep in every commit. In small teams that is the first thing to break down.

## Keeping the document current

- **Status column** per story, exactly these values: `open` · `planned` (issue exists) · `in progress` · `done` (PR merged) · `dropped` (with a reason in section 6).
- **Status in section 6** (open questions, risks, assumptions), a separate value range: `open` · `assumption` · `risk` · `resolved` · `disproved`.
- **Carry the date in the header forward** on every change.
- **Change history** at the end of the document, only for substantive changes to requirements — not for typos.
- **IDs are never reused and never renumbered.** A dropped story stays with status `dropped`; a new one takes the next free number.
- If an already implemented requirement changes substantively: add a new row with a new ID and set the old one to `dropped`. Otherwise issues and tests point at text that no longer exists.

### Changes during delivery

- **A new wish never enters the running stage.** It becomes a story in the next stage, or a row in "Won't (this stage)" with a reason. Exception: it replaces a Must story of comparable size — then the replaced one goes to `dropped` with a pointer to the new ID.
- **A story turns out to be undeliverable:** go back to the document, not just the issue. Old ID to `dropped` with the reason in section 6, new story with a new ID, close the old issue and link the new one.
- **An assumption falls:** set it to `disproved` in section 6 and review every story built on it.

## Sources

- [ISO/IEC/IEEE 29148:2018](https://www.iso.org/standard/72089.html) — characteristics of individual requirements and of the set
- [INCOSE Guide to Writing Requirements](https://www.incose.org/docs/default-source/working-groups/requirements-wg/guidetowritingrequirements/incose_rwg_gtwr_v4_summary_sheet.pdf) — writing rules and characteristics
- [Femmer et al.: Rapid Quality Assurance with Requirements Smells](https://arxiv.org/abs/1611.08847) — the language smells and their context dependence
- [GitHub: Linking a pull request to an issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue) — closing keywords

The full 29148 text is paywalled; the characteristic names come largely from accessible renderings.
