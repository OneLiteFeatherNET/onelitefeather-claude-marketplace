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
