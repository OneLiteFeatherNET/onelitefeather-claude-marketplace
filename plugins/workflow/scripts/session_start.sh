#!/usr/bin/env bash
# SessionStart hook: injects the day-to-day routing policy into the context.
# A SessionStart hook's stdout is loaded as additional context.
cat <<'EOF'
[workflow] Day-to-day routing active:
- Finding/navigating/refactoring code -> Serena symbol tools (find_symbol,
  find_referencing_symbols, get_symbols_overview), NOT grep/find/read.
- Docs/concepts -> the doc index or the specific file, no full-text dumps.
- Raw grep/read only as a last resort (config keys, strings, non-code).
- To track the effect, run /benchmark-stack:measure or /workflow:report regularly.
EOF
exit 0
