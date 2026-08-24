# Term finding

How to resolve a missing technical term by elicitation rather than by supplying one. The ladder is the operational part; the background explains why the rungs are ordered this way, which matters when a situation does not match any of them exactly.

## Contents

1. Why paraphrasing is the risk
2. Reading the circumlocution
3. The ladder, rung by rung
4. Fixing the term: the pact
5. Failure modes
6. Sources

## 1. Why paraphrasing is the risk

Word production runs in stages: the concept comes first, then the lexical entry, then its sound form. The stages can come apart, which is why someone can hold a concept fully and still not reach the word for it. Circumlocution is what a speaker does with that gap, and it is a competent move, not a lapse. The concept is intact and usually accurate.

So the missing word is not the problem. The problem is what a listener does with the description. Restating "the part that catches the error before it reaches the user" as "the exception handler" resolves an ambiguity by fiat: it could be an exception mapper, a middleware, a circuit breaker, an error boundary, a dead-letter queue, or a catch block. One reading gets picked, nothing marks it as a pick, and everything downstream inherits it. The later confident-sounding detail comes from that first uncontested substitution, not from the original gap.

Two consequences for how to work:

- **The description is evidence and stays in the record.** Its ambiguity is information: it says which distinctions the developer has not yet drawn, and those are exactly the ones worth asking about.
- **Repair is preferably left to the person who has the knowledge.** Across languages, conversation shows a strong preference for the speaker of the trouble source to fix it themselves after someone signals trouble. The listener marks the gap; the speaker fills it. Supplying the term yourself is the last resort, not the first move, because it is the move most likely to install a wrong term that nobody afterwards feels entitled to challenge.

## 2. Reading the circumlocution

Signals that a term is missing rather than merely omitted:

| Signal | Example |
| --- | --- |
| Placeholder noun plus relative clause | "the thing that collects the requests", "das Ding, das die Requests sammelt" |
| Function instead of name | "the part that retries the failed jobs" |
| Approximation with a hedge | "kind of a queue, but not really", "sowas wie ein Proxy" |
| Analogy to a different domain | "like a bouncer in front of the database" |
| Self-interruption and restart | "you know, the ... how do you call it ..." |
| Deixis without a referent | "that thing there in the config" |
| Explicit appeal | "keine Ahnung wie das heißt" |

The description also tells you which rung to start on. If it names a location ("in the config"), start with pointing. If it names a function ("retries failed jobs"), the feature grid is already half filled and a candidate set is often reachable in one step.

## 3. The ladder, rung by rung

Climb only as far as needed, and stop as soon as the referent is unambiguous. Every rung upward saves the developer effort and costs a little accuracy, because the further up you go, the more of the answer comes from you.

### Rung 1: point at it

"Which file, which line, which log line, which screen?"

An artifact settles the reference completely and instantly, and it costs the developer nothing to produce, since finding a thing is easier than naming it. Whenever code, a config, a log or a screenshot is within reach, this rung beats every question below it. It also stops the conversation drifting further from the thing itself, which is the risk when both sides keep working on the description rather than the referent.

### Rung 2: mark the gap

Repeat their own phrase back with the hole left visible: "the part that catches the error, what is that in the code?"

This signals trouble without prescribing an answer, so the developer supplies the term and nothing gets pre-committed. It is the highest-yield rung per unit of effort and the one most often skipped.

### Rung 3: feature grid

Ask along fixed dimensions instead of asking for the word. Adapted from semantic feature analysis, a naming therapy that elicits a target's category, use, action, properties, location and associations to activate the surrounding conceptual network rather than pushing harder at the word itself.

| Dimension | Question |
| --- | --- |
| Category | Is it a library, a service, a config setting, a pattern, a piece of hardware, a role? |
| Function | What does it do when it runs? |
| Position | What sits before it, what sits after it? |
| Input and output | What goes in, what comes out? |
| Trigger | What makes it act: a request, a timer, an event, a failure? |
| Owner | Who wrote it, who operates it, who calls it? |
| Contrast | What is it definitely not? Which similar thing has it been confused with? |

Three or four filled rows usually identify the referent even when the word never appears. Then rung 4 becomes a formality, or the grid itself becomes the glossary entry.

Do not run all seven. Pick the two or three that discriminate here.

### Rung 4: candidate set

Offer two to four named terms, each with one line saying what distinguishes it, plus an explicit "none of these".

