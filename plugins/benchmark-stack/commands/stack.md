---
name: stack
description: Starts or stops the local OTel observability stack (OTel Collector + Prometheus + Grafana) for the A/B measurement.
disable-model-invocation: true
argument-hint: "up | down"
---

Control the local observability stack. Argument: `$ARGUMENTS` (up or down).

On `up`:
```bash
docker compose -f "${CLAUDE_PLUGIN_ROOT}/stack/docker-compose.yml" up -d
```
Then tell the user: Grafana runs on http://localhost:3000 (admin/admin, dashboard
"Claude Code — Serena A/B"), Prometheus on http://localhost:9090, and Claude Code
must be started via `source "${CLAUDE_PLUGIN_ROOT}/env/ab.sh" <baseline|serena>` so
OTLP flows to localhost:4317.

On `down`:
```bash
docker compose -f "${CLAUDE_PLUGIN_ROOT}/stack/docker-compose.yml" down
```

Check first whether Docker is running; if not, point it out politely.
