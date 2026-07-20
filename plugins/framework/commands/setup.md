---
name: setup
description: Walks through the complete framework setup once — verifies all bundled dependency plugins are installed/enabled, checks the Outline MCP connection, and creates the Vault collection with its five categories.
disable-model-invocation: true
---

Run the complete framework setup. This is an explicit, user-triggered
action — you may create missing structure (Vault collection, categories)
directly, without asking first.

1. **Verify dependency plugins.** Run `claude plugin list --json` via Bash
   and check whether `superpowers`, `skill-creator`, `claude-md-management`,
   `code-review`, `code-simplifier`, `security-guidance`, `frontend-design`,
   `context7`, and `ralph-loop` are present and enabled. If the `claude` CLI
   call itself isn't available in this environment, skip this check with a
   brief note instead of aborting the whole command. For every missing or
   disabled plugin, name the exact command the user needs to run themselves
   (`claude plugin install <name>@claude-plugins-official` or
   `claude plugin enable <name>`) — don't try to install it yourself.
2. **Verify the Outline MCP connection.** Try `list_collections` (load via
   ToolSearch first if the Outline tools are deferred). If it fails with an
   auth/connection error, briefly explain that a browser OAuth login against
   the Outline instance is needed on first use — and continue with the
   remaining setup steps that don't depend on Outline.
3. **Set up the Vault structure.** Search for the **"Vault"** collection
   (`list_collections(query="Vault")`).
   - Missing: create it (`create_collection`, name "Vault").
   - Existing: reuse it, don't duplicate.

   Then check `list_collection_documents` for the top-level documents and
   create any of the five categories that are missing (`create_document`,
   `collectionId` = Vault collection, no `parentDocumentId`). These titles
   are literal — they match the categories already used in the real Vault,
   so keep them exactly as written, not translated:

   | Icon | Title |
   |---|---|
   | 📚 | Research Material |
   | 🗂️ | Projekte |
   | 💡 | Konzepte & Themen |
   | 🔗 | Quellen |
   | 👤 | Personen & Organisationen |

4. **Summarize.** What was already fine, what got created/fixed — and,
   clearly separated, what the user still needs to do themselves (missing
   plugin installs, Outline login, `uv` for the optional
   `framework-code-navigation` if that's installed too). Point to
   `/framework:doctor` for a quick, change-free re-check anytime.

This command is idempotent — safe to re-run any time, e.g. after onboarding
a new team member or whenever something seems off.
