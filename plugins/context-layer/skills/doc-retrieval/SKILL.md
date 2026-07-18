---
name: doc-retrieval
description: Decides WHERE context comes from — code questions via Serena symbols, docs/concept questions via the doc index (if configured), and never dump whole README/wiki/PDF files. Activates on questions about concepts, design decisions, documentation or "how/why".
when_to_use: Whenever the question is about a concept, design decision, rationale, or documentation rather than a concrete code symbol — decide whether to query the doc index or the code layer.
---

# Doc retrieval: pick the right source

Goal: keep the jump between **docs** and **code** cheap — don't pull whole
documents into context.

## Decision rule

- **Code question** (definition, call, type, "where is X implemented") → code layer
  (Serena symbol tools, see the `code-navigation` skill).
- **Docs/concept question** (design decision, "why built this way", a term, a spec)
  → query the doc index, do **not** read the whole README/wiki/PDF.
- **Combined** ("how does our code use the API and what does the design doc say")
  → first the code layer for the call sites (+ JavaDoc at the symbol), then the doc
  index for the rationale. In that order, not both as full text.

## Doc index (optional, project-specific)

This layer deliberately bundles **no** doc-index server, because that needs API
keys and a vector store (nothing that belongs in a shared plugin). If you want one,
add it per project — e.g. `claude-context` (Zilliz) or an Outline/Confluence
retrieval server — and register it in the project `.mcp.json`.

Until then: for free-form docs, only use targeted `search_for_pattern`/`read` on
the specifically relevant file — no broad ingestion of whole doc trees.
