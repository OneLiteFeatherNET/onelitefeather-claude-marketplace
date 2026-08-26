# Outline conventions (OneLiteFeather)

House rules for one specific wiki. They apply **only** when documenting a OneLiteFeather project in its Outline instance — never to a third-party project, whose own conventions win. For storing requirements in a repo instead, see `repo-layout.md`.

## Tools

`list_collections`, `list_collection_documents`, `list_documents`, `fetch`, `create_document`, `update_document`, `move_document`, `list_users`. If they are marked deferred, load them via ToolSearch first.

If the tools are unavailable, fall back to Markdown files in the repo and propose the path — **never invent Outline URLs.**

## Formatting rules

- **No H1 as the first line** — the title is a separate field in Outline. Content starts with body text or a heading at H2 or below.
- **Real umlauts and ß** (ä, ö, ü, ß) instead of ASCII substitutes, and typographic quotation marks, since the documents are German.
- **Cross-references as real Markdown links** `[title](url)`, using the actual URL from the `create_document` or `fetch` response. No wiki-link syntax (`[[…]]`) — Outline does not render it as a link. No placeholder URLs, not even temporarily.
- **Never start a placeholder with `<`.** Outline mangles `- [ ] <…>` into `- [ ] undefined<…>` on save. Write `(description)` instead — everywhere, not only in checkboxes.
- **@-mentions:** `@[Name](mention://user/<userId>)`, with IDs from `list_users`. **Never guess a user ID.** If it cannot be found, write the plain name without a mention.

## Writing and changing

- `create_document` with the project parent's `parentDocumentId` — requirements documents hang under the existing project, never loose in a collection.
- Change existing documents with `editMode: "patch"`. **Never blind `replace`** when parts are worth keeping.
- After creating the stage documents, patch the stage table in the main document with the real URLs.
- Before creating anything, check whether the project already has a parent (`list_documents`, `list_collection_documents`). Do not assume it is missing.
