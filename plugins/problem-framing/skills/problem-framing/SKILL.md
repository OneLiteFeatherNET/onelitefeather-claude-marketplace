---
name: problem-framing
description: >-
  Turns a vague, shifting or solution-shaped request into a short written problem brief with an
  explicit goal, in-scope and out-of-scope lists, constraints, testable acceptance criteria, an
  agreed glossary and marked open questions, so the work that follows is narrow and checkable
  instead of plausible and wrong. Detects the XY problem (asking about the attempted solution),
  target drift (starts as A, turns out to be B) and circumlocution (describing a thing by its
  function because the term is missing), and resolves a missing term by elicitation instead of
  silently paraphrasing it into confident vocabulary. Use this skill whenever a task arrives
  underspecified, contradictory or described in placeholders: "make it better", "fix the
  performance", "the thing that catches the errors", "so ein Ding das", "das ist irgendwie
  kaputt", "ich weiß nicht genau was ich will", "eigentlich meinte ich", or whenever a request
  could be read two different ways.
---

# Problem Framing

## Core idea

Underspecified requests do not fail loudly. They produce a fluent, confident answer to a question nobody asked, and the cost only surfaces after the work is done. Framing is cheap in comparison, so the goal is a short written brief that names the target, the boundary and the finish line before the expensive part starts.

Two failure modes, equally bad:

- **Interrogation.** Ten clarifying questions before any help arrives. The person came with a question and leaves with homework. Withholding an answer until the request is reformulated to your satisfaction is not rigor, it is a toll booth.
- **Silent guessing.** Filling every gap with a plausible default, never naming which defaults were chosen. The answer looks finished, and the wrong assumption is discovered three steps later.

The way between them: answer with the best available reading, state the assumptions that reading rests on, and make the open questions visible and cheap to answer.

## When to run

Signals that a request is not yet framed:

- The goal is a comparative with no baseline: better, faster, cleaner, more robust
- The request names a technique rather than an outcome ("add caching", "use a queue")
- A thing is described by what it does rather than named ("the part that retries the failed jobs"), or carries a placeholder noun: thing, mechanism, layer, service, Ding, Sache
- Two readings of the sentence would produce different deliverables
- Scope has no edge: nothing in the request says what is not included
- The person says they are not sure what they want, or describes symptoms in the plural without a pattern
- A previous attempt was rejected with "not quite" or "eigentlich meinte ich"
- The work about to start is expensive: implementation, migration, a document, a deck, a refactor

For a cheap, reversible task, skip the brief and just do the work. Framing a five-line answer costs more than redoing it.

## Question budget

- At most three questions per turn, and only questions whose answers change the output. If the answer would not change anything, it is curiosity, not clarification.
- Never ask what the context, the files, the code or the earlier conversation already answer.
- Offer options rather than open prose whenever the answer space is small. Selecting is faster than composing.
- Give every question a default: "I will assume X unless you say otherwise." That way silence is a valid answer and the work can start.
- Ask in one batch. Serial questioning turns a two-minute clarification into a ten-message exchange.

## Workflow

1. **Capture the request verbatim.** The original wording is evidence. Do not paraphrase it away before analyzing it, because the paraphrase is where the misreading enters.
2. **Classify and pick a lens.** See the routing table below; details in `references/lenses.md`.
3. **Run the lens.** Extract only what the brief needs.
4. **Write the brief.** Format below. Keep it to one screen.
5. **Confirm in one line.** "I read this as: [one sentence]. Go, or correct me." Not a questionnaire, one sentence to accept or reject.
6. **Keep the brief live.** On contradiction later, apply the drift protocol.

## Routing table

