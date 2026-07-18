# benchmark-stack — env helper for A/B runs
# Usage:  source env/ab.sh <baseline|serena> [run-no]
# Then start `claude` in the SAME shell and run the test task.
#
# Points Claude Code's OpenTelemetry export at the local collector (localhost:4317)
# and tags the run via OTEL_RESOURCE_ATTRIBUTES so Grafana/report can cleanly split
# baseline vs serena.

_cond="${1:-baseline}"
_run="${2:-1}"

if [ "$_cond" != "baseline" ] && [ "$_cond" != "serena" ]; then
  echo "Usage: source env/ab.sh <baseline|serena> [run-no]" >&2
  return 1 2>/dev/null || exit 1
fi

# --- Telemetry on ---
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
# Faster export so numbers land in the dashboard promptly:
export OTEL_METRIC_EXPORT_INTERVAL=5000
export OTEL_LOGS_EXPORT_INTERVAL=5000

# --- Run tagging (becomes the metric labels 'condition' / 'run') ---
export OTEL_RESOURCE_ATTRIBUTES="condition=${_cond},run=${_run},service.name=claude-code"

echo "[ab.sh] condition=${_cond} run=${_run}  -> OTLP to ${OTEL_EXPORTER_OTLP_ENDPOINT}"
if [ "$_cond" = "baseline" ]; then
  echo "        NOTE: DISABLE Serena/doc-layer for this run (e.g. 'claude --strict-mcp-config' without Serena,"
  echo "              or turn the Serena plugin/server off in this project). Built-in tools only."
else
  echo "        Serena (+ optional doc-layer) ACTIVE for this run. The CLAUDE.md routing must be present."
fi
