# Story map, stages and prioritization

## The story map in five sentences (for game designers)

Write across the top what a player does from start to finish — "enter the round", "get equipped", "fight", "win or lose". That is the **backbone**; it is not prioritized, it is simply the order in which you would tell the story. Under each activity you hang the detail stories, most important at the top. Then you draw a horizontal line across *all* columns: everything above it is **stage 1** — a playable game in which every activity appears in its simplest form, not one finished feature. Every further line below is another stage that makes *all* activities a bit better.

## A stage is a slice, not a feature bundle

This is the most common misreading. "stage 1 = the shop, finished; stage 2 = trading, finished" is a vertical feature bundle — exactly what story mapping exists to prevent. A stage cuts **horizontally through all activities**.

**Test question:** can stage 1 ship on its own and somebody play or use it? If not, it is a feature bundle.

**Second test:** if only one or two activities appear in a stage, the cut is probably wrong.

The **Activity** column in the story table is the backbone in table form. Reuse the same activity names across all stages.

## How to cut a stage — six patterns

Meta-rule: *find the one complicated spot and reduce its variants to one.*

| Pattern | Question | Example |
|---|---|---|
| Workflow steps | Which steps can stage 1 leave out? | Round: start → fight → end first; lobby countdown, statistics and rewards later |
| Variants / rules | Which special rule can wait? | "Last one standing wins" first, then teams, comeback rule, sudden death |
| Data | Is a subset enough? | The library reads YAML first, JSON and TOML later |
| Interface | Can it work without a nice UI at first? | Chat command first, GUI inventory later; config file first, API later |
| Path | Are there several routes to the same goal? | Kit selection by command first, by sign click later |
| Performance later | "Works" first, "fast" second? | Region lookup linear at first, with a measured limit as an NFR from stage 2 |

If it is unclear *how* something could work at all, that is not a story in the table but a **time-boxed spike** — its output is a decision, not code.

## Quick check before adding a row

Four of the INVEST criteria matter here: **V**aluable, **S**mall, **T**estable, **I**ndependent.

- **Too big:** the story contains "and" or "manage"; the acceptance criterion needs more than three EARS sentences; it does not fit in one stage.
- **Technical instead of user-centred:** the "so that" describes code ("so that the service starts") rather than an effect for the role. Test: would the role notice the difference? If not, it is an enabler — do not force it into the story table.
- **Not testable:** "should run smoothly" belongs in section 5 as a measurable NFR, not in a story.

## Roles

"As a player/user" and "As a developer/operator" are defaults, not a complete list. Other common OLF roles:

| Role | Typical interest |
|---|---|
| Moderator/Admin | Abort a round, kick players, review rule violations |
| Map builder | Place spawn points and areas, run the setup flow |
| Spectator | Follow a running round without interfering |
| Content creator | Record, keep an overview, avoid spoilers |
| Server operator | Deployment, scaling, cost |

**Rule of thumb:** whoever looks at the system *differently* is a role of their own. Otherwise admin and builder stories get forgotten systematically and only surface as a gap in production.

## Stories without a user role (enablers)

Migrations, refactorings, build infrastructure and spikes have no meaningful "As a …" phrasing. They are recorded as **enablers** with ID `EN-X.NN`, may be phrased technically, and need an **"unblocks"** column listing the user story IDs that depend on them.

An enabler that unblocks no story is a candidate for deletion.

If an enabler depends on another repo (a missing feature in a shared library, say), the repo name and issue link belong in its description — otherwise the dependency stays invisible until the stage is due.

## Using MoSCoW correctly

- Priority applies **per stage**, not per project. MoSCoW without a fixed frame is worthless.
- **At most 60 % of a stage's effort may be "Must"** (the DSDM rule), and around 20 % should be "Could" — those Could items are the contingency that keeps the stage deliverable despite mis-estimation. The remainder is "Should".
- A requirements document deliberately carries no effort estimates. As a working substitute: **at most 60 % of the rows in a stage as "Must"**, adjusting when individual stories are obviously far larger than the rest. A real effort distribution belongs to planning, not to the document.
- If nearly every story is "Must", the prioritization is not what is wrong — the stories are cut too coarsely. Apply the splitting patterns above.
- **"Won't this time" gets documented, not omitted.** A separate "Won't (deliberately out of this stage)" table stops the same discussion from restarting in every review.
- Optional for game concepts: a Kano lens (basic / performance / excitement) as an extra column. Excitement features are almost never "Must".

Deliberately not used: WSJF, which needs cost-of-delay estimates that do not exist for a small product concept.

## Special case: time-boxed events

- **The date is a constraint**, not a schedule: one line in section 2 ("must be live on DD.MM. at HH:MM"). This is the only exception to "no dates in the requirements document".
- **Cut backwards from the date:** stage 1 is what *must* stand on the day. Everything else is "Won't", not "stage 2" — there usually is no second stage after the event.
- **Teardown is a backbone activity**, not an afterthought: switching off, what happens to progress and rewards, how long data is kept. Without it the backbone is incomplete.
- **Decide and write down whether it repeats:** one-off (a throwaway solution is fine) or annual (then configurability belongs in as an NFR).
- The typical event NFR is the load spike at the start — everyone arrives at once, not spread out. The capacity number differs from a steady-state product's.

## Sources

- [Jeff Patton: The New Backlog](https://jpattonassociates.com/the-new-backlog/) — backbone, narrative flow, walking skeleton
- [Humanizing Work Guide to Splitting User Stories](https://www.humanizingwork.com/the-humanizing-work-guide-to-splitting-user-stories/) — splitting patterns and the meta-pattern
- [Mike Cohn: SPIDR](https://www.mountaingoatsoftware.com/agile/five-simple-but-powerful-ways-to-split-user-stories) — spike/path/interface/data/rules
- [DSDM: MoSCoW Prioritisation](https://agilebusiness.org/dsdm-project-framework/moscow-prioritisation.html) — the 60 % rule and the priority levels
- [Bill Wake: INVEST](https://xp123.com/invest-in-good-stories-and-smart-tasks/) — the original definition