| What arrived | Lens | What it produces |
| --- | --- | --- |
| Something is broken, intermittently or inexplicably | IS / IS NOT specification (what, where, when, extent) | A sharp boundary around the defect and the contrast that explains it |
| A request for a specific technique or mechanism | Goal ladder ("what does that get you") | The actual objective, plus whether the proposed technique reaches it |
| A thing described by its function, unnamed | Term-finding ladder, `references/term-finding.md` | An agreed term, recorded in the glossary and then used unchanged |
| "I don't know what I want" | Artifact first: examples, counterexamples, negative space | A target described by comparison when it cannot be described directly |
| A comparative with no baseline | Measure first: current value, target value, measurement method | A finish line that can be checked |
| Build or write something | Spec: scope, non-goals, acceptance criteria | A bounded deliverable |
| Several problems in one message | Split and rank by cost of being wrong | One problem in focus, the rest parked in writing |

## The XY check

When the request names a solution rather than an outcome, ask once what it is meant to achieve. One question, phrased as interest rather than correction: "What does that get you downstream?"

Two rules keep this from becoming obnoxious:

- **Answer the question that was asked anyway.** If there is a real answer to the literal request, give it. Then note the alternative: "This is how you do Y. If the goal is actually Z, then W is shorter."
- **Take the answer at face value.** If the person confirms they do want Y, help with Y. They may have context that is not on the table. One redirect is a service, three is treating them as an unreliable narrator.

## Anti-paraphrase

Developers routinely describe things they cannot name: "the part that catches the error before it reaches the user", "so ein Ding, das die Requests sammelt". This is not sloppiness. It is circumlocution, the standard strategy for a lexical gap, and the description almost always carries the right concept. The gap is in the vocabulary, not in the understanding.

The hazard is what happens next. Restating the description in confident technical vocabulary reads as helpfulness and is in fact a commitment: it picks one referent out of the several the description fits, and every later turn builds on that pick. Nothing marks the pick as a guess. Fabricated detail usually enters here, not at the gap itself but at the paraphrase that closed it silently.

Three rules:

1. **Keep the original wording.** Quote it in the brief. The developer's phrase stays the anchor, so a wrong reading is still catchable three turns later.
2. **Never substitute silently.** A term you supply is a proposal and is marked as one: "I am reading 'the part that catches the error' as an exception handler in the middleware chain. Right?" A proposal can be rejected; a silent substitution cannot.
3. **Elicit before supplying.** Give the developer the chance to produce the term first. Once you have supplied one, correcting it means contradicting a confident-sounding statement, and people often just go along. The wrong term then becomes fixed vocabulary for the rest of the conversation.

### Term-finding ladder

Climb only as far as needed, from least to most supportive. Details, examples and the German variants are in `references/term-finding.md`.

1. **Point at it.** "Which file, which line, which log entry?" An artifact beats any description, and it costs the developer nothing to produce.
2. **Mark the gap.** Repeat their phrase back with the hole visible: "the part that catches the error, what is that in the code?" Locates the trouble without prescribing an answer.
3. **Feature grid.** Ask along fixed dimensions instead of asking for the word: category, function, position in the system, input and output, neighbors, and what it is explicitly not. Sharp enough to identify the referent even if the word never surfaces.
4. **Candidate set.** Offer two to four named terms, each with a one-line differentiator, plus an explicit "none of these". Recognizing a term is far easier than producing one.
5. **Partial cues.** For "I know it, I just cannot get to it": first letter, one word or two, vendor or open source, where they last saw it. Partial access is real and these cues resolve it.
6. **Coin a placeholder.** If no established term exists, name the thing explicitly as local vocabulary: "calling this the retry gate for now". Better a labeled invention than a borrowed term that carries wrong connotations.

### The pact

Once a term is agreed, freeze it. Record it in the glossary as `developer's wording → agreed term` and use the agreed term unchanged from then on. Naming something is a proposal about how to conceptualize it, and once both sides accept it, they keep referring back to it. Introducing a synonym later breaks that agreement and forces the developer to re-check whether the same thing is still meant. Elegant variation is a virtue in prose and a defect here.

If a term has to change, change it out loud: name the old one, the new one, and the reason, then update the glossary.

