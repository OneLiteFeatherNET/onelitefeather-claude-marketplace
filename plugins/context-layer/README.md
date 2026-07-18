# context-layer

Puts a **retrieval layer between docs and code** so Claude Code navigates on
purpose instead of spamming `grep`/`find`/`read` — cutting API calls and tokens.

## What's inside

- **Serena** (MCP, via `uvx`) — LSP symbol search over code: definitions,
  references, structure, symbol-based editing. Resolves into dependencies
  (including JavaDoc at the symbol when `-sources` jars are present).
- **Skill `code-navigation`** — tells the agent to use symbol tools instead of text
  search (otherwise it falls back to grep out of habit).
- **Skill `doc-retrieval`** — decides code vs docs source and prevents dumping whole
  README/wiki/PDFs.

## Install

```bash
/plugin install context-layer@onelitefeather-claude-marketplace
```

Prerequisite: `uv` (for `uvx`). Serena wires up the matching language server for
Java/Kotlin.

## Optional doc index

Deliberately **not** bundled (needs API keys + a vector store). For real doc
retrieval, add one per project (e.g. `claude-context` or an Outline retrieval
server) and register it in the project `.mcp.json`.
