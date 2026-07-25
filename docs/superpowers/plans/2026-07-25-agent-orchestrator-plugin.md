# Agent-Orchestrator Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new `agent-orchestrator` plugin to this Claude Code plugin marketplace — a skill that decomposes complex tasks into independent subtasks, delegates each to the cheapest viable model tier, and escalates only when a subtask proves too hard — per `docs/superpowers/specs/2026-07-25-agent-orchestrator-plugin-design.md`.

**Architecture:** A single skill (`orchestrator`) plus an explicit-trigger command (`run`), both Claude-Code-only (no `.codex-plugin`/`.antigravity-plugin` manifests, since the plugin depends on the `Agent` tool's model overrides and `isolation: 'worktree'`, and on `TaskCreate`/`TaskUpdate`). `SKILL.md` holds the always-loaded core loop; three `references/` files hold the escalation ladder, the state-file schema, and the worktree-merge mechanics, mirroring how `release-engineering`'s `workflows` skill splits large topics into references.

**Tech Stack:** Markdown with YAML frontmatter (`SKILL.md`, `commands/run.md`), JSON (plugin manifest, `marketplace.json`). No build step, no test framework in this repo — "tests" in this plan are structural/content verification via `jq` (JSON validity) and `grep` (required frontmatter fields, cross-file path references, key content markers), matching the pattern used in `docs/superpowers/plans/2026-07-25-release-engineering-plugin.md`.

## Global Constraints

- Plugin name: `agent-orchestrator`. Skill name: `orchestrator`. Command name: `run` (invoked as `/agent-orchestrator:run`). All lowercase, kebab-case.
- Claude Code only: `plugins/agent-orchestrator/` ships only `.claude-plugin/plugin.json` — no `.codex-plugin/`, no `.antigravity-plugin/`.
- `SKILL.md` frontmatter: exactly `name` and `description` (no other keys), matching the convention verified against existing skills in this repo.
- `commands/run.md` frontmatter: `name`, `description`, `argument-hint`, `disable-model-invocation: true` — explicit-only command, matching `plugins/framework/commands/doctor.md`'s pattern of `disable-model-invocation: true` for commands that shouldn't be silently auto-invoked by the model.
- Model ladder is fixed and must appear identically (same order, same names) in both `SKILL.md` and `references/escalation-protocol.md`: `haiku → sonnet → opus → fable`.
- State file path is fixed: `.claude/agent-orchestrator/state/<run-id>.json`. Every reference to it across files must use this exact path.
- The `.gitignore` safety requirement (check/append `.claude/agent-orchestrator/` before first write) must appear as a hard requirement in `references/state-file.md`, not as a soft suggestion.
- Every new/modified plugin manifest and `marketplace.json` must remain valid JSON (`jq empty <file>` exits 0).
- Content is generic and project-agnostic — no OneLiteFeather-specific tooling, repo names, or conventions (unlike `release-engineering`, this plugin is a general orchestration mechanism, not org-specific knowledge).

---

### Task 1: Plugin scaffold — manifest

**Files:**
- Create: `plugins/agent-orchestrator/.claude-plugin/plugin.json`

**Interfaces:**
- Produces: the plugin directory `plugins/agent-orchestrator/` that Tasks 3–7 populate with `skills/` and `commands/`. No code interfaces — a static JSON manifest, structurally identical in shape to the other plugins' `.claude-plugin/plugin.json` files, minus the `dependencies`/`mcpServers` keys (this plugin needs neither).

- [ ] **Step 1: Write a failing structural check**

```bash
test -f plugins/agent-orchestrator/.claude-plugin/plugin.json && echo "UNEXPECTED: already exists" || echo "OK: missing as expected"
```

Expected output: `OK: missing as expected`

- [ ] **Step 2: Create `plugins/agent-orchestrator/.claude-plugin/plugin.json`**

```json
{
  "name": "agent-orchestrator",
  "displayName": "Agent Orchestrator",
  "version": "0.1.0",
  "description": "Decomposes complex, multi-step tasks into independent subtasks and delegates each to the cheapest viable model tier (haiku, sonnet, opus, and — with explicit permission — fable), escalating a subtask only when it reports being out of its depth or its result looks implausible. Claude Code only.",
  "author": { "name": "OneLiteFeather", "url": "https://github.com/OneLiteFeatherNET" },
  "license": "MIT",
  "keywords": ["orchestration", "subagents", "delegation", "multi-agent", "model-routing", "worktree", "task-tracking"]
}
```

- [ ] **Step 3: Verify valid JSON with the expected name**

```bash
jq -e '.name == "agent-orchestrator"' plugins/agent-orchestrator/.claude-plugin/plugin.json >/dev/null \
  && echo "OK: valid JSON with matching name" || echo "FAIL"
```

Expected: `OK: valid JSON with matching name`

- [ ] **Step 4: Commit**

```bash
git add plugins/agent-orchestrator/.claude-plugin/plugin.json
git commit -m "feat: scaffold agent-orchestrator plugin manifest"
```

---

### Task 2: Register the plugin in `marketplace.json` and `README.md`

**Files:**
- Modify: `.claude-plugin/marketplace.json`
- Modify: `README.md`

**Interfaces:**
- Consumes: `plugins/agent-orchestrator` directory existing (Task 1).
- Produces: nothing consumed by later tasks — a leaf registration step, done early so the plugin isn't "invisible" to marketplace tooling while later tasks are still in progress.

- [ ] **Step 1: Write a failing check**

```bash
jq -e '.plugins[] | select(.name == "agent-orchestrator")' .claude-plugin/marketplace.json >/dev/null \
  && echo "UNEXPECTED: already registered" || echo "OK: not registered yet"
```

Expected: `OK: not registered yet`

- [ ] **Step 2: Add the plugin entry to `.claude-plugin/marketplace.json`**

Open `.claude-plugin/marketplace.json`. Find the `"plugins"` array's last entry (currently
`release-engineering`, ending with its closing `}` followed by `]`). Add a `,` after that `}`, then
add a new object:

