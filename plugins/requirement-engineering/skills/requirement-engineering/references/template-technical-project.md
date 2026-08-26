# Template: requirements (technical project)

Role in user stories: "As a developer/operator". For libraries, services, infrastructure tools. Adds an interface/API column.

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

(Short prose: problem, motivation, which other projects or repos depend on this.)

**Terms:** Define ambiguous terms (instance, service, module, registry) once here and use only those afterwards.

## 2. Goals and non-goals

**Goals:**
* (…)

**Non-goals:**
* (…)

## 3. Stakeholders and roles

| Role | Person | Interest |
|---|---|---|
| Maintainer | (name) | Owns architecture and reviews |
| Consumer | (name) | Uses the library in their own project |
| Operator | (name) | Runs the deployment |

## 4. Stage overview

A stage cuts across all activities; it is not a feature bundle.

| Stage | Summary | Document |
|---|---|---|
| Stage 1 | (smallest usable version) | (link once created) |

## 5. Non-functional requirements

| ID | Category | Requirement (EARS + measure) | Priority |
|---|---|---|---|
| NFR-001 | Compatibility & versioning | The library shall not introduce a binary-incompatible change within a MAJOR version (SemVer 2.0.0). | Must |
| NFR-002 | Compatibility & versioning | The library shall compile against (framework) version (X) and Java (N). | Must |
| NFR-003 | Security & integrity | If the configuration contains an unknown field, then the library shall abort startup with an error naming that field. | Must |
| NFR-004 | Performance & capacity | The API shall answer read requests at (N) req/s with p95 at most 200 ms. | Must |
| NFR-005 | Data protection | The service shall not write personal data or secrets to logs. | Must |
| NFR-006 | Reliability & recovery | When the service starts, it shall answer `/health` with `UP` within 5 s. | Should |
| NFR-007 | Maintainability & testability | The CI build shall fail when line coverage of the core module drops below 70 %. | Should |
| NFR-008 | Operations & observability | The service shall emit structured JSON logs with trace and span correlation. | Should |

## 6. Open questions / risks / assumptions

Status here: `open` · `assumption` · `risk` · `resolved` · `disproved`.

| Question / risk / assumption | Owner | Status |
|---|---|---|
| (…) | (name) | open |
| (a value nobody has confirmed) | (name) | assumption |

## 7. Sign-off criteria

- [ ] (describe the criterion)

## Change history

Substantive changes to requirements only, not typos.

| Date | Change | Who |
|---|---|---|
| (YYYY-MM-DD) | Document created | (name) |

---

*Uses EARS for acceptance criteria and MoSCoW per stage. Roles are developer/operator rather than end user.*
```

## Child document per stage: "User Stories: Stage X"

```markdown
## User Stories: Stage (X) — (short name)

Priority applies to this stage. At most 60 % of the rows as "Must".

| ID | Activity | Story ("As a developer/operator I want … so that …") | Acceptance criterion (EARS) | Interface/API | Priority | Status |
|---|---|---|---|---|---|---|
| US-X.01 | (backbone activity) | As an operator I want (…) so that (…) | When (…), the (…) shall (…) | (API/endpoint/config) | Must | open |

### Enablers (no user role)

| ID | Description | Unblocks | Priority | Status |
|---|---|---|---|---|
| EN-X.01 | (migration, refactoring, build infrastructure, spike; name the repo and issue link if it depends on another repo) | US-X.01 | Must | open |

### Won't (deliberately out of this stage)

| Topic | Reason |
|---|---|
| (…) | (…) |
```

Story status values: `open` · `planned` · `in progress` · `done` · `dropped`.
