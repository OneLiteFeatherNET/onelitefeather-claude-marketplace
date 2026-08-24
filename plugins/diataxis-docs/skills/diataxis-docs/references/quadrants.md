# The four quadrants in detail

Read the section for the quadrant being written. Each section states what the page is for, what must not appear in it, and the failure mode that produces bad pages of that type.

---

## Tutorial

**Purpose:** the reader acquires a skill by doing something that works. The subject of a tutorial is the reader's competence, not the product's features.

**Preconditions the author owes the reader:** a stated starting point, a stated end state, and a promise that following the steps produces that end state. If the author cannot guarantee it on a clean environment, it is not a tutorial yet.

**Must not appear:**

- Options, alternatives, "or", "optionally", "depending on your setup". One path.
- Explanation of why. A sentence of orientation is fine; a paragraph of rationale is a different quadrant.
- Anything the reader cannot see the result of. Every step produces a visible change, otherwise the reader cannot tell whether it worked.
- Edge cases, error handling, production concerns.
- A second tutorial. If a project seems to need two, one of them is a how-to.

**Voice:** first person plural for the shared journey, second person for actions. Present tense. Concrete numbers rather than "wait a moment".

**Failure mode:** the feature tour. The author knows the product and wants to show all of it, so the tutorial becomes a guided list of capabilities. The reader finishes without having achieved anything and without a mental model. Test: does the tutorial have exactly one outcome that the reader can name afterwards?

**Handling defaults that get in the way:** where a default would break the tutorial path, route around it silently instead of explaining it. A tutorial that stops to explain why a setting exists has become an explanation. The reason belongs in explanation, the change belongs in a how-to, and the tutorial just uses a path where the problem does not arise.

**Before / after:**

> Bad: "You can install the plugin by dropping the JAR into `plugins/`, or use your panel's plugin manager, or build from source if you prefer. Note that the default configuration ignores the world named `world`, which exists for historical reasons because most servers use it as their survival world."

> Good: "Drop the JAR into `plugins/` and restart the server. Then create a world called `test_world` and switch to it."

---

## How-to

**Purpose:** the reader has a goal and needs the shortest reliable route to it. They already know the product; the page owes them accuracy, not education.

**Structure:** goal restated in one line, prerequisites, numbered steps, one verification step, and the one failure branch that actually occurs in practice.

**Must not appear:**

- Teaching. No explanation of the underlying concept beyond one clause.
- Restated values from the reference. Name the key, link the reference, let the reader look up the default there.
- Multiple goals. "Configure notifications" is a chapter, not a how-to. Split into "Send alerts to Discord", "Notify staff in game", "Log alerts to console only".

**Voice:** imperative. Titles begin with a verb. The title states the reader's goal in the reader's words, never the feature name.

**Failure mode:** the feature page. "Discord integration" collects everything about Discord: what it is, every option, three workflows and a troubleshooting list. It fails because a reader arriving with a goal has to filter. Test: can the title be completed as "How to …"? "How to Discord integration" fails, "How to send alerts to Discord" passes.

**On completeness:** a how-to may leave things out. It is allowed to be opinionated about the route it describes and to ignore the other three routes, because the reader wants to finish, not to compare. Comparison is explanation.

---

## Reference

**Purpose:** a lookup. The reader knows what they are looking for and needs to find it fast and trust it completely.

**Properties that matter more than prose quality:** completeness, consistency of structure, and correctness. Reference is scanned, so the structure of the entry does the navigating. Every entry has the same fields in the same order, even when a field is empty.

**Must not appear:**

- Recommendations, best practices, "we suggest". These belong in explanation. In a reference table a recommendation is read as a fact, and unlike facts it goes stale silently.
- Narrative or ordering. Reference has no sequence; alphabetical or structural order only.
- Instructions. If the reader is being told to do something in order, it is a how-to.
- Anything a generator could produce that is nevertheless typed by hand. See `reference-pages.md`.

**Voice:** neutral, terse, present tense, no second person. Describe the machinery, not the reader.

**Failure mode:** the annotated config file pasted into a page. It looks like reference and behaves like one until the software changes. The remedy is not more discipline, it is generation plus a CI gate.

**The one sentence that must be written by a human:** what the option actually does. A generator can emit key, type, default and allowed values; it cannot emit effect. Write that sentence next to the field in the source so the generator carries it along.

---

## Explanation

**Purpose:** understanding. The reader is away from the keyboard, deciding whether to adopt something, wondering why a thing works the way it does, or trying to build a mental model.

**What belongs here and nowhere else:**

- Design decisions and the alternatives that were rejected.
- Trade-offs between options that a how-to has to pick between.
- Scope boundaries: what the software deliberately does not do, and which platforms are deliberately unsupported. This class of page prevents a class of bug report.
- Historical context: why a default is what it is, why an old key still exists.
- Concept introductions that several how-tos would otherwise each repeat.

**Must not appear:**

- Steps. The moment a numbered list of actions appears, the page has become a how-to.
- Reference tables. Link to the reference instead.

**Voice:** discursive, allowed to say "we chose", allowed to compare, allowed to admit uncertainty. This is the only quadrant where the author's opinion is a feature.

**Failure mode:** it never gets written, because it is the only quadrant with no immediate reader demand. The symptom is the same three questions being answered by hand in chat every month. Each of those is an explanation page that does not exist yet; write it the third time the question appears.

**Relationship to ADRs:** where a project keeps architecture decision records, explanation pages and ADRs overlap but are not the same. The ADR is the internal record with status and consequences, aimed at the team. The explanation page is the outward-facing narrative, aimed at users, and may summarise several ADRs. Link the ADR from the explanation rather than duplicating it.