```json
    {
      "name": "agent-orchestrator",
      "displayName": "Agent Orchestrator",
      "source": "./plugins/agent-orchestrator",
      "description": "Decomposes complex tasks into independent subtasks and delegates each to the cheapest viable model tier (haiku, sonnet, opus, fable), escalating only when a subtask proves too hard. Claude Code only.",
      "category": "productivity",
      "keywords": ["orchestration", "subagents", "delegation", "multi-agent", "model-routing"]
    }
```

The full `"plugins"` array must end up with five entries: `framework`, `framework-code-navigation`,
`minestom-knowledge`, `release-engineering`, `agent-orchestrator`, in that order.

- [ ] **Step 3: Verify JSON validity and the new entry**

```bash
jq empty .claude-plugin/marketplace.json && echo "OK: valid JSON"
jq -e '.plugins[] | select(.name == "agent-orchestrator") | .source == "./plugins/agent-orchestrator"' .claude-plugin/marketplace.json >/dev/null \
  && echo "OK: entry present" || echo "FAIL: entry missing or wrong source"
jq '.plugins | length' .claude-plugin/marketplace.json
```

Expected: `OK: valid JSON`, `OK: entry present`, and `5` as the length.

- [ ] **Step 4: Add a row to the plugin table in `README.md`**

In `README.md`, find the `## The plugins` table. Add a fifth row directly after the
`release-engineering` row:

```markdown
| **agent-orchestrator** | Decomposes complex tasks into independent subtasks and delegates each to the cheapest viable model tier (haiku, sonnet, opus, fable), escalating only when needed. Claude Code only — uses the `Agent` tool's model overrides, worktree isolation, and task tracking. |
```

- [ ] **Step 5: Add an install line to the `## Install` → `### Claude Code` section**

In the same `README.md`, in the `### Claude Code` fenced bash block, after the line
`/plugin install release-engineering@onelitefeather-claude-marketplace`, add:

```bash

# Complex-task delegation: haiku -> sonnet -> opus -> fable escalation
/plugin install agent-orchestrator@onelitefeather-claude-marketplace
```

- [ ] **Step 6: Verify the README changes landed**

```bash
grep -c "agent-orchestrator" README.md
```