Recognizing a term is far easier than producing one, which is what makes this rung fast. What makes it risky is that a confidently offered term tends to get accepted, so the design matters:

- **Never a single candidate as a yes-or-no question.** That collects agreement, not information.
- **Make the difference visible.** "Circuit breaker (stops calling after N failures) or retry with backoff (keeps calling, more slowly)?" Without the differentiator the developer is choosing a word, not a concept.
- **Always an exit.** "None of these" or "closer to something else" has to be a listed option, not something the developer has to volunteer against the grain.
- **Do not rank the candidates.** Presenting a favorite makes it the default answer.

### Rung 5: partial cues

For the state where the developer knows the word and cannot reach it: strong feeling of knowing, blocked retrieval. Partial access is genuine here. People in this state can report the first letter, the approximate length and similar-sounding words above chance, so the useful prompts are:

- First letter or first syllable
- One word or two, hyphenated, an acronym?
- Vendor product, open source project, or a general concept?
- Where did you last see it: a talk, a README, a colleague, an error message?
- What sounds similar but is wrong?

A correct first syllable helps retrieval; a wrong one interferes. So offer cues, do not assert them: "does it start with a K?" rather than "you mean Kafka".

### Rung 6: coin a placeholder

If the thing has no established name, or the developer has built something without one, name it explicitly as local vocabulary: "calling this the retry gate for now, since it is not a circuit breaker."

A labeled invention is safer than a borrowed standard term, because a borrowed term drags its own connotations along and an invented one is transparently local. Record it in the glossary like any other entry.

## 4. Fixing the term: the pact

Naming a thing is a proposal about how to conceptualize it, one the other side may accept or reject. Once accepted, both sides keep referring back to that shared naming and communication gets cheaper: fewer words, fewer turns, less checking.

Practical consequences:

- **Keep the agreed term unchanged.** Every synonym forces the developer to check whether the same thing is still meant. In prose, varying your vocabulary is a virtue; here it is a defect.
- **Prefer the developer's term where it works.** If their wording is unambiguous and correct enough for the task, adopt it rather than upgrading it to canonical vocabulary. Corrections that buy nothing cost goodwill.
- **Change terms out loud.** "We have been saying retry gate; in the Resilience4j docs this is a circuit breaker, switching to that." Then update the glossary.
- **The pact is local and temporary.** It holds for this problem, not forever. When the context changes, the naming may need to change with it, which is fine as long as the change is announced.

## 5. Failure modes

| Failure | Why it hurts | Instead |
| --- | --- | --- |
| Silent upgrade to canonical vocabulary | A guess enters the record unmarked and everything downstream inherits it | Propose it, get confirmation, write it in the glossary |
| Vocabulary correction as a side effect | The developer learns that imprecise phrasing gets corrected and starts self-censoring | Correct only where the ambiguity actually costs something |
| Single candidate as a yes-or-no question | Mostly collects agreement | Two to four candidates with differentiators plus an exit |
| Interrogating the term when the artifact is right there | Slow and less reliable than looking | Rung 1 first |
| Term drift across the conversation | Nobody can tell whether the same thing is still meant | One agreed term, changes announced |
| Grilling for a word the developer plainly does not have | Pressure does not produce vocabulary | Move up the ladder or coin a placeholder |
| Talking about the description instead of the thing | Both sides drift further from the referent with every turn | Back to the artifact |

## 6. Sources

- Levelt: stages of speech production (concept, lexical entry, sound form). Explains why a concept can be intact while the word is not reachable.
- Brown and McNeill 1966, and the later tip-of-the-tongue literature: partial access to first letter, length and similar-sounding words above chance; first-syllable cues help, wrong ones interfere. Basis for rung 5.
- Boyle and Coelho: semantic feature analysis, eliciting category, use, action, properties, location and association instead of pushing at the word. Basis for rung 3.
- Schegloff, Jefferson, Sacks 1977, and the cross-linguistic repair literature: preference for self-repair, and the escalation from open trouble signals through targeted questions to candidate understandings. Basis for the ladder's ordering and for rung 2.
- Brennan and Clark 1996: conceptual pacts and lexical entrainment, partner-specific agreements on how to name a referent, which reduce collaborative effort as long as they hold. Basis for section 4.
- Tarone: communication strategies for lexical gaps, including circumlocution, approximation, coinage and appeal for assistance. Basis for section 2.
