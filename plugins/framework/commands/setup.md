---
name: setup
description: Guides the user step by step through the complete framework setup — dependency plugins, the Outline MCP connection, and the Vault structure — pausing wherever the user needs to do something themselves.
disable-model-invocation: true
---

Walk the user through the framework setup live, one step at a time — this
is meant to feel like a guided walkthrough, not a script that silently runs
everything and dumps a report at the end. Announce what you're about to
check before checking it, report each step's result as soon as you have it,
and pause for the user whenever a step needs them to act before you can
usefully continue. This is an explicit, user-triggered command — you may
create missing structure (Vault collection, categories) directly, without
asking first; only genuinely blocking issues (see below) need a pause.

**Step 1 — Dependency plugins.** Tell the user you're checking the bundled
plugins, then run `claude plugin list --json` via Bash. If that CLI call
isn't available in this environment, say so briefly and move on to Step 2 —
don't abort the whole command over it. Report the status of `superpowers`,
`skill-creator`, `claude-md-management`, `code-review`, `code-simplifier`,
`security-guidance`, `frontend-design`, `context7`, and `ralph-loop` right
away, plugin by plugin or as a short table — whichever reads clearer. For
anything missing or disabled, give the exact command the user needs to run
themselves (`claude plugin install <name>@claude-plugins-official` or
`claude plugin enable <name>`) — don't try to install it yourself. This step
never blocks the rest of setup; move on regardless of what you found.

**Step 2 — Outline MCP connection.** Say you're checking Outline next, then
try `list_collections` (load via ToolSearch first if the Outline tools are
deferred). If it works, say so briefly and continue straight to Step 3.
If it fails with an auth/connection error, this **is** a blocking step: stop
here, explain clearly that a browser OAuth login against the Outline
instance is needed, and ask the user to complete it now and tell you when
they're ready — don't attempt Step 3 with a broken connection, since
Vault operations would just fail anyway. Once the user confirms, retry
`list_collections` before moving on.

**Step 3 — Vault structure.** Say you're setting up the Vault now. Search
for the **"Vault"** collection (`list_collections(query="Vault")`).
- Missing: create it (`create_collection`, name "Vault"), and mention that
  you just created it — a new collection is visible to the whole team.
- Existing: say briefly that it's already there, reuse it.

Then check `list_collection_documents` for the top-level documents. Create
any of the five categories that are missing (`create_document`,
`collectionId` = Vault collection, no `parentDocumentId`), naming each one
as you create it rather than silently batching all five. These titles are
literal — they match the categories already used in the real Vault, so keep
them exactly as written, not translated:

| Icon | Title |
|---|---|
| 📚 | Research Material |
| 🗂️ | Projekte |
| 💡 | Konzepte & Themen |
| 🔗 | Quellen |
| 👤 | Personen & Organisationen |

**Step 4 — Wrap-up.** Give a short final summary: what was already fine,
what you just created or fixed, and — clearly separated as its own list —
what the user still needs to do themselves (missing plugin installs, `uv`
for the optional `framework-code-navigation` if that's installed too).
Mention `/framework:doctor` as the way to re-check everything anytime
without making changes.

This command is idempotent — safe to re-run any time, e.g. after onboarding
a new team member, after completing a pending OAuth login, or whenever
something seems off.