Expected: `2` (the table row's `**agent-orchestrator**` cell, and the
`/plugin install agent-orchestrator@onelitefeather-claude-marketplace` line — the comment line above
it intentionally doesn't repeat the plugin name). Confirm both lines are present via
`grep -n "agent-orchestrator" README.md`.

- [ ] **Step 7: Commit**

```bash
git add .claude-plugin/marketplace.json README.md
git commit -m "feat: register agent-orchestrator in marketplace and README"
```

---

### Task 3: `orchestrator/SKILL.md`

**Files:**
- Create: `plugins/agent-orchestrator/skills/orchestrator/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks (self-contained content file).
- Produces: links to `references/escalation-protocol.md` (Task 4), `references/state-file.md`
  (Task 5), and `references/worktree-merge.md` (Task 6), and to the `/agent-orchestrator:run`
  command (Task 7) — exact names must match what those tasks create.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/agent-orchestrator/skills/orchestrator/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
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
```

- [ ] **Step 3: Verify frontmatter and required content markers**

```bash
f=plugins/agent-orchestrator/skills/orchestrator/SKILL.md
head -1 "$f" | grep -qx -- '---' && echo "OK: starts with frontmatter fence"
grep -q '^name: orchestrator$' "$f" && echo "OK: name field"
grep -q '^description: ' "$f" && echo "OK: description field"
grep -q 'haiku' "$f" && grep -q 'sonnet' "$f" && grep -q 'opus' "$f" && echo "OK: ladder tiers mentioned"
grep -q '## Core loop' "$f" && echo "OK: Core loop section"
grep -q '## Decomposition guidance' "$f" && echo "OK: Decomposition guidance section"
grep -q 'references/escalation-protocol.md' "$f" && echo "OK: points to escalation-protocol reference"
grep -q 'references/state-file.md' "$f" && echo "OK: points to state-file reference"
grep -q 'references/worktree-merge.md' "$f" && echo "OK: points to worktree-merge reference"
grep -q '/agent-orchestrator:run' "$f" && echo "OK: manual command mentioned"
```

Expected: ten `OK:` lines, no errors.

- [ ] **Step 4: Commit**

```bash
git add plugins/agent-orchestrator/skills/orchestrator/SKILL.md
git commit -m "feat: add orchestrator skill"
```

---

### Task 4: `orchestrator/references/escalation-protocol.md`

**Files:**
- Create: `plugins/agent-orchestrator/skills/orchestrator/references/escalation-protocol.md`

**Interfaces:**
- Consumes: `plugins/agent-orchestrator/skills/orchestrator/SKILL.md` (Task 3) links here.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/agent-orchestrator/skills/orchestrator/references/escalation-protocol.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
# Escalation protocol

## The ladder

`haiku → sonnet → opus → fable`, in that fixed order. The first three steps are a plain
retry-at-next-tier chain. `fable` is never used silently — it requires an explicit
`AskUserQuestion` confirmation (see "Exhausting the ladder" below).

Default starting tier for a freshly decomposed subtask is `haiku`. A sub-subtask created by
recursive decomposition (see below) starts at `sonnet` instead, since its parent subtask already
proved too hard for `haiku`/`sonnet` — starting it back at `haiku` would just repeat a known-bad
attempt.

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
  claimed file change that `git status`/`git diff` doesn't actually show.

Any of these triggers the same next-tier retry as an explicit `ESCALATE`, with the heuristic
observation recorded as the reason in the state file.

## Exhausting the ladder: recursive decomposition, then `fable`, then hand-back

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
```

- [ ] **Step 3: Verify content markers**

```bash
f=plugins/agent-orchestrator/skills/orchestrator/references/escalation-protocol.md
grep -q 'haiku → sonnet → opus → fable' "$f" && echo "OK: ladder stated in fixed order"
grep -q 'ESCALATE:' "$f" && echo "OK: ESCALATE contract present"
grep -q 'plausibility heuristic' "$f" && echo "OK: heuristic section present"
grep -q 'AskUserQuestion' "$f" && echo "OK: fable confirmation gate present"
grep -q 'hand the subtask back' "$f" && echo "OK: hand-back behavior present"
grep -qi 'bounded process' "$f" && echo "OK: no-unbounded-retry statement present"
```

Expected: six `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/agent-orchestrator/skills/orchestrator/references/escalation-protocol.md
git commit -m "feat: add escalation-protocol reference"
```

---

### Task 5: `orchestrator/references/state-file.md`

**Files:**
- Create: `plugins/agent-orchestrator/skills/orchestrator/references/state-file.md`

**Interfaces:**
- Consumes: `plugins/agent-orchestrator/skills/orchestrator/SKILL.md` (Task 3) links here.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/agent-orchestrator/skills/orchestrator/references/state-file.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
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
once per run — if a previous run already added the entry, skip re-adding it. This is a hard
requirement: a plugin whose own scratch state ends up committed to the repo it's orchestrating work
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
```

- [ ] **Step 3: Verify content markers**

```bash
f=plugins/agent-orchestrator/skills/orchestrator/references/state-file.md
grep -q '.claude/agent-orchestrator/state/<run-id>.json' "$f" && echo "OK: exact state file path present"
grep -q 'gitignore' "$f" && echo "OK: gitignore requirement present"
grep -q 'hard requirement' "$f" && echo "OK: requirement framed as hard, not soft"
grep -q '"tierHistory"' "$f" && echo "OK: tierHistory field documented"
grep -q '"worktree"' "$f" && echo "OK: worktree field documented"
grep -q 'TaskCreate' "$f" && grep -q 'TaskUpdate' "$f" && echo "OK: TaskCreate/TaskUpdate relationship documented"
```

Expected: six `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/agent-orchestrator/skills/orchestrator/references/state-file.md
git commit -m "feat: add state-file reference"
```

---

### Task 6: `orchestrator/references/worktree-merge.md`

**Files:**
- Create: `plugins/agent-orchestrator/skills/orchestrator/references/worktree-merge.md`

**Interfaces:**
- Consumes: `plugins/agent-orchestrator/skills/orchestrator/SKILL.md` (Task 3) links here.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/agent-orchestrator/skills/orchestrator/references/worktree-merge.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
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
```

- [ ] **Step 3: Verify content markers**

```bash
f=plugins/agent-orchestrator/skills/orchestrator/references/worktree-merge.md
grep -q "isolation: 'worktree'" "$f" && echo "OK: isolation flag documented"
grep -q -- '--no-ff' "$f" && echo "OK: merge command documented"
grep -q 'merge conflict' "$f" && echo "OK: conflict handling documented"
grep -q 'references/escalation-protocol.md' "$f" && echo "OK: links back to escalation protocol"
```

Expected: four `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/agent-orchestrator/skills/orchestrator/references/worktree-merge.md
git commit -m "feat: add worktree-merge reference"
```

---

### Task 7: `commands/run.md`

**Files:**
- Create: `plugins/agent-orchestrator/commands/run.md`

**Interfaces:**
- Consumes: `plugins/agent-orchestrator/skills/orchestrator/SKILL.md` (Task 3) — the command
  delegates to the skill's core loop by name.
- Produces: nothing consumed by later tasks. This is the final task in the plan.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/agent-orchestrator/commands/run.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
---
name: run
description: Force the orchestrator skill's decompose/delegate/escalate loop to start immediately on the given task, bypassing the skill's own proactive-trigger judgment. Use when a task should be orchestrated but wouldn't otherwise be recognized as complex enough to auto-trigger.
argument-hint: <task description>
disable-model-invocation: true
---

Run the `orchestrator` skill's core loop (see the `orchestrator` skill's `SKILL.md`) on the task
described in `$ARGUMENTS`, starting immediately — do not spend time judging whether the task is
"complex enough"; that judgment call already happened when the user typed this command.

If `$ARGUMENTS` is empty, ask the user what task to orchestrate before doing anything else.

Follow the core loop exactly as the `orchestrator` skill defines it: decompose, track, delegate,
escalate per `references/escalation-protocol.md`, merge worktrees per `references/worktree-merge.md`,
and summarize at the end.
```

- [ ] **Step 3: Verify frontmatter and content markers**

```bash
f=plugins/agent-orchestrator/commands/run.md
head -1 "$f" | grep -qx -- '---' && echo "OK: frontmatter fence"
grep -q '^name: run$' "$f" && echo "OK: name field"
grep -q '^disable-model-invocation: true$' "$f" && echo "OK: explicit-only command"
grep -q '\$ARGUMENTS' "$f" && echo "OK: uses \$ARGUMENTS"
grep -q 'orchestrator' "$f" && echo "OK: references orchestrator skill"
```

Expected: five `OK:` lines.

- [ ] **Step 4: Verify the full plugin structure is in place**

```bash
find plugins/agent-orchestrator -type f | sort
```

Expected output (paths only, order matters for `sort`):

```
plugins/agent-orchestrator/.claude-plugin/plugin.json
plugins/agent-orchestrator/commands/run.md
plugins/agent-orchestrator/skills/orchestrator/SKILL.md
plugins/agent-orchestrator/skills/orchestrator/references/escalation-protocol.md
plugins/agent-orchestrator/skills/orchestrator/references/state-file.md
plugins/agent-orchestrator/skills/orchestrator/references/worktree-merge.md
```

- [ ] **Step 5: Commit**

```bash
git add plugins/agent-orchestrator/commands/run.md
git commit -m "feat: add agent-orchestrator run command"
```
