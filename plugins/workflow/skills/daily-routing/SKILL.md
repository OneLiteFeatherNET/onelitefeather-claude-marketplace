---
name: daily-routing
description: Day-to-day operating policy for the context-layer — during normal work (building features, fixing bugs, reading code) consistently use Serena symbol tools instead of grep/find/read and measure the effect regularly. Applies continuously, not only for explicit search tasks.
when_to_use: Continuously during normal development work in this project — building features, fixing bugs, reading or changing code — to keep call/token usage low.
---

# Daily routing — operating the context-layer

This policy keeps the context-layer active in **daily** work (not just the benchmark):

1. **Serena is the default.** For any code interaction, use the symbol tools first:
   `get_symbols_overview` → `find_symbol` → `find_referencing_symbols`, edit
   symbol-based. grep/find/read only when the language server returns nothing
   (config, strings, non-code).
2. **Docs targeted.** Send concept/design questions to the doc index or the
   specifically relevant file — no full-text dumps of whole README/wiki/PDFs.
3. **Keep it measurable.** After larger tasks run `/benchmark-stack:measure`, and
   periodically `/workflow:report` for the trend. Goal: exploration calls and
   uncached input fall, Serena usage stays high.
4. **Stay honest.** A saving only counts with unchanged correctness.

This plugin depends (via `dependencies`) on `context-layer` and `benchmark-stack` —
without them the layer or the measurement is missing.
