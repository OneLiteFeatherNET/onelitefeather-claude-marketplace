---
name: measure
description: Builds the before/after token report (HTML) from the collected OTel metrics, plus the tool-call breakdown.
disable-model-invocation: true
---

Build the Serena A/B report from the locally collected OpenTelemetry metrics.

Run:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/report/make_report.py" \
  "${CLAUDE_PLUGIN_ROOT}/data/metrics.json" \
  -o "${CLAUDE_PROJECT_DIR}/serena-report.html"
```

If you also want to analyze Claude Code session logs (tool calls grep/find/read vs.
Serena), run:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/report/cc_measure.py" \
  --baseline "$HOME/.claude/projects/*/BASELINE*.jsonl" \
  --serena   "$HOME/.claude/projects/*/SERENA*.jsonl"
```

Then report the path to the HTML report and the key deltas (total tokens, uncached
input, whether Serena was actually used). Point out that a token win only counts
with unchanged correctness.
