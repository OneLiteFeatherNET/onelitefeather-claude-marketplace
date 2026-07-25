# Escalation protocol

## The ladder

`haiku → sonnet → opus → fable`, in that fixed order. The first three steps are a plain
retry-at-next-tier chain. `fable` is never used silently — it requires an explicit
`AskUserQuestion` confirmation (see "Exhausting the ladder" below).

Default starting tier for a freshly decomposed subtask is `haiku`. A sub-subtask created by
recursive decomposition (see below) starts at `sonnet` instead, since its parent subtask already
proved too hard for `haiku`/`sonnet` — starting it back at `haiku` would just repeat a known-bad
attempt.

The tier names above (`haiku`, `sonnet`, `opus`, `fable`) are the literal values to pass as the
`Agent` tool's `model` parameter — the ladder isn't a separate abstraction layered on top, it's just
which `model` value you pass on each retry. For example, delegating a fresh subtask at the starting
tier looks like:

```
Agent({ description, prompt, model: 'haiku', isolation: 'worktree' })
```

Retrying the same subtask at the next tier after an escalation is the same call with `model` bumped
up (`'sonnet'`, then `'opus'`, then — only with confirmation — `'fable'`) and the same `prompt`; see
"The worker-side signal" below for what changes and what doesn't between attempts.

## The worker-side signal: `ESCALATE`

Append this to every delegated subtask's prompt:

> If this task needs more context, deeper reasoning, or more steps than you can reliably deliver, do
> not guess or produce a low-confidence answer. Instead, return exactly:
> `ESCALATE: <one-sentence reason>`

When an `Agent` call's result starts with `ESCALATE:`, retry the same subtask at the next tier up,
carrying the escalation reason forward into the retry's tracking (not into the retry's own prompt —
the retry gets the original subtask prompt again, at a stronger model, not a prompt about why the
previous attempt failed).

## The orchestrator-side check: plausibility heuristic

Even a non-`ESCALATE` result can be quietly wrong — a small model may not recognize its own limits.
After every result that isn't itself an `ESCALATE`, check for:

- **Suspiciously short or generic output** relative to what the subtask asked for (a two-line answer
  to a subtask that asked for a multi-file change).
- **Apology or hedging language** ("I wasn't able to fully...", "this may not be complete...",
  "I couldn't verify...").
- **Visible non-completion** — TODOs left in code, a described plan with no actual edits made, a
  claimed file change that verification doesn't actually show. How to verify depends on whether the
  subtask ran with `isolation: 'worktree'` (see `references/worktree-merge.md`): a worktree-isolated
  subtask's changes live on its own branch in a separate worktree, so the orchestrator's own
  `git status`/`git diff` in the working tree will never show them and would false-positive on every
  successful isolated subtask — check `git diff <working-branch>...<worktree-branch>` instead, using
  the branch name from the `Agent` result / state file's `worktree` field. For a non-isolated
  (read-only or in-place) subtask, plain `git status`/`git diff` in the working tree is the right
  check.

Any of these triggers the same next-tier retry as an explicit `ESCALATE`, with the heuristic
observation recorded as the reason in the state file.

## Exhausting the ladder: recursive decomposition, then `fable`, then hand-back

The recursive-decomposition step below has two triggers, not one: a subtask escalating all the way
to `opus` (the normal case described here), or a worktree merge conflict on that subtask's branch
(see `references/worktree-merge.md`), which routes straight to step 1 below regardless of the
subtask's current tier — a merge conflict is a decomposition problem, not something a stronger model
fixes by retrying, so it skips the tier-by-tier ladder entirely instead of waiting for it to exhaust.

If a subtask still escalates (via either signal) at `opus`:

1. **Recursively decompose once.** Break that subtask into smaller sub-subtasks, following the same
   decomposition guidance as the top-level decomposition (see the `orchestrator` skill's
   "Decomposition guidance" section). Re-enter the ladder at `sonnet` for each sub-subtask (not
   `haiku` — see above).
2. If any sub-subtask escalates through `sonnet → opus` again, **ask the user** via
   `AskUserQuestion` whether to attempt it with `fable`. Do not use `fable` without this
   confirmation — it sits outside the normal cost/capability ladder and its fit for a given task
   isn't assumed.
3. If the user declines, or the `fable` attempt also escalates, **hand the subtask back** to the
   main conversation context: mark it `blocked` in the state file, and report it to the user with its
   full attempt history (every tier tried, every escalation reason) so the original context can pick
   it up with complete information — not as a bare failure with no trail.

This is a bounded process by construction: at most one recursive-decomposition pass, at most one
`fable` attempt (with confirmation), then a stop. No tier is retried more than once with the same
prompt, and no subtask spins indefinitely.
