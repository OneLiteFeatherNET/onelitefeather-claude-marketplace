---
name: ab-guide
description: Shows the A/B test protocol (baseline vs serena) and the test tasks for a clean before/after comparison.
disable-model-invocation: true
---

Show the user the A/B protocol and guide them step by step.

Read and summarize:
- `${CLAUDE_PLUGIN_ROOT}/tasks/test-tasks.md` (the test tasks)
- `${CLAUDE_PLUGIN_ROOT}/env/ab.sh` (the env setup per condition)

Explain the flow briefly:
1. `/benchmark-stack:stack up` — start the observability stack.
2. Per condition, a fresh shell: `source "${CLAUDE_PLUGIN_ROOT}/env/ab.sh" baseline 1`
   or `... serena 1`, then start `claude` and run a test task. Baseline = Serena off,
   serena = Serena on (plugin MCP active).
3. Each task 3–5× per condition, same git state (`git reset --hard`).
4. `/benchmark-stack:measure` — build the report.

Emphasize: record the correctness of every run; check Serena usage in the report.
