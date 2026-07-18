---
name: start
description: Starts day-to-day operation — checks that the context-layer is active and sets the routing policy for the session.
disable-model-invocation: true
---

Set up the day-to-day workflow for this session:

1. Check whether `context-layer` (Serena) is available — try a Serena tool call
   (e.g. `get_symbols_overview` on a file). If not: ask the user to install/enable
   `context-layer` and to provide `uv`.
2. From now on, follow the routing policy: code via Serena symbols, docs targeted,
   grep/read only as a fallback.
3. Point out that `/workflow:report` shows the trend anytime and
   `/benchmark-stack:measure` builds a clean A/B report.

Keep the answer short — just confirm the layer is up and the policy applies.
