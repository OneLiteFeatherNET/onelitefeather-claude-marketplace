# Lenses

Five ways to get from a vague request to a stated problem. Pick by what arrived, not by preference. Each lens produces material for a specific part of the brief.

## Contents

1. IS / IS NOT specification (defects and anomalies)
2. Goal ladder (solution-shaped requests)
3. Artifact first (the person cannot articulate it)
4. Measure first (comparatives without a baseline)
5. Scope cut (build and write requests)
6. Anti-patterns

## 1. IS / IS NOT specification

For anything reported as broken, flaky, slow or strange. Adapted from Kepner-Tregoe problem analysis, which specifies a deviation along four dimensions before anyone proposes a cause. Its signature move is the second column: what the problem could plausibly be, but is not.

| Dimension | IS | COULD BE BUT IS NOT | Distinction |
| --- | --- | --- | --- |
| **What** | Which object shows the deviation, and what exactly is the deviation | Which similar object does not show it | What differs between them |
| **Where** | Where it appears: host, region, module, code path, screen | Where it does not appear, though it could | What differs |
| **When** | First seen, last seen, frequency, what it coincides with | When it does not occur, though conditions look the same | What differs |
| **Extent** | How many units, how far, how bad | How many are unaffected | What differs |

The distinction column is the payload. A cause that does not explain why the problem appears on the left and not on the right is not the cause.

Two rules keep this honest:

- Separate observation from inference. "The pod restarts" is an observation; "the memory limit is too low" is a hypothesis, and it belongs in a different column of thinking.
- Ask "what changed" per dimension. Most anomalies date from a change, and the change window is bounded by the When row.

Even a partial matrix is useful: the boundary alone often makes the cause obvious and always narrows the search.

## 2. Goal ladder

For requests that name a technique instead of an outcome. This is the XY problem: someone wants X, believes Y will get them there, and asks about Y. Helpers then work on Y and are confused, because Y is a strange thing to want on its own.

The move is one question, upward:

> "What does that get you downstream?"

Repeat at most three times. Each step upward opens the option space; too many steps land at "we want the company to succeed", which is unactionable.

Stop climbing when one of these is true:

- The answer names an observable outcome for someone specific
- The next step up would be outside the person's control
- The person has answered the same thing twice in different words

Two guardrails, because this lens is the easiest one to abuse:

- **Answer Y as well.** If the literal request has an answer, give it. The symbiotic form is: here is how to do Y, and if the goal is Z then W is shorter.
- **One redirect, not three.** If the person confirms Y after being asked once, work on Y. They may hold context that never made it into the message.

## 3. Artifact first

For "I don't know what I want" and for "not quite" without a reason. Recognition is far easier than specification: people who cannot describe a target can almost always judge one placed in front of them.

Techniques, in the order that usually works:

- **Examples and counterexamples.** "Show me one you like and one you do not." The gap between the two is the specification, and it is usually a short list of dimensions.
- **Cheap draft as a probe.** Produce a deliberately small version, explicitly labeled as a probe. The reaction contains more information than any question would. Keep it small so revision is cheap and no sunk cost accumulates.
- **Negative space.** "What would definitely be wrong?" People who cannot state a goal can almost always state a violation.
- **Two concrete options.** Offer A and B with a named difference, and ask which is closer. Do not offer five; the point is to force a contrast, not a survey.
- **Extreme test.** "If it were ten times faster, would you be happy?" Reveals whether the stated dimension is the one that matters.
- **Walk one case end to end.** Have them narrate a single concrete instance from start to finish. Generalities hide requirements; a specific case exposes them.

## 4. Measure first

For "better", "faster", "cleaner", "more robust". Three fields, none skippable:

1. **Current value.** What is it now, with units and with the method of measurement.
2. **Target value.** What number ends the work. "Faster" is not a target; "p95 under 200 ms" is.
3. **Method.** How the value gets measured, and whether that method exists already.

If the current value is unknown, measuring it is the first deliverable, and that is usually a smaller and more useful piece of work than the improvement itself.

If no number is available at all, fall back to a qualitative but binary criterion: a named person can do a named thing without a named workaround.

## 5. Scope cut

For build and write requests. Three lists, written in this order:

1. **Out of scope.** First, deliberately. The adjacent tempting work is easier to see than the necessary work, and unbounded work expands by default: caching layers, neighboring refactors, extra dependencies, one more chapter. Anything not explicitly excluded gets pulled in.
2. **In scope.** Three to five concrete items. If the list runs longer, the deliverable should be split into slices.
3. **Done when.** Checkable criteria, one line each.

Slicing rule: prefer the slice that produces a checkable result soonest, even if it is not the most interesting one. A checkable slice converts opinions into observations, and everything after it is cheaper to steer.

## 6. Anti-patterns

| Pattern | Why it hurts | Instead |
| --- | --- | --- |
| Question wall before any help | The person leaves with homework instead of an answer | Best reading plus stated assumptions, questions alongside |
| Silent default filling | The wrong assumption surfaces three steps later | Mark it: assumption in force, or open question |
| Paraphrasing the request away early | The misreading enters at the paraphrase and never gets caught | Keep the original wording, restate once for confirmation |
| Asking what the context answers | Signals the material was not read | Read first, then ask about the actual gaps |
| Serial questioning | Ten messages for a two-minute clarification | One batch, at most three questions |
| Confirmation questionnaire | Framing costs more than the work | One sentence to accept or reject |
| Rewriting the brief silently on drift | The original target vanishes unnoticed | Name the delta, classify it, then update |
| Framing a trivial task | Overhead exceeds the work | Just do it and stay correctable |
