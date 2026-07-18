# A/B test tasks (run identically for baseline & serena)

Goal: tasks that require **retrieval** — exactly where Serena shines. Run each task
in a **fresh session** (`/clear` or restart) and on the **same git state**
(`git reset --hard && git clean -fd`). Do 3–5× per condition so non-determinism
averages out.

Phrase the task **word-for-word identically** in both conditions. Copy the prompt
verbatim from this file.

---

## T1 — Locate
> Find out where <feature X> is handled in the project, and name the responsible
> class/method with file and line. Change nothing.

## T2 — References / impact
> I want to rename the method <Foo.bar()>. Show me ALL places that call or override
> it, project-wide — including calls from other modules.

## T3 — Explain a subsystem
> Explain in 10 sentences how subsystem <Y> works and which other parts it relates
> to. No file dumps, only the relevant symbols.

## T4 — Dependency usage (JVM-specific)
> How does our code use the <Lib Z> API (e.g. Paper/Adventure)? Show the concrete
> call sites and what the called methods do according to their JavaDoc.

## T5 — Small end-to-end change
> Add <small, well-scoped feature> and adjust the affected tests.

---

### Important for the evaluation
- **Record correctness:** for each run note whether the result was factually correct
  (yes/no). Fewer tokens with a wrong solution does NOT count as a win.
- **Was Serena actually used?** Check in the dashboard/report whether
  `mcp_server=serena` calls appear. If it's 0, the routing isn't taking effect — then
  it isn't Serena that's bad, but the CLAUDE.md instruction is missing/not applied.
