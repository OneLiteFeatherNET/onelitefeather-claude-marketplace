# EARS patterns

EARS (Easy Approach to Requirements Syntax, Mavin et al., IEEE RE'09) gives acceptance criteria a fixed sentence shape so they become testable instead of interpretable.

**Base form:** `[While <state>,] [Where <feature is active>,] [When|If <trigger>,] the <system> shall <response>.`

**Formal rule:** any number of state clauses, **at most one** trigger clause, **exactly one** named system, at least one response.

Writing in another language: keep the structure, translate the surface — see `localization.md`.

## The six patterns

| Pattern | Keyword | Template | Example |
|---|---|---|---|
| Ubiquitous (always applies) | – | The \<system\> shall \<response\>. | The phase manager shall record every phase change with a timestamp. |
| Event-driven (point in time) | WHEN | **When** \<trigger\>, the \<system\> shall \<response\>. | When the last member of a team dies, the game logic shall mark that team as eliminated. |
| State-driven (period of time) | WHILE | **While** \<state\>, the \<system\> shall \<response\>. | While the waiting phase is running, the server shall display the remaining wait time to every player. |
| Unwanted behaviour (error case) | IF/THEN | **If** \<condition\>, **then** the \<system\> shall \<response\>. | If the configuration file contains an unknown field, then the library shall abort startup with an error naming that field. |
| Optional feature | WHERE | **Where** \<feature is active\>, the \<system\> shall \<response\>. | Where ELO-based balancing is enabled, the matchmaker shall distribute teams by ELO rating. |
| Complex (combined) | WHILE + WHEN | **While** \<state\>, **when** \<trigger\>, the \<system\> shall \<response\>. | While a round is active, when a player crosses the world border, the game logic shall return them to the spawn point. |

The subject stands **before** `shall`, never after it. `When <condition>, shall <system> <behaviour>` is not EARS.

## Prohibitions and limits

Not every requirement describes an action. Permitted response forms:

| Kind | Form | Example |
|---|---|---|
| Action | shall \<do\> | The game logic shall respawn the player. |
| Prohibition | shall not \<do\> | The service shall not write player data to logs. |
| Upper bound | shall use at most … | The instance shall use at most 2 GiB of heap. |
| Lower bound | shall sustain at least … | The instance shall sustain at least 19.5 ticks per second. |

`shall` and `shall not` express obligation, not priority. A `should` inside the sentence is always wrong — priority lives only in the MoSCoW column.

## Where the method stops

Beyond **more than three** clauses in total (state plus trigger), or with combinatorial logic, do not force an EARS sentence — write a decision table and link to it from the criterion. Conveying a requirement's meaning is worth more than pressing it into a template.

## Common mistakes

| Wrong | Why | Right |
|---|---|---|
| "When the player dies, shall be respawned." | Passive, no acting system named | "…, the game logic shall respawn the player." |
| "…, the system shall store the score and update the sidebar and notify the team." | Three requirements in one sentence, not individually testable | Three criteria with their own IDs |
| "The system shall store the score if the player dies." | Condition trailing — readers skip it | Condition first |
| "The system should respond quickly." | "should" is a wish, "quickly" is not measurable | "…, the server shall respond within 3 ticks." |
| "The system shall use a ConcurrentHashMap." | Prescribes a solution instead of a requirement | Describe observable behaviour |
| "The system shall …" in a document about the game logic | "the system" is the default catch-all for "I don't know who" | Name the actual subsystem and name it consistently |
| Mixing an English keyword into a foreign-language sentence | Valid in neither language | One language per document (`localization.md`) |

## Testability check

Check each criterion on its own (following ISO/IEC/IEEE 29148:2018):

1. **One actor** — is a concretely named system or subsystem attached to the obligation, with no passive and no bare "it"?
2. **One behaviour** — exactly one requirement, no "and also"?
3. **Observable** — can a test see from the outside whether it happened (message, state, log, API response)?
4. **Measurable** — does every time, quantity or size come with a number and a unit, no weasel words? For yes/no properties: is the check unambiguous?
5. **Trigger unambiguous** — when/while/if/where chosen correctly, and can the trigger be reproduced?
6. **Solution-free** — does it describe *what*, not *how*?

Closing question: **"What would the test look like that disproves this?"** If there is no answer, the criterion is not testable.

## Sources

- [alistairmavin.com/ears](https://alistairmavin.com/ears/) — the official EARS templates for all six patterns
- [EARS on Wikipedia](https://en.wikipedia.org/wiki/Easy_Approach_to_Requirements_Syntax) — generic syntax, formal rule, limitations
- [QRA: When not to use EARS](https://qracorp.com/when-not-to-use-ears/) — EARS is meant for zero to three preconditions
