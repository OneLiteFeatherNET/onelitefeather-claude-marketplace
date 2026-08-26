# Non-functional requirements: categories and measurability

## The rule

**No NFR without a check criterion.** "The server should be performant" is a wish, not a requirement. Every NFR needs either a measure with a unit and a condition — or, for yes/no properties, a criterion that can be decided unambiguously.

If the number is missing because nobody knows it yet, record it in section 6 as an assumption or open question — do not phrase it vaguely.

Formally this is the one part EARS does not bring along: the SEI *Quality Attribute Scenarios* consist of source, stimulus, artifact, environment, response and **response measure**; EARS already covers the first five. Only the response measure is adopted, as a mandatory element — a second sentence format is deliberately not introduced.

## Category checklist

Ten categories derived from ISO/IEC 25010:2023 and trimmed to what small product teams actually need. When writing a requirements document, **walk every row once** and decide: relevant → write an NFR, or explicitly "not relevant".

The names in the "category" column are a **closed list** — use exactly this spelling in the NFR table so categories stay comparable across projects.

| ISO/IEC 25010:2023 | Relevant? | Category | Example NFR |
|---|---|---|---|
| Functional Suitability | No — lives in the user stories | – | – |
| Performance Efficiency | **Always** | Performance & capacity | While a round with up to 24 players is running, the game instance shall sustain at least 19.5 ticks per second. |
| Reliability | **Always** | Reliability & recovery | If a game instance crashes, then the orchestrator shall provide a replacement instance within 60 s. |
| Security | **Yes** | Security & integrity | The game server shall validate movement, reach and damage server-side. |
| Security → confidentiality | **For player data** | Data protection | If a user requests deletion, then the data service shall remove their personal data within 30 days. |
| Interaction Capability (incl. *inclusivity*) | **For game concepts** | Usability & accessibility | The scoreboard shall distinguish states by symbol or text in addition to colour. |
| Flexibility → adaptability | **Yes** | Localization | The application shall deliver all user-facing text through translation keys. |
| Compatibility + Flexibility → replaceability | **For libraries** | Compatibility & versioning | The library shall remain binary compatible within a MAJOR version (SemVer 2.0.0). |
| Maintainability | **For libraries/backends** | Maintainability & testability | The CI build shall fail when line coverage of the core module drops below 70 %. |
| Maintainability → analysability | **Always** | Operations & observability | While an instance is running, it shall export throughput, active users and heap usage as metrics. |
| *(no ISO counterpart)* | **For multiplayer** | Moderation & abuse prevention | When a user is reported, the moderation service shall retain the related chat log for 7 days. |
| Safety | No — aims at harm to people or property | – | – |

Observability and localization have no characteristic of their own in ISO 25010 (they fall under analysability and adaptability). That is precisely why this list is not a one-to-one copy of the standard.

**Easiest to forget and almost always relevant:** fairness/anti-cheat, recovery after a crash, observability, localization, moderation, accessibility, and data protection for player data (often minors).

## Vague → measurable

Each row is exactly **one** requirement. Where two things belong together, they appear as two NFRs with their own IDs.

| Vague phrasing | Measurable version |
|---|---|
| "The server should be performant." | While a round with up to 24 players is running, the game instance shall sustain at least 19.5 ticks per second (mean tick duration at most 51 ms). |
| "No lag while playing." | While a round is running, server-side processing latency for a player action shall be at most 50 ms (p95). |
| "Lots of players should be able to join." | The game instance shall serve 24 concurrent players without violating the tick-rate limit in NFR-001. |
| "The server should not use too much RAM." | While a round is running, the game instance shall use at most 2 GiB of heap. |
| *(same topic, second requirement)* | A full GC of the game instance shall take at most 200 ms. |
| "Instances should start quickly." | When the orchestrator starts an instance, that instance shall accept players within 15 s. |
| "Worlds should load fast." | When a player enters a map, the world service shall have loaded the spawn area within a radius of 5 chunks within 2 s. |
| "The game should be fair." | The game server shall validate movement, reach and damage server-side. |
| *(same topic, second requirement)* | The game server shall not accept a client-reported hit decision without validation. |
| "Crashes should not be a big deal." | If a game instance terminates unexpectedly, then no player progress older than 60 s shall be lost. |
| *(same topic, second requirement)* | If a game instance terminates unexpectedly, then the network shall move the affected players to the lobby within 30 s. |
| "The API should be fast." | The REST API shall answer read requests at 50 req/s with p95 at most 200 ms. |
| "We do not want to break anyone." | The library shall not introduce a binary-incompatible change within a MAJOR version (SemVer 2.0.0). |
| "Well tested." | The CI build shall fail when line coverage of the core module drops below 70 %. |
| "The service should boot quickly." | When the service starts, it shall answer `/health` with `UP` within 5 s. |

Every number in this table is an **illustrative example of the form** — never copy one into a real document unchecked. If nobody knows the right value, it belongs in section 6 as an open question.

## Sources

- [ISO/IEC 25010:2023](https://www.iso.org/standard/78176.html) — product quality model, 2nd edition 2023 (Safety added, Usability → Interaction Capability, Portability → Flexibility)
- [Sonar: ISO/IEC 25010 explained](https://www.sonarsource.com/resources/library/iso-iec-25010-explained/) — sub-characteristic lists (secondary source)
- [SEI: Quality Attribute Workshops, 3rd Edition](https://insights.sei.cmu.edu/documents/716/2003_005_001_14249.pdf) — the six-part scenario format including the response measure
- [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/) — accessibility in games
- [SemVer 2.0.0](https://semver.org/) — what each version position promises
- [Minecraft Wiki: Tick](https://minecraft.wiki/w/Tick) — 20 TPS corresponds to 50 ms per tick; tick duration (MSPT) is the usual measure

The sub-characteristics of Reliability, Security, Maintainability and Flexibility come from secondary sources and were not verified against the standard's text.
