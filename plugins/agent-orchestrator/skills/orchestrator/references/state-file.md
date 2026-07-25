# State file

## Purpose

Tracks per-subtask orchestration detail that `TaskCreate` doesn't model — which model tier a
subtask is currently on, its full escalation history, and where its worktree lives — so that a
subtask's outcome (see `references/escalation-protocol.md`) can be reconstructed and reported even
after several retries. `TaskCreate`/`TaskUpdate` entries mirror the same subtasks for the
user-facing task list; the state file is the orchestrator's own bookkeeping, not a replacement for
it.

## Location and the `.gitignore` requirement

`.claude/agent-orchestrator/state/<run-id>.json`, one file per orchestration run.

**Before writing this file for the first time in a project, check whether
`.claude/agent-orchestrator/` (or a covering pattern like `.claude/`) is already excluded by the
project's `.gitignore`. If not, append `.claude/agent-orchestrator/` to `.gitignore` (creating the
file if the project has none) before creating the state file.** This check runs once per project, not
once per run — if a previous run already added the entry, skip re-adding it. This is a hard requirement:
a plugin whose own scratch state ends up committed to the repo it's orchestrating work
in directly contradicts its purpose.

## Schema

```json
{
  "runId": "2026-07-25T14-30-00-fix-api-validation",
  "task": "Add input validation to every handler in api/",
  "startedAt": "2026-07-25T14:30:00Z",
  "subtasks": [
    {
      "id": "subtask-1",
      "description": "Add validation to api/users.go handlers",
      "status": "done",
      "currentTier": "sonnet",
      "tierHistory": [
        {
          "tier": "haiku",
          "outcome": "escalated",
          "reason": "ESCALATE: needs to cross-reference the shared validation package's error format"
        },
        { "tier": "sonnet", "outcome": "done", "reason": null }
      ],
      "worktree": { "path": "/tmp/.../worktree-subtask-1", "branch": "orchestrator/subtask-1" },
      "resultSummary": "Added validation to CreateUser/UpdateUser/DeleteUser handlers using the shared validator package."
    }
  ]
}
```

Field meanings:

- `status` — one of `pending`, `in_progress`, `escalated`, `blocked`, `done`, `failed`.
- `currentTier` — the tier the subtask is presently running at (or most recently completed at).
- `tierHistory` — append-only log, one entry per attempt, in the order attempted. `outcome` is
  `escalated`, `done`, or `failed`; `reason` is the `ESCALATE` text or heuristic observation that
  triggered the next tier, `null` on the entry that finally succeeded.
- `worktree` — `null` for subtasks that never used `isolation: 'worktree'` (read-only/analysis
  subtasks); otherwise the path/branch the `Agent` tool returned, kept until the merge step
  (`references/worktree-merge.md`) completes.
- `resultSummary` — a short human-readable summary of the outcome, written once the subtask reaches
  a terminal status (`done`, `blocked`, or `failed`).

## Relationship to `TaskCreate`

Each subtask gets one `TaskCreate` entry, created alongside its first state-file entry, with
`TaskUpdate` calls mirroring `status` transitions (`in_progress` when a tier attempt starts,
`completed` when the subtask reaches `done`). The state file is the source of truth for tier/escalation
detail; `TaskCreate` is the source of truth for what the user sees in the harness's task list. Keep
them in sync, but don't try to cram tier history into `TaskCreate`'s content — that's what the state
file is for.
