---
name: run
description: Force the orchestrator skill's decompose/delegate/escalate loop to start immediately on the given task, bypassing the skill's own proactive-trigger judgment. Use when a task should be orchestrated but wouldn't otherwise be recognized as complex enough to auto-trigger.
argument-hint: <task description>
disable-model-invocation: true
---

Invoke the `agent-orchestrator:orchestrator` skill on the task described in `$ARGUMENTS`, starting
immediately — do not spend time judging whether the task is "complex enough"; that judgment call
already happened when the user typed this command.

If `$ARGUMENTS` is empty, ask the user what task to orchestrate before doing anything else.

Follow the skill's core loop exactly as its own `SKILL.md` defines it: decompose, track, delegate,
escalate, merge worktrees, and summarize at the end. Once the skill is loaded, its `SKILL.md`
correctly points at its own `references/escalation-protocol.md` and `references/worktree-merge.md`
(paths relative to the skill directory) — do not try to resolve those reference paths from this
command file's own location.
