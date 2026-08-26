# Template: requirements (product or game concept)

Role in user stories: "As a player" / "As a user". For games, events, and user-facing features. Further roles: `story-mapping.md`.

**Before filling this in:** walk the category checklist in `nfr-categories.md` once and look up the sentence forms in `ears-patterns.md`. The NFR category names are a closed list — copy them verbatim. If the document is not written in English, see `localization.md`.

Every number below is an **example of the form**, not a specification. Never copy one unchecked; an unconfirmed value belongs in section 6 as an `assumption`.

```markdown
---

**Responsibilities:** Concept: (name) · Requirements maintained by: (name)
**Document status:** Draft | In review | Signed off (YYYY-MM-DD)
**Review:** Domain side: (name) · Delivery side: (name)
**Last updated:** (date)

---

## 1. Context and background

(Short prose: problem, motivation, how this fits the wider product. When converting an existing prose document, the trimmed original belongs here.)

**Terms:** Define invented or ambiguous terms (round, match, instance) once here and use only those afterwards.

## 2. Goals and non-goals

**Goals:**
* (…)

**Non-goals:**
* (…)

## 3. Stakeholders and roles

| Role | Person | Interest |
|---|---|---|
| Player | – | Plays the round |
| Designer | (name) | Defines the rules |
| Map builder | (name) | Builds the environment, places spawn points |
| Developer | (name) | Implements the logic |
| Moderator | (name) | Aborts rounds, reviews rule violations |

## 4. Stage overview

A stage cuts across all activities; it is not a feature bundle.

| Stage | Summary | Document |
|---|---|---|
| Stage 1 | (smallest playable version) | (link once created) |

## 5. Non-functional requirements

| ID | Category | Requirement (EARS + measure) | Priority |
|---|---|---|---|
| NFR-001 | Performance & capacity | While a round with up to (N) players is running, the instance shall sustain at least 19.5 ticks per second. | Must |
| NFR-002 | Reliability & recovery | If an instance crashes, then no player progress older than 60 s shall be lost. | Must |
| NFR-003 | Security & integrity | The server shall validate movement, reach and damage server-side. | Must |
| NFR-004 | Data protection | The data service shall store only the personal fields listed in section 2. | Must |
| NFR-005 | Localization | The game shall deliver all player-facing text through translation keys. | Should |
| NFR-006 | Usability & accessibility | The scoreboard shall distinguish states by symbol or text in addition to colour. | Should |
| NFR-007 | Operations & observability | While an instance is running, it shall export tick rate, player count and heap usage as metrics. | Should |
| NFR-008 | Moderation & abuse prevention | When a player is reported, the moderation service shall retain the related chat log for 7 days. | Could |

## 5b. Maps, assets and balancing

Non-code artifacts are requirements like any other; the "system" in the EARS sentence is then the map or the asset pack.

| ID | Artifact | Requirement | Priority |
|---|---|---|---|
| MAP-001 | Map | The map shall provide (N) spawn points at least (X) blocks apart. | Must |
| RES-001 | Asset pack | Where an asset pack is active, the game shall stay playable without its contents. | Should |

**Balancing values** go in a table of their own (value, starting figure, source: decided or assumed). They are domain content, not implementation detail — but they change after playtests. Changing one needs **no new story ID**, only a change-history entry.

## 6. Open questions / risks / assumptions

Status here: `open` · `assumption` · `risk` · `resolved` · `disproved`.

| Question / risk / assumption | Owner | Status |
|---|---|---|
| (…) | (name) | open |
| (a value nobody has confirmed) | (name) | assumption |

## 7. Sign-off criteria

At least one criterion that only a playtest can satisfy.

- [ ] (describe the criterion)

## Change history

Substantive changes to requirements only, not typos.

| Date | Change | Who |
|---|---|---|
| (YYYY-MM-DD) | Document created | (name) |

---

*Uses EARS for acceptance criteria and MoSCoW per stage.*
```

## Child document per stage: "User Stories: Stage X"

```markdown
## User Stories: Stage (X) — (short name)

Priority applies to this stage. At most 60 % of the rows as "Must".

| ID | Activity | Story ("As a player I want … so that …") | Acceptance criterion (EARS) | Priority | Status |
|---|---|---|---|---|---|
| US-X.01 | (backbone activity) | As a player I want (…) so that (…) | When (…), the (…) shall (…) | Must | open |

### Enablers (no user role)

| ID | Description | Unblocks | Priority | Status |
|---|---|---|---|---|
| EN-X.01 | (technical prerequisite; name the repo and issue link if it depends on another repo) | US-X.01 | Must | open |

### Won't (deliberately out of this stage)

| Topic | Reason |
|---|---|
| (…) | (…) |
```

Story status values: `open` · `planned` · `in progress` · `done` · `dropped`.
