#!/usr/bin/env bash
# PreToolUse hook (matcher: Grep) — a gentle, NON-blocking nudge:
# reminds the agent to use Serena instead of Grep for code search.
# Never blocks (always exit 0); only adds context.
set +e
input="$(cat 2>/dev/null)"

python3 - "$input" <<'PY' 2>/dev/null || true
import sys, json
raw = sys.argv[1] if len(sys.argv) > 1 else ""
try:
    data = json.loads(raw) if raw.strip() else {}
except Exception:
    data = {}
ti = data.get("tool_input", {}) or {}
pattern = str(ti.get("pattern", ""))
msg = ("For code structure (definitions, callers, references, types) the Serena "
       "symbol tools are more precise and token-efficient than Grep: "
       "find_symbol / find_referencing_symbols / get_symbols_overview. "
       "Use Grep only when it is really about text/config/strings.")
out = {"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": msg}}
print(json.dumps(out))
PY
exit 0
