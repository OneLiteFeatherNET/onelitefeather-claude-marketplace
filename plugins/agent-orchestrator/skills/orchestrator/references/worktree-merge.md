# Worktree isolation and merge

## When to use `isolation: 'worktree'`

Pass `isolation: 'worktree'` on the `Agent` call for any subtask whose worker is expected to create
or modify files. This gives the worker its own git worktree, so subtasks running concurrently can
never overwrite each other's in-progress changes.

Skip it for subtasks that are read-only — research, analysis, answering a question about the
codebase, drafting text that a later step will place into a file. These have no conflict risk, and
worktree setup has real overhead (disk, setup time) that isn't worth paying when nothing will be
written.

## Merging a successful worker's changes back

When a worktree-isolated `Agent` call succeeds (reaches `done`, not `escalated`/`blocked`), the tool
result includes the worktree's path and branch (an unchanged worktree is auto-removed instead, so
only worktrees with actual changes reach this step). Merge that branch back into the working branch
the orchestrator itself is operating on:

```bash
git merge --no-ff <worktree-branch> -m "merge: <subtask description>"
```

Use `--no-ff` so each subtask's merge stays visible as its own commit in history, rather than being
silently fast-forwarded into indistinguishable individual commits.

## A merge conflict is an escalation signal, not a retry target

If the merge produces a conflict, do not attempt to auto-resolve it and do not silently retry the
subtask at the same tier — a conflict means two subtasks weren't as independent as the decomposition
assumed, which is a decomposition problem, not a model-capability problem. Treat it the same as an
`ESCALATE` result for that subtask (record it in the state file's `tierHistory` with
`reason: "merge conflict against <branch>"`) and let the escalation protocol's normal ladder
(`references/escalation-protocol.md`) handle it — usually via recursive decomposition, since
re-running the same subtask at a stronger model won't fix an overlapping file range that a smarter
decomposition would have avoided.
