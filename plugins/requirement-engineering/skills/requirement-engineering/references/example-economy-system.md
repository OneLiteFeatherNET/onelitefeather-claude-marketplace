# Worked example: an in-game economy

A filled-in excerpt in the target format. This is a real OneLiteFeather project; its own documents live in German in Outline, so the rows there read as in `localization.md` — here they are shown in the canonical English form.

[Project](https://outline.onelitefeather.dev/doc/bildungs-wirtschaftssystem-survival-aktien-spielerisches-lernen-GAzhLaApZL) ·
[Requirements (player view)](https://outline.onelitefeather.dev/doc/1-anforderungen-spielersicht-MHvUiwgSPR)

The project was the model for this standard: numbered stories, staged delivery, sign-off criteria, one child document per stage. What it lacked and the standard adds: a systematic NFR section, standalone EARS acceptance criteria instead of an implicit "so that" column, and MoSCoW instead of stage order as the only signal of priority.

The numbers below illustrate the form; they are not project specifications.

## Excerpt: main document, sections 4 and 5

### 4. Stage overview

| Stage | Summary | Document |
|---|---|---|
| Stage 0 | Currency exists, players can earn and spend | *(link once created)* |
| Stage 1 | One tradable share with a moving price | *(link once created)* |
| Stage 2 | Several shares, portfolio view, price history | *(link once created)* |

Every stage touches all backbone activities (earn → inform → trade → review) — stage 0 in the simplest form imaginable.

### 5. Non-functional requirements

| ID | Category | Requirement (EARS + measure) | Priority |
|---|---|---|---|
| NFR-001 | Performance & capacity | While up to 60 players are active on the survival server, price calculation shall take at most 5 ms per tick. | Must |
| NFR-002 | Reliability & recovery | If the server terminates unexpectedly, then no account balance older than 60 s shall be lost. | Must |
| NFR-003 | Security & integrity | The economy service shall verify funds server-side before it executes a transaction. | Must |
| NFR-004 | Usability & accessibility | The price display shall mark price movement by an arrow symbol in addition to colour. | Should |
| NFR-005 | Operations & observability | While the system is running, the economy service shall export transaction count and money supply as metrics. | Should |

## Excerpt: "User Stories: Stage 1"

| ID | Activity | Story | Acceptance criterion (EARS) | Priority | Status |
|---|---|---|---|---|---|
| US-1.01 | Inform | As a player I want to see a share's current price so that I can pick a moment to buy. | When a player uses the price board, the economy service shall show them the current price with a timestamp. | Must | done |
| US-1.02 | Trade | As a player I want to buy shares so that I benefit from price gains. | When a player confirms a purchase, the economy service shall credit the shares to their portfolio and deduct the price from their balance. | Must | in progress |
| US-1.02b | Trade | *(error case for US-1.02)* | If the player's balance is insufficient, then the economy service shall reject the purchase and state the shortfall. | Must | in progress |
| US-1.03 | Review | As a player I want to see my gain or loss so that I learn from the decision. | When a player sells shares, the economy service shall report the difference against the purchase price. | Must | open |
| US-1.04 | Inform | As a player I want to be told about large price swings so that I need not keep checking. | While a player holds shares, when the price deviates more than 20 % from their purchase price, the economy service shall notify them once. | Should | open |

### Enablers

| ID | Description | Unblocks | Priority | Status |
|---|---|---|---|---|
| EN-1.01 | Persistence layer for balances and portfolio positions | US-1.02, US-1.03 | Must | done |

### Won't (deliberately out of stage 1)

| Topic | Reason |
|---|---|
| Several tradable shares | Only after one price model has proven itself in play (stage 2) |
| Credit and leverage | Pedagogically delicate, needs its own discussion — open question in section 6 |

## What to take from this

When the shape of a section is unclear, use these rows as a pattern. Three things are deliberate:

- Every story names an **effect for the player** in its "so that", not a technical state.
- A story often needs **two** criteria: the success case and the error case (US-1.02 / US-1.02b). The error case usually carries the real rule — but it never replaces the success case.
- The enabler row is phrased technically yet points at the stories it unblocks, and "Won't" gives reasons instead of staying silent.
