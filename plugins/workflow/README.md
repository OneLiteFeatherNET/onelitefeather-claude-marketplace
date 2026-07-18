# workflow

Runs the **day-to-day operation** of the other two plugins. Depends (via
`dependencies`) on `context-layer` and `benchmark-stack` and makes sure the layer
takes hold not only in the benchmark but in daily work — plus trend reports so the
effect stays visible over time.

## Install

```bash
/plugin install workflow@onelitefeather-claude-marketplace
```

Pulls `context-layer` and `benchmark-stack` in as dependencies.

## What it does

- **SessionStart hook** — injects the routing policy into the context on every start
  (Serena instead of grep, docs targeted).
- **PreToolUse hook (Grep)** — a gentle, non-blocking nudge: reminds the agent to use
  the Serena symbol tools for code structure. Never blocks.
- **Skill `daily-routing`** — the continuous operating policy for normal work.
- **`/workflow:start`** — checks that the layer is active and sets the policy.
- **`/workflow:report`** — trend across recent sessions (exploration calls, Serena
  usage, tokens): is the layer taking hold in daily work?

## Idea

`context-layer` provides the capability, `benchmark-stack` proves the effect once,
and `workflow` keeps both in operation: it keeps reminding the agent to route, and
shows via the trend whether exploration/tokens fall and Serena usage stays high.

## Note on the hooks

The hooks are deliberately **soft** (they inform, they don't block). If you want
harder enforcement, switch the `PreToolUse` Grep hook to blocking (`hooks/hooks.json`
+ `scripts/nudge_grep.sh`) — then the agent must fall back to Serena. The nudge is
the gentler variant to start with.
