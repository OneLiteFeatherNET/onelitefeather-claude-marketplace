# The four quadrants in detail

Read the section for the quadrant being written. Each section states what the page is for, what
must not appear in it, the mechanical check that catches drift, and the failure mode that produces
bad pages of that type.

---

## Tutorial

**Purpose:** the reader acquires a skill by doing something that works. The subject of a tutorial
is the reader's competence, not the product's features. A tutorial is a lesson, and a lesson is a
contract in which nearly all the responsibility falls on the teacher: there is no obligation on the
learner to understand or remember. If they fail, the tutorial failed.

**Preconditions the author owes the reader:** a stated starting point, a stated end state, and a
promise that following the steps produces that end state. Aspire to perfect reliability — it should
work for every reader, every time. If it cannot be guaranteed on a clean environment, it is not a
tutorial yet.

**What the exercise has to be:**

- **Meaningful** — the reader finishes with a sense of achievement, not a completed chore.
- **Successful** — they can actually complete it.
- **Logical** — the path makes sense as they walk it, even before they understand why.
- **Usefully complete** — it puts them in contact with the actions, concepts and tools they need
  to become familiar with, and no others.

**Positive craft, not just prohibitions:**

- **Narrate the expected.** "After a few moments, the server responds with …". The reader has no
  tutor in the room; the prose is the tutor. This is the commonest reason tutorials fail in the
  field — clean, correct, silent steps that leave the reader unable to tell whether it worked.
- **Signpost the likely wrong turn.** "If the output does not show …, you have probably forgotten
  to …". This is not error handling; it is the tutor noticing.
- **Point out what to notice.** The reader does not yet know which part of the output matters.
- **Permit repetition.** Steps should be safe to run again. Repetition is not the best teacher —
  sometimes it is the only teacher.
- **Open with what will be built, not what will be learned.** "In this tutorial we will create and
  deploy a scalable web application" is right; "in this tutorial you will learn …" is presumptuous
  and a poor pattern, because you cannot make anyone learn — only make it so they can.

**Must not appear:**

- Choices. One path; the reader is never asked to decide between alternatives. (Grep for "or",
  "optionally", "depending on your setup" as a hint — the rule is the intent, not the token.)
- Explanation of why. A sentence of orientation is fine; a paragraph of rationale is a different
  quadrant. Explanation is only pertinent at the moment the reader wants it, and that is not the
  author's call to make on their behalf. This is the hardest temptation for a teacher to resist.
- Abstraction and generalisation. Learning moves from the concrete and particular towards the
  general; the general emerges afterwards, it is not the starting point.
- Anything the reader cannot see the result of. Every step produces a comprehensible result,
  however small, otherwise the reader cannot tell whether it worked.
- Edge cases, error handling, production concerns.

**Voice:** first person plural for the shared journey, second person for actions. Present tense.
Concrete numbers rather than "wait a moment".

**Mechanical check:** can the reader name, in one sentence, the thing they built? If not, it is a
feature tour.

**Failure mode:** the feature tour. The author knows the product and wants to show all of it, so the
tutorial becomes a guided list of capabilities. The reader finishes without having achieved anything
and without a mental model.

**On the number of tutorials:** two tutorials are a smell, not an error. Check each against
study-versus-work: if the second serves a reader who already knows what they want, it is a how-to.
If it serves a genuinely different learner — a library's users and its contributors, an operator and
a developer, three deployment targets that are effectively three products — then two are correct.

**Handling defaults that get in the way:** where a default would break the tutorial path, route
around it silently instead of explaining it. A tutorial that stops to explain why a setting exists
has become an explanation. The reason belongs in explanation, the change belongs in a how-to, and
the tutorial just uses a path where the problem does not arise.

**On finding the flaws:** you will not find them yourself. A tutorial's defects surface only by
watching a real reader work through it, so treat the first external report as data rather than as a
support ticket.

**Before / after:**

