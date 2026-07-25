---
name: orchestrator
description: Decomposes a complex, multi-step task into independent subtasks and delegates each one via the Agent tool to the cheapest model tier likely to succeed (haiku, then sonnet, then opus), escalating a subtask to the next tier only when it reports being out of its depth or its result looks implausible. Use this proactively whenever a task clearly breaks down into independent, delegable pieces of varying difficulty. Do not use it for a single-shot edit, a simple question, or a task that's inherently sequential and tightly coupled step-to-step. An explicit manual trigger is also available: /agent-orchestrator:run.
---

# Agent Orchestrator

Turns a complex, multi-step task into a delegation pipeline: decompose into independent subtasks,
delegate each to the cheapest model tier likely to succeed, escalate only the subtasks that actually
need a stronger model. The point is to reserve expensive reasoning for the pieces that need it, not
to run everything on the biggest model available.

## When to use this

Use it proactively when a task decomposes into pieces that:

- are **independent** of each other (don't need to see each other's intermediate state), and
- vary in expected difficulty, so routing them all to the same model tier would either overpay for
  the easy ones or under-serve the hard ones.

Do **not** use it for a single-shot edit, a simple question, or a task that's inherently sequential
and tightly coupled step-to-step (each step needs the previous step's live context) — decomposition
would just add overhead with no benefit. Do the work directly in those cases.

An explicit manual trigger is also available: `/agent-orchestrator:run <task description>`, for cases
where this skill's own judgment doesn't fire but the user wants orchestration anyway.

## Core loop

1. **Decompose** the task into subtasks that are independent and appropriately small — see
   "Decomposition guidance" below.
2. For each subtask, **create tracking**: a state entry (`references/state-file.md`) and a matching
   `TaskCreate` entry, so the user sees live progress alongside the orchestrator's own bookkeeping.
3. **Delegate** each subtask via the `Agent` tool, starting at the cheapest tier likely to succeed
   (default: `haiku`), using `isolation: 'worktree'` for any subtask that touches files (see
   `references/worktree-merge.md`).
4. **Apply the escalation protocol** (`references/escalation-protocol.md`) to every result — retry at
   the next tier when a subtask reports it's out of its depth or the result looks implausible.
5. On a subtask's completion, **merge** its worktree branch back (`references/worktree-merge.md`) and
   update both the state file and its `TaskCreate` entry.
6. Once every subtask has resolved (completed, or handed back unresolved per the escalation
   protocol's ceiling), **summarize** outcomes to the user — call out by name any subtask that
   couldn't be resolved through delegation and was handed back.

## Decomposition guidance

Good subtasks are the actual point of this skill, not an afterthought:

- **Independent**: a subtask shouldn't need another subtask's intermediate output to start. If B
  genuinely depends on A's result, either sequence them explicitly (run A, then decompose B using A's
  actual output) or fold them into one subtask — don't fake independence.
- **Small enough for a small model**: prefer several narrowly-scoped subtasks over one broad one.
  "Add input validation to the three handlers in `api/users.go`" beats "improve the API" — the latter
  is a planning task in disguise, not something haiku or sonnet can execute reliably.
- **Self-contained context**: because subtasks are delegated to fresh `Agent` calls (which don't see
  this conversation), each subtask's prompt must carry everything its worker needs — the relevant
  file paths, the acceptance criteria, and any constraints from the original task. A worker that has
  to guess context is a worker that escalates unnecessarily.

## Delegating a subtask

Every worker prompt gets the escalation-protocol addendum from `references/escalation-protocol.md`
appended, so the worker knows how to signal it's out of its depth instead of guessing.

File-mutating subtasks pass `isolation: 'worktree'`; read-only/analysis subtasks omit it (no
conflict risk, and per-agent worktree setup has real overhead that isn't worth paying for a subtask
that changes nothing).

## Further reference

- `references/escalation-protocol.md` — the model ladder, the `ESCALATE` contract, the plausibility
  heuristic, and what happens when a subtask exhausts the ladder.
- `references/state-file.md` — the state-file schema, its `.gitignore`-safety requirement, and how it
  relates to `TaskCreate` entries.
- `references/worktree-merge.md` — when to use worktree isolation and how to merge a worker's branch
  back.
