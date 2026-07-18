# benchmark-stack

A small **OpenTelemetry stack + report generator** to compare Claude Code runs:
**baseline** (no layer) vs. **context-layer** (with Serena). Measures API calls,
tokens and cost — as a Grafana live dashboard and a slide-ready HTML report.

## Install

```bash
/plugin install benchmark-stack@onelitefeather-claude-marketplace
```

Prerequisites: Docker + Compose (dashboard), Python 3 + `matplotlib` (report).

## Commands

- `/benchmark-stack:ab-guide` — shows the A/B protocol and the test tasks.
- `/benchmark-stack:stack up|down` — starts/stops Collector + Prometheus + Grafana.
- `/benchmark-stack:measure` — builds the HTML report from the collected metrics.

## Flow

1. `/benchmark-stack:stack up` → Grafana http://localhost:3000 (admin/admin),
   dashboard "Claude Code — Serena A/B".
2. Baseline run: `source "$CLAUDE_PLUGIN_ROOT/env/ab.sh" baseline 1`, then start
   `claude` (context-layer/Serena off) and run a task from `tasks/test-tasks.md`.
3. Layer run: `source "$CLAUDE_PLUGIN_ROOT/env/ab.sh" serena 1`, same task, same git
   state, context-layer active.
4. Run each task 3–5× per condition (non-determinism → compare averages).
5. `/benchmark-stack:measure` → `serena-report.html`.

`serena-report.sample.html` is included — that's what the output looks like with
sample numbers, without running anything first.

## What is measured

Total tokens and especially **uncached input** (the real cost driver), split by
`condition` and `mcp_server.name` (shows the Serena share → a check whether the
layer was actually used), plus cost. Optionally `report/cc_measure.py` for the
tool-call count (grep/find/read vs. Serena) from the session logs.

## Notes

- **Record correctness** — fewer tokens with a wrong result does not count.
- If Grafana stays empty: `curl -s localhost:8889/metrics | grep claude_code` shows
  the real metric names; the PromQL expects `claude_code_token_usage_tokens_total`.
- Without `context-layer` there is no Serena share to measure — the two plugins
  belong together.