> Bad: "You can install the plugin by dropping the JAR into `plugins/`, or use your panel's plugin
> manager, or build from source if you prefer. Note that the default configuration ignores the world
> named `world`, which exists for historical reasons because most servers use it as their survival
> world."

> Good: "Drop the JAR into `plugins/` and restart the server. The startup log now contains a line
> naming the plugin version. Then create a world called `test_world` and switch to it."

---

## How-to

**Purpose:** the reader has a goal and needs a reliable route to it. They already know the product;
the page owes them accuracy, not education. A how-to is a contract in the form: *if you are facing
this situation, you can work your way through it by taking these steps.*

**It answers to a human project, not to the machinery.** "How to calibrate the radar array", "how to
configure reconnection back-off policies" — a real goal someone has. Not "how to use the Deploy
button", which is defined by an operation the tool offers rather than by anything the reader wants.
Tools appear in a how-to as incidental bit-players, the means to the reader's end.

**Structure:** goal restated in one line, prerequisites, the steps, verification, and the branches
and judgement calls the reader actually faces.

**It may branch, and often must.** Real problems do not reduce to a linear procedure. Sequences fork
and overlap, have several entry and exit points, and frequently require the reader's judgement.
Conditional imperatives are the native voice: *"If you want x, do y."* — *"In the case of …, an
alternative approach is …"*. The tutorial is the single-path form because it owns a contrived
environment; the how-to meets the real world and has to prepare for the unexpected. Capping a how-to
at one linear path produces exactly the brittle machine-shaped guide this quadrant exists to avoid.

Actions include thinking and judgement, not only keystrokes. A how-to should address how the reader
thinks as well as what they do.

**Adaptability over narrowness.** A guide useless for any purpose except the exact one described is
rarely worth having. Ground it in a real situation, then leave the reader able to transpose it.

**On flow.** Sequence order is judged, not arbitrary. Ground the steps in the patterns of the
reader's actual activity: does the guide make them switch tool or context repeatedly? How long does
it require them to hold a thought open before it can be resolved in action? Does it make them jump
back to an earlier concern, and is that avoidable? At its best a how-to is the helper who has the
tool you were about to reach for already in their hand.

**Must not appear:**

- Teaching. No explanation of the underlying concept beyond one clause. If it matters, link it.
- Reference material included "for completeness". Link it.
- Restated values from the reference. Name the key, link the reference, let the reader look up the
  default there.
- Multiple goals. "Configure notifications" is a chapter, not a how-to. Split into "Send alerts to
  Discord", "Notify staff in game", "Log alerts to console only".

**Voice:** imperative, with conditional imperatives where the route branches. Titles begin with a
verb and state the reader's goal in the reader's words, never the feature name.

**Mechanical check:** can the title be completed as "How to …"? "How to Discord integration" fails;
"How to send alerts to Discord" passes. Ranked: "How to integrate application performance
monitoring" is good, "Integrating application performance monitoring" is worse, "Application
performance monitoring" is a reference page wearing a how-to costume.

**Failure mode:** the feature page. "Discord integration" collects everything about Discord: what it
is, every option, three workflows and a troubleshooting list. A reader arriving with a goal has to
filter it themselves.

**On completeness:** a how-to may leave things out. Practical usability beats completeness here — a
tutorial has to be end-to-end, a how-to only has to start and end somewhere reasonable. It is
allowed to be opinionated about the route it describes and to ignore the other three, because the
reader wants to finish, not to compare. Comparison is explanation.

---

## Reference

**Purpose:** a description of the machinery and how to operate it. The reader knows what they are
looking for and needs to find it fast and trust it completely.

**Reference is led by the product, not by the reader.** It is neutral about what the reader is
doing — a marine chart serves the navigator plotting a course and the judge investigating the wreck
equally well. Its only job is to describe, succinctly and in an orderly way. This is why its
structure mirrors the machinery's own structure: if a method belongs to a class in a module, the
documentation shows the same relationship. Mirroring also makes gaps visible. The caveat is only
that you do not force the documentation into an unnatural shape to achieve it.

