---
name: report
description: Shows the trend across the most recent Claude Code sessions (exploration calls, Serena usage, tokens) — proves whether the context-layer takes hold in daily work.
disable-model-invocation: true
argument-hint: "[number-of-sessions]"
---

Build the day-to-day trend report. Run (default 15 sessions, or `$ARGUMENTS`):

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/trend_report.py" --last "${ARGUMENTS:-15}"
```

Summarize the key takeaway for the user: are **exploration calls** and **uncached
input** going down over time and are **Serena calls** going up? If Serena is
consistently 0, the routing isn't taking effect — then check context-layer
(installed/active?) and the CLAUDE.md/skill instruction.
