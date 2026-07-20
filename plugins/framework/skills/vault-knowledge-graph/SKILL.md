---
name: vault-knowledge-graph
description: Builds and maintains a knowledge graph in the "Vault" collection in Outline — stores research material, project info, concepts, sources, and people as linked documents, and later loads relevant context back from it in a targeted way. ALWAYS use this skill when the user wants to store, note down, or look something up "in the Vault", "in Outline", or "in the knowledge base" — even if they just say "remember this", "save that research", or "what do we already know about X" without naming Outline or Vault explicitly. Applies both to writing (new findings, project status, research results) and to targeted loading of background knowledge before working on a task.
---

# Vault Knowledge Graph

This skill turns the Outline collection **"Vault"** into a knowledge graph: documents are nodes, mutual hyperlinks in the text are edges. Outline itself has no concept of a graph — the graph property exists only because every document explicitly links its related documents, and those links are maintained in both directions. Without consistent backlinks, the Vault degrades into an ordinary document dump.

Use the Outline MCP tools for every action (`list_collections`, `list_collection_documents`, `list_documents`, `fetch`, `create_document`, `update_document`, `move_document`, `create_collection`). If they're marked deferred, load them first via ToolSearch.

## Core principle: search before creating

Before creating anything new, search the Vault (`list_documents` with the Vault collection's `collectionId`) for related terms. A knowledge graph gets its value from connections, not from the sheer number of documents — a new find is almost always related to something that already exists (same project, same concept, same source). These hits become edges later.

## Setup: ensure the structure exists

Look up the Vault collection ID via `list_collections(query="Vault")`. If it doesn't exist, ask the user before creating it — a new collection is a visible structural change in a (possibly shared) workspace.

Check the top-level documents with `list_collection_documents`. If one of the five categories is missing, create it (uncritical, pure structure, no need to ask first). These five titles are literal document titles already in use in the real Vault — keep them exactly as written, don't translate them:

| Icon | Category | Belongs here |
|---|---|---|
| 📚 | Research Material | Papers, articles, research notes, experiment results, summaries |
| 🗂️ | Projekte | One document per project: goal, status, architecture decisions, open questions |
| 💡 | Konzepte & Themen | Recurring terms, definitions, patterns, cross-project ideas |
| 🔗 | Quellen | External references: links, citations, tools, bibliographic details |
| 👤 | Personen & Organisationen | Who's who, role, relation to projects/topics |

Each category is a top-level document in the Vault collection; each individual entry is created as a child document underneath it (`parentDocumentId`). So the category provides the coarse ordering; the actual relationships between nodes — including across categories — come from links in the text, not from nesting.

## Metadata block

Every node document starts with a metadata block as a table, followed by a separator line and the actual content:

```markdown
| Feld | Wert |
|---|---|
| Typ | Research Material |
| Tags | #rag #llm #retrieval #embeddings |
| Erstellt | 2026-07-20 |
| Verwandte Dokumente | [Projekt Onelitefeather](/doc/projekt-onelitefeather-abc123) · [Konzept: Retrieval](/doc/konzept-retrieval-def456) |

---

(actual content)
```

The table's field names (`Typ`, `Tags`, `Erstellt`, `Verwandte Dokumente`) are literal, fixed strings — keep them exactly as shown so every document in the Vault uses the same, greppable structure.

- **Table instead of blockquote:** an earlier version of this skill used four `> **Field:**` lines in a shared blockquote. Testing against real Outline showed that Outline collapses multi-line blockquotes into a single paragraph on save (the line breaks are lost) — after that, no individual metadata line could be patched anymore. A table, on the other hand, is its own block type in Outline with real, separately addressable rows, and survives saving reliably.
- **Tags** are short, lowercase, with a `#` prefix, and cover two levels: at least one tag for the overarching topic/project (e.g. `#kundenportal`) and one to three tags for the concrete terms in the content (e.g. `#rag`, `#embeddings`) — this keeps both broad and targeted search reliable later.
- **Verwandte Dokumente** (related documents) holds the relative Outline URL (the `url` field from the `create_document`/`fetch` tool response), not just the title as text — only that way does the link actually become an edge when clicked.
- This fixed structure is deliberate: the "Verwandte Dokumente" row can later be changed in a targeted way via `update_document` with `editMode: "patch"` (`findText` = the exact existing table row, e.g. `| Verwandte Dokumente | ... |`), without touching the rest of the content.

## Writing conventions

- **Use correct special characters:** titles, tags, and content use real Unicode umlauts and ß (ä, ö, ü, ß) instead of ASCII substitutes (ae, oe, ue, ss) — unless a literally quoted external text already contains the ASCII variant.
- **Formulas as LaTeX:** mathematical formulas and equations are written as LaTeX (`$...$` inline, `$$...$$` as its own block) instead of being paraphrased in prose — Outline renders LaTeX natively, and only that way do formulas stay exactly reusable later.

## Workflow: capturing knowledge

1. **Determine the type** — which of the five categories fits best. In genuinely ambiguous cases, pick the closest match rather than asking.
2. **Search for related documents** — `list_documents` with keywords from the new content, filtered to the Vault collection. The most relevant hits become edges.
3. **Create the document** — `create_document` with title, metadata block + content as `text`, and `parentDocumentId` of the matching category. Condense large sources (whole papers, long threads) sensibly instead of copying them in 1:1 — a later recall pass should be able to load something targeted, not search through a novel.
4. **Maintain backlinks** — for every related document found in step 2: read its current text via `fetch`, then extend its existing `Verwandte Dokumente` table row via `update_document` (`editMode: "patch"`, `findText` = the exact existing row, e.g. `| Verwandte Dokumente | ... |`) with a link to the new document. Skipping this step creates only a one-sided connection — the graph stays incomplete.

## Workflow: loading targeted context (recall)

The goal is to bring exactly the relevant slice of the Vault into the context window for an upcoming task — not as much as possible, but as precisely as possible.

1. **Search** — `list_documents` with the core terms of the current task, scoped to the Vault collection.
2. **Load** — fully load the most relevant hits via `fetch(resource: "document", id)`.
3. **Follow one hop** — extract the linked documents from their metadata block and only load the ones that plausibly contribute to the concrete task. Blindly following the entire neighborhood blows up the context window and dilutes relevance — when in doubt, load one neighbor too few rather than ten too many.
4. **Condense** — prepare the result compactly for the actual task (relevant facts, not raw dumps of every document loaded).

## Further guardrails

- Never delete existing Vault documents without an explicit instruction — maintaining backlinks means adding, not replacing.
- If a new find clearly belongs to an existing document (e.g. a new status update for the same project), update that existing document (`update_document`, usually `editMode: "append"` or `"patch"`) instead of creating a duplicate.
- When uncertain about category or linking: make a sensible assumption and briefly mention it in the chat, rather than interrupting the flow with questions — the user can correct it at any time.
