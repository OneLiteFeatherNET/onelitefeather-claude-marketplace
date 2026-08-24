# Question catalog

Seven blocks. Do not run all of them. Select what fits the decision, and per block ask at most the two or three questions that will actually uncover something here. Bundle questions rather than dripping them one at a time.

## Contents

- A Framing: tests whether the right question is even on the table
- B Assumptions: exposes what the decision rests on
- C Alternatives: tests whether real options existed
- D Evidence and numbers: tests how load-bearing the basis is
- E Motives and biases: tests why this option looks so attractive
- F Consequences and operations: tests what happens after the decision
- G Reversibility and exit: tests the way back
- Appendix: business decisions, quality attributes, sources

## A Framing

If the question is posed wrong, the best answer does not help.

1. State the decision in one sentence: "We choose X to achieve Y under constraint Z." What sits at Y if X disappears?
2. Is this the decision or already the solution? Which problem was the solution supposed to fix, and who reported it?
3. Who actually has the problem, and how will that person notice it is solved?
4. What happens if nothing is decided? Doing nothing is an option and belongs on the list, with a price attached.
5. What forces the timing? A real deadline, a contract, an end of support, or impatience?
6. Is there an existing solution to be replaced? Why was it built that way? Anyone who does not know the original rationale cannot know what replacing it will break.
7. Which decision does this one preempt without that having been discussed?

## B Assumptions

Key assumptions check. The most productive block if there is time for only one.

1. List the assumptions under which the decision is right. At least five, unfiltered.
2. Which of them are load-bearing, meaning which single false assumption flips the decision on its own?
3. For each load-bearing assumption: where does it come from? Measurement, documentation, experience, guess, hearsay?
4. Which assumption was true two years ago and has not been rechecked since?
5. Which assumption only holds at the current order of magnitude? At what value (users, data volume, nodes, requests, cost) does it fail?
6. Which assumption concerns the behavior of other people who were never asked?
7. What would have to be true for the opposing position to be right? Is that perhaps plausible?

## C Alternatives

1. Which options were seriously examined, and which were listed to pad the table?
2. Were the alternatives measured against the same criteria as the favored option, or against different ones?
3. Is there a smaller variant delivering eighty percent of the benefit for twenty percent of the effort?
4. Is there a variant that defers the decision without getting expensive: an abstraction, a pilot, a feature flag, a time-boxed experiment?
5. If the favored option were banned by decree, what would get built instead? And why is that worse?
6. Is an option being excluded because it does not work, or because it is boring?
7. What evidence argues against the favored option, and how has it been handled so far?

## D Evidence and numbers

1. Where do the numbers in the business case or the capacity plan come from? Who said them first?
2. Which number comes from a measurement in your own system, which from a vendor datasheet, which from a blog post?
3. Was the benchmark taken under conditions resembling production (data volume, concurrent load, network, hardware)?
4. If you had to make this decision again in a year, what information would you want? Is it obtainable today, and at what cost?
5. Does the diagnosis rest on a single memorable experience, the most recent incident, or the most recent success?
6. What does the outside view say? How have comparable efforts in comparable teams typically ended, rather than how this one is supposed to end?
7. Which piece of evidence is missing, and is its absence currently being read as confirmation?

## E Motives and biases

Uncomfortable, and best answered honestly to oneself.

1. Who benefits from this decision regardless of the outcome? Learning curve, visibility, resume, budget, influence?
2. Was the option chosen because it fits, or because it is interesting? Honest answer; both are allowed, but it has to be named.
3. Was there dissent? From whom, how was it handled, and did that person go quiet afterwards?
4. If there was no dissent: was nobody asked, or did nobody want to object?
5. How much effort is already sunk, and how heavily does that effort carry the argument? Sunk cost is not an argument, but it likes to appear as one.
6. Is success in one area being read as fitness in another (vendor, tool, team, pattern)?
7. Is the decision overly cautious? Loss aversion looks like diligence from the inside and costs options.

## F Consequences and operations

1. Which quality attributes does the decision improve, which does it degrade? Walk the list in the appendix and name tradeoff points explicitly.
2. Sensitivity points: where in the design does a small change translate directly into a quality attribute? That is where outages will surface, and that is where monitoring belongs.
3. Is the base case too optimistic? Where are the costs that never show up in the estimate: migration, data transfer, training, documentation, permissions, decommissioning the old thing?
4. Is the worst case bad enough? If the worst case is "it takes two extra weeks", it has not been thought through.
5. Who gets woken at night when this breaks, and do they know about it?
6. What is the blast radius on malfunction: one service, all services, the data, the users, the invoice?
7. Who operates and updates this in eighteen months? How many people will still understand it then?
8. What is the running load: patch cadence, certificates, upstream breaking changes, operating cost, backup and restore?
9. A low-probability, high-impact event occurs (the vendor disappears, the license changes, the project gets archived, a data center fails). Then what?

## G Reversibility and exit

1. One-way door or two-way door? Reasoning in one sentence.
2. If two-way: when does it become a one-way door? At what degree of entanglement, what data volume, what point in time?
3. What does the way back cost concretely, in person-days and in downtime?
4. Has the way back ever been rehearsed, or does it exist only in documentation?
5. What data comes into existence that did not exist before, and how would it get back out? Data formats are the most common trap on exit.
6. What commitment is being entered into: contract term, notice period, public API, migration promise to users?
7. Which measurable signal ends the experiment? Without an abort criterion defined up front, nothing ever gets aborted.

## Appendix: business and product decisions

In addition to the blocks above, when the decision is not primarily technical (product, pricing, career, partnership, monetization):

1. Who pays, and for what exactly? If nobody pays: what is the currency, time, attention, reach, reputation?
2. What demand is evidenced, and by what? Expressions of interest and letters of intent are not demand.
3. What is the null hypothesis: that nobody needs this? What evidence would refute it, and is that evidence cheap to obtain?
4. What are the opportunity costs? What does not get built in the same window?
5. What is the smallest test of the riskiest assumption, and how long does it take?
6. What obligation does this create toward third parties (users, community, clients), and how long does it run?
7. For career and partnership decisions: what is the best alternative if this option disappears, and how strong is it really? Anyone who has not checked an alternative is negotiating from weakness.

## Appendix: quality attributes

For block F. Walk the list and note per attribute whether the decision raises it, lowers it, or leaves it untouched. The interesting rows are where one attribute rises and another falls.

Availability, latency, throughput, data consistency, data durability, security, privacy and regulatory compliance, modifiability, testability, observability, operability, recoverability, scalability, portability and vendor independence, cost, onboarding effort, accessibility.

## Sources

- Kahneman, Lovallo, Sibony: Before You Make That Big Decision, Harvard Business Review, June 2011. The twelve-question decision quality checklist, distributed across blocks C, D and E.
- Heuer, Pherson: Structured Analytic Techniques for Intelligence Analysis. Key assumptions check (block B), premortem analysis and structured self-critique, devil's advocacy, what-if analysis, high impact/low probability analysis (block F).
- Kazman, Klein, Clements: ATAM, Software Engineering Institute. Quality attributes, sensitivity points, tradeoff points, risks and non-risks (block F and the verdict format).
- Bezos: type 1 and type 2 decisions, one-way and two-way doors. Scaling the depth of review (block G).