The seriousness is that of a food label. Nobody wants recipes or marketing copy printed among the
allergen information; mixing them in could be dangerous. Reference presentation for food is
governed by law, and reference in software deserves the same kind of care.

**Properties that matter more than prose quality:** completeness, consistency of structure, and
correctness. Reference is scanned, so the structure of the entry does the navigating. Every entry
has the same fields in the same fixed order — the order is in `reference-pages.md`.

**What legitimately belongs here besides machine-derivable facts:** a description of how something
works, the correct way to use it, constraints between options, warnings, and illustrative examples.
These are hand-written and still reference — do not exile them to explanation.

**Must not appear:**

- Recommendations and value judgements: "we recommend", "best practice", "usually you want", "it's a
  good idea". These belong in explanation. In a reference table a recommendation is read as a fact,
  and unlike facts it goes stale silently.
- Narrative or ordering. Reference has no sequence; alphabetical or structural order only.
- Instructions. If the reader is being told to do something in order, it is a how-to.
- Discursive explanation. It damages the reference by interrupting it, and damages the explanation
  by never letting it develop.
- Machine-derivable facts that are nevertheless typed by hand. See `reference-pages.md`.

**Voice:** neutral, terse, present tense. Second person only in constraints and warnings — "You must
use a", "You must not apply b unless c", "Never d" — never in guidance or encouragement. Describe
the machinery, not the reader.

**Mechanical check:** does every entry carry the same fields in the same fixed order, with fields
omitted rather than reordered where they do not apply? The order is in `reference-pages.md`.

**Failure mode:** the annotated config file pasted into a page. It looks like reference and behaves
like one until the software changes. The remedy is generation plus a CI gate.

**The one sentence that must be written by a human:** what the option actually does. A generator can
emit key, type, default and allowed values; it cannot emit effect. Write that sentence next to the
field in the source so the generator carries it along.

---

## Explanation

**Purpose:** understanding. The reader is away from the work — deciding whether to adopt something,
wondering why a thing works the way it does, or building a mental model.

**What belongs here and nowhere else:**

- Design decisions and the alternatives that were rejected.
- Trade-offs between options that a how-to has to pick between.
- Scope boundaries: what the software deliberately does not do, and which platforms are deliberately
  unsupported. This class of page prevents a class of bug report.
- Historical context: why a default is what it is, why an old key still exists.
- Concept introductions that several how-tos would otherwise each repeat.

**Must not appear:**

- Steps. The moment a numbered list of actions appears, the page has become a how-to.
- Reference tables. Link to the reference instead.

**Voice:** discursive, allowed to say "we chose", allowed to compare, allowed to admit uncertainty.
This is the only quadrant where the author's opinion is a feature.

**Mechanical check — the *about* test:** you should be able to put an implicit "about" in front of
the title. *About user authentication.* *About the TPS threshold.* A title that resists it is
usually a reference page or a how-to in disguise.

**Bounding an open-ended topic:** explanation has no natural edges, so anchor each page to a real or
imagined *why* question and let that question decide what is in scope.

**Reader-facing section name:** "Background" is the house choice. "Discussion", "Conceptual guides"
and "Topics" are the canonical alternatives if a project prefers one.

**Failure mode:** it never gets written, because it is the only quadrant with no immediate reader
demand. The symptom is the same three questions being answered by hand in chat every month. Each of
those is an explanation page that does not exist yet; write it the third time the question appears.

**Relationship to ADRs:** where a project keeps architecture decision records, explanation pages and
ADRs overlap but are not the same. The ADR is the internal record with status and consequences,
aimed at the team. The explanation page is the outward-facing narrative, aimed at users, and may
summarise several ADRs. Link the ADR from the explanation rather than duplicating it.
