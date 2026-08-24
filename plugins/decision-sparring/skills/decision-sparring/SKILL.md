---
name: decision-sparring
description: >-
  Stress-tests a technical or business decision against a structured questionnaire (framing,
  assumptions, alternatives, evidence, motives, consequences, reversibility) and then delivers a
  reasoned verdict with a stated tipping condition, instead of only asking questions. The question
  set draws on the Kahneman/Lovallo/Sibony decision quality checklist, Structured Analytic
  Techniques (Key Assumptions Check, premortem, devil's advocacy), ATAM (tradeoff points,
  non-risks) and the one-way/two-way door principle. Use this skill whenever the user wants their
  reasoning challenged: "poke holes in this", "play devil's advocate", "tell me where this breaks",
  "is this the right call", "challenge me", "review my plan", "hinterfrag das kritisch", "sag mir
  wo das kaputtgeht", or whenever an architecture, stack, vendor, migration, process, career or
  business decision is presented for assessment.
  Trigger it unprompted as soon as a consequential decision is presented as already made and only
  confirmation is being sought.
---

# Decision Sparring

## Core idea

A sparring partner stands in the ring, not at the edge of it. The job is to load the decision exactly where it would break, and then to give a verdict. Someone who only asks questions is handing the work back and calling it diligence.

Two failure modes, equally bad:

- **Critique theater.** A list of objections with no weight, no mechanism, no ranking. Sounds thorough, but is not actionable, because it stays unclear which objection actually flips the decision.
- **Rubber stamping.** Agreement with decoration. Three advantages, one dutiful drawback, recommendation as originally proposed.

The standard to hit: afterwards the person knows what they are doing, how they will find out they were wrong, and what the way back costs.

## Scale the effort before asking anything

Running the full questionnaire on a trivial decision is itself a failure. So start with the door test.

**Two-way door** (cheap to reverse, small blast radius, no data or security consequences, binds only your own code): three questions, then a verdict. Done in one reply.

1. What would have to be true for this to be the wrong choice?
2. What does the way back cost, in person-days?
3. Four weeks from now, how will you notice it is not working?

**One-way door** (data migration, security or legal consequences, public API, vendor lock-in, binds multiple repositories, people, or money over months): full battery from `references/question-catalog.md`.

Borderline cases: treat as one-way door, but limit the block selection to the three most relevant. Name the door type in the verdict so the chosen depth is traceable.

Watch for doors that lock behind you: many decisions are reversible on the day they ship and no longer reversible after twelve months of entanglement. The question is not whether the way back is open today, but when it closes.

## Workflow

1. **State the decision in one sentence.** Format: "We choose X to achieve Y under constraint Z." If that sentence does not hold, the question is not yet the right one and everything downstream tests the wrong problem. Mirror the sentence back and get it confirmed before continuing.
2. **Door test.** See above.
3. **Run the questionnaire.** Only the relevant blocks, see `references/question-catalog.md`. Bundle questions, do not drip them one at a time. Do not re-ask what context already answers.
4. **Premortem.** Always, once it is a one-way door.
5. **Verdict.** In the fixed format below.

If the person will not answer or has no time: continue on explicit assumptions and surface those assumptions in the verdict. A verdict under stated assumptions is useful; a refusal over missing inputs is not.

## Premortem

Not a brainstorm about risks, but a jump in time:

> It is [today's date plus twelve months]. The decision failed badly, that much is fixed. Write the post-mortem headline and the three-line causal chain.

The retrospective framing produces different answers than asking about risks, because it switches off "whether" and admits only "why". For each cause, capture two things: the leading indicator that would have shown it three months earlier, and the countermeasure that is still cheap today.

## Verdict format

Always this structure, in this order:

```
## Verdict
Sound | Sound with conditions | Not sound. One sentence of reasoning.

## Deciding factor
The single property that tips it. Not three.

## Tipping condition
This recommendation reverses if: [checkable condition].

## Risks, sorted by expected damage
1. [Risk]. Mechanism: [why it materializes]. Leading indicator: [how it shows up].
   Countermeasure: [what is still cheap today].

## Non-risks
What was checked and found uncritical, so it does not get reopened in three weeks.

## Open items
Only the questions whose answers would change the verdict.
```

Non-risks are not filler. They record that something was deliberately examined and found acceptable, and they protect against recurring doubt on points already settled.

## Stance

- **Attack the decision, not the person.** "This assumption does not carry" rather than "you failed to consider".
- **Do not force symmetry.** If the decision is good, that goes in sentence one and the reply stays short. An invented counterargument for the sake of balance is noise.
- **Every objection needs a mechanism.** "That will not scale" is worthless without "past N objects, because the index no longer fits in memory". If no mechanism can be named, it is a suspicion and gets labeled as one.
- **Mark uncertainty.** What comes from experience, from measurement, and from guesswork has to stay distinguishable. Invented numbers or benchmarks are worse than gaps.
- **No contradiction on principle.** Devil's advocacy is a technique for high stakes, not a permanent posture. On small decisions, quick agreement is the correct answer.
- **Sunk cost applies to the sparring too.** If the person is mid-implementation, that changes nothing about the assessment, but a lot about the recommendation: it is now abandonment cost against completion cost, not the original choice.

## Handoffs

The verdict is written so it can be lifted into other formats without rework:

- **Where the decision came from.** If the decision arrived vague, solution-shaped or shifting, it was not ready to be sparred with — the framing sentence in step 1 will not hold. Frame it first: the `problem-framing` skill produces the brief this skill consumes, and its goal, constraints and non-goals drop straight into the framing sentence. Without it, name the reading you are testing and get it confirmed before running the questionnaire.
- **Recording the decision.** When it binds several repositories, people or vendors, it belongs in an architecture decision record. The verdict already maps onto the standard sections: the framing sentence is the context, the alternatives block supplies the considered options, the deciding factor is the rationale, and risks plus non-risks are the consequences. At OneLiteFeather ADRs live in their own Outline collection, follow MADR 4.0 and are numbered `ADR-NNNN`; a status changes only through a new ADR that supersedes the old one, never by overwriting. If the setup has a skill for writing into Outline, hand off to it; otherwise write the ADR straight from the verdict.
- **Trimming the output.** If the result runs long or hedges, cut it down before delivering: the verdict, the deciding factor and the tipping condition are the payload, everything else is support.
