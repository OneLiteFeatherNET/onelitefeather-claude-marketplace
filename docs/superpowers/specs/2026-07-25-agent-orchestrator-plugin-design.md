# Plugin `agent-orchestrator` — Design

## Purpose

A new Claude Code plugin that turns complex, multi-step tasks into a delegation pipeline: a skill
decomposes the task into independent subtasks and delegates each to the cheapest model tier likely
to handle it, escalating to stronger tiers only when a subtask proves too hard. This lets expensive
reasoning (opus, and — with explicit user permission — fable) be reserved for the subtasks that
actually need it, while the bulk of the work runs on haiku/sonnet.

Claude-Code-only: the design leans on mechanisms with no equivalent on Codex/Antigravity — the
`Agent` tool's per-call model override and `isolation: 'worktree'`, and the `TaskCreate`/`TaskUpdate`
task-tracking tools. No `.codex-plugin`/`.antigravity-plugin` manifests are shipped.

## Scope decisions (made during brainstorming)

- **Trigger:** proactive skill trigger (description-based auto-invocation) is primary — no slash
  command is required to start orchestrating. A `/agent-orchestrator:run <task>` command is included
  as an explicit manual override for when auto-detection doesn't fire or the user wants to force it.
- **Model ladder:** fixed four-tier ladder `haiku → sonnet → opus → fable`. The first three are a
  straight retry-on-escalation chain; `fable` is gated behind an explicit `AskUserQuestion`
  confirmation and is never used silently.
- **Escalation signal — combined:** (1) the worker's own prompt instructs it to return
  `ESCALATE: <reason>` instead of a low-confidence result when the subtask exceeds what it can
  reliably handle; (2) the orchestrator (main context) additionally runs a lightweight plausibility
  heuristic over every non-`ESCALATE` result (suspiciously short/generic output, apology/error
  language, visible non-completion) as a fallback net for silent under-delivery.
- **Max-escalation behavior:** if a subtask still escalates at `opus`, the orchestrator does **not**
  immediately give up — it recursively decomposes that subtask once into smaller sub-subtasks, which
  re-enter the ladder starting at `sonnet` (not `haiku`, since the subtask is already known to be
  hard). Only if that also fails does the orchestrator ask the user for permission to try `fable`. If
  the user declines, or `fable` also escalates, the subtask is handed back to the main conversation
  context with its full attempt history (not retried indefinitely).
- **Worktree isolation:** per-subtask, not per-run. Every subtask that mutates files runs via
  `Agent({..., isolation: 'worktree'})` so parallel workers can never clobber each other's changes.
  Read-only/analysis subtasks skip isolation. Successful worktree branches are merged back into the
  working branch by the orchestrator; a merge conflict is itself treated as an escalation-worthy
  signal rather than something to silently retry past.
- **State tracking — combined:** a local, gitignored JSON state file records orchestrator-internal
  detail (per-subtask tier history, escalation reasons, worktree path/branch) that `TaskCreate`
  doesn't model, while `TaskCreate`/`TaskUpdate` mirrors the same subtasks for user-visible progress
  in the harness's task UI. Neither replaces the other.
- **State file must never land in the repo:** before first writing the state file, the skill checks
  whether `.claude/agent-orchestrator/` is already covered by the project's `.gitignore` and adds an
  entry itself if not — this is a hard requirement, not a documentation note, since a plugin whose own
  scratch state gets committed would be a direct contradiction of its purpose.
- **Out of scope:** no cross-run state persistence/resumption UI (a run's state file is
  session/run-scoped, not a dashboard); no cost/token accounting or budget enforcement; no
  auto-detection tuning beyond a reasonable trigger description (no user-configurable sensitivity
  knob in v1).

## Structure

```
plugins/agent-orchestrator/
├── .claude-plugin/plugin.json
├── README.md
├── commands/
│   └── run.md
└── skills/
    └── orchestrator/
        ├── SKILL.md
        └── references/
            ├── escalation-protocol.md
            ├── state-file.md
            └── worktree-merge.md
```

Additionally: an entry for `agent-orchestrator` in `.claude-plugin/marketplace.json` (format
analogous to the four existing plugin entries) and a row in the plugin table in the root `README.md`.

## Skill: `orchestrator`

**SKILL.md** (main content):

- Trigger description: fires proactively when a task is recognizably multi-step and decomposes into
  parts that can be worked on independently (not for single-shot edits or simple questions).
- Core loop, stated plainly:
  1. Decompose the task into independent subtasks.
  2. For each subtask: create a state entry (see `references/state-file.md`) and a matching
     `TaskCreate` entry.
  3. Delegate via `Agent`, starting at the cheapest tier likely to succeed (default: `haiku`), using
     `isolation: 'worktree'` for any subtask that touches files.
  4. Apply the escalation protocol (`references/escalation-protocol.md`) to each result.
  5. On subtask completion, merge its worktree branch back per `references/worktree-merge.md`, update
     both the state file and the `TaskCreate` entry.
  6. Once all subtasks resolve (completed or handed back), summarize outcomes to the user, calling
     out any subtasks that were handed back unresolved.
- Explicitly states the decomposition should produce subtasks that are independent enough to run in
  parallel and small enough that a small model has a realistic shot — this is the actual point of the
  plugin, not just a fallback path.
- Points to the three reference files for the mechanics that don't need to live in the always-loaded
  skill body.

**references/escalation-protocol.md**:

- The four-tier ladder and the ordering rule (`haiku → sonnet → opus`, `fable` gated).
- The exact worker-prompt addendum used for every delegated subtask, instructing it to return
  `ESCALATE: <reason>` instead of forcing a low-confidence answer.
- The plausibility-heuristic checklist the orchestrator applies to non-`ESCALATE` results.
- The max-escalation flow: one recursive decomposition attempt restarting at `sonnet`, then the
  `AskUserQuestion` gate for `fable`, then hand-back to the main context with full history.
- Explicit statement that this is a bounded process — no unbounded retry loops at any tier.

**references/state-file.md**:

- JSON schema: run id, top-level task description, start timestamp, and a list of subtask records —
  id, description, status (`pending`/`in_progress`/`escalated`/`blocked`/`done`/`failed`), current
  tier, full tier history (`{tier, outcome, reason}` entries), worktree path/branch (if any), result
  summary.
- File location: `.claude/agent-orchestrator/state/<run-id>.json`.
- The mandatory `.gitignore` check/append step that must run before the file is first written.
- Relationship to `TaskCreate`: what lives in the state file vs. what's mirrored into task entries,
  and that they're kept in sync but serve different audiences (orchestrator-internal vs. user-facing).

**references/worktree-merge.md**:

- When to use `isolation: 'worktree'` (file-mutating subtasks) vs. skip it (read-only/analysis).
- How to merge a successful worker's worktree branch back into the working branch.
- Treating a merge conflict as an escalation signal rather than silently retrying or discarding
  changes.

## Command: `run`

**commands/run.md**: a `disable-model-invocation: true` command (explicit-only, mirrors the pattern
used by `framework`'s `doctor`/`setup`) that takes the task description as its argument and forces the
`orchestrator` skill's core loop to start immediately, bypassing the proactive-trigger judgment call —
for cases where the user wants orchestration on a task that wouldn't otherwise be judged complex
enough to auto-trigger.

## Out of scope

- Cross-run resumption/dashboard UI for state files.
- Cost or token budget accounting/enforcement.
- User-configurable trigger-sensitivity tuning.
- Codex/Antigravity portability (the mechanisms this plugin depends on don't exist there).