### Guardrail against agreement bias

Candidate sets are the fastest rung on the ladder and the easiest to abuse. A single candidate offered as a yes-or-no question mostly collects agreement, not information. So: at least two candidates, each with the difference made visible, and always an explicit way out. And when the developer confirms a term without hesitation but a later statement contradicts it, treat the term as unconfirmed again rather than the statement as inconsistent.

## Brief format

```
## Problem
One sentence. An observable state, not a solution and not a wish.

## Goal
What is observably true when this is done.

## In scope
Three to five bullets, concrete.

## Out of scope
The adjacent, tempting work that will not be done. This list is as
important as the one above, because unbounded work expands by default.

## Constraints
Stack, versions, deadline, budget, people, existing decisions that hold.

## Glossary
The developer's wording, then the agreed term, one line each:
"the part that catches the error" -> ExceptionMapper in the middleware chain.
Terms still unconfirmed are marked as such.

## Done when
Checkable criteria. Every line must map to something observable.

## Assumptions
Each with the default in force: "Assuming X, since nothing says otherwise."

## Open
[NEEDS CLARIFICATION: specific question] for each real gap. Mark them,
do not fill them with a plausible guess.
```

Drop empty sections rather than padding them. For small tasks the brief is five lines; for a migration it is a page. If it exceeds one page, the problem needs splitting, not a longer document.

## Writing acceptance criteria

A criterion that cannot fail is not a criterion. "The endpoint is secure" fails this test; "unauthenticated requests receive HTTP 401" passes it. The reliable pattern:

- **Always:** The system shall [response].
- **On an event:** When [trigger], the system shall [response].
- **While in a state:** While [state], the system shall [response].
- **On something unwanted:** If [failure condition], then the system shall [response].
- **For an optional feature:** Where [feature is present], the system shall [response].

The same structure works outside software: "When the reader finishes section 2, they can run the migration without asking a follow-up question."

If no concrete criterion can be written for a requirement, the requirement is still too vague to act on. That is a finding, not a failure, and it belongs under Open.

## Drift protocol

Target drift is normal. Working on a problem is how people discover what they actually meant. What breaks things is drift handled silently: quietly changing the target and thereby losing the original one.

When a later message contradicts the brief, name the delta in one line, then classify it:

- **Refinement.** New detail, no conflict. Update the brief and continue, no confirmation needed.
- **Pivot.** The target changed. "You started at A, this reads as B. Which one is the target?" Then rewrite the brief and re-cut the scope, because the old out-of-scope list was built for A.
- **Expansion.** New work bolted onto the existing target. Offer it as a second slice rather than growing the current one, and finish the first one.

Do not audit the drift, do not point out that the person changed their mind. Name the delta, resolve it, continue.

## Narrowing

The brief exists to make the work smaller, not to document it more thoroughly. Two habits do most of that work:

- Prefer the smallest deliverable that can be checked, and name the next slice rather than absorbing it.
- Write the out-of-scope list before the in-scope list. It is easier to see what is tempting than what is necessary, and the tempting adjacent work is what silently doubles the effort.

## Handoffs

The brief is the input for whatever comes next, so hand it over rather than restating it:

- **The framed problem turns out to be a choice between options.** Framing is done; the work is now weighing alternatives. Hand the brief to the `decision-sparring` skill, which takes the goal and constraints as its framing sentence and returns a verdict with a tipping condition. If it is not installed, the brief still supplies the context and constraints for that comparison directly.
- **The result binds several repositories, people or vendors.** It belongs in an architecture decision record. Problem, constraints and non-goals map onto the context section without rewriting.
- **The brief becomes documentation.** Goal, scope and acceptance criteria are the skeleton of a how-to or a reference page; the glossary carries straight over as terminology. The `diataxis-docs` skill decides which quadrant each part belongs in and where it gets published.
- **The brief turns wordy.** Cut it. A brief longer than one page has stopped narrowing the work and started describing it.
