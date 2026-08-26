# Writing requirements in a language other than English

English is the canonical form of this standard: section names, status values and EARS sentences as documented in `ears-patterns.md`. A project that writes in another language keeps the **structure** and translates the **surface**.

Three rules hold regardless of language:

1. **One language per document.** Mixing an English keyword into a foreign-language sentence (`When der Spieler stirbt, shall das System …`) is readable in neither and is not valid EARS either.
2. **Translate the pattern, not word by word.** The point of EARS is that a point in time, a period and a logical condition are told apart. A translation that collapses them into one word throws away the whole benefit.
3. **Keep the IDs.** `US-X.NN`, `EN-X.NN`, `NFR-001` are language-independent and are what links documents, issues and tests.

## German variant (used for OLF-internal documents)

OLF's internal project documents live in German in Outline. The complete mapping:

**EARS sentence forms** — base form `[Solange <Zustand>,] [Sofern <Feature aktiv>,] [Sobald|Falls <Auslöser>,] muss <das System> <Reaktion>.`

| Pattern | English | German |
|---|---|---|
| Ubiquitous | The \<system\> shall \<response\>. | Das \<System\> muss \<Reaktion\>. |
| Event-driven | **When** \<trigger\>, the \<system\> shall … | **Sobald** \<Ereignis\>, muss das \<System\> … |
| State-driven | **While** \<state\>, the \<system\> shall … | **Solange** \<Zustand\>, muss das \<System\> … |
| Unwanted behaviour | **If** \<condition\>, **then** the \<system\> shall … | **Falls** \<Bedingung\>, muss das \<System\> … |
| Optional feature | **Where** \<feature is active\>, the \<system\> shall … | **Sofern** \<Feature aktiv\>, muss das \<System\> … |
| Complex | **While** …, **when** …, the \<system\> shall … | **Solange** …, **sobald** …, muss das \<System\> … |

**„Wenn" is banned in German**, because it can mean all three of *sobald*, *solange* and *falls*. This three-way split matches the SOPHIST BedingungsMASTeR (FALLS / SOBALD / SOLANGE), which rejects „wenn" for the same reason. Obligation is always „muss" or „darf nicht"; „sollte" belongs nowhere in the sentence, since priority lives in the MoSCoW column.

**Section names**

| English | German |
|---|---|
| Context and background | Kontext & Ausgangslage |
| Goals and non-goals | Ziele & Nicht-Ziele |
| Stakeholders and roles | Stakeholder & Rollen |
| Stage overview | Ausbaustufen-Übersicht |
| Non-functional requirements | Nicht-funktionale Anforderungen |
| Open questions / risks / assumptions | Offene Fragen / Risiken / Annahmen |
| Sign-off criteria | Abnahmekriterien |
| Change history | Änderungshistorie |
| Maps, assets and balancing | Anforderungen an Map, Assets und Balancing |

**Terms**

| English | German |
|---|---|
| stage (release slice) | Ausbaustufe |
| activity (backbone) | Aktivität |
| user story | User Story |
| enabler | Enabler |
| acceptance criterion | Akzeptanzkriterium |
| assumption | Annahme |
| draft / in review / signed off | Entwurf / In Review / Freigegeben |

**Status values** — story: `offen` · `geplant` · `in Arbeit` · `umgesetzt` · `verworfen` (open · planned · in progress · done · dropped). Open questions section: `offen` · `Annahme` · `Risiko` · `geklärt` · `widerlegt` (open · assumption · risk · resolved · disproved).

**Story phrasing:** „Als \<Rolle\> möchte ich \<Ziel\> damit \<Nutzen\>."

## Other languages

Produce the same mapping before writing: the six sentence forms, the section names, the status values. Pin down which words mark a point in time, a period and a condition, and use only those. Record the mapping in the document itself if the project has no other place for it — an undocumented convention is one that the next author will break.
