---
name: doctor
description: Read-only health check for framework — reports the status of dependency plugins, the Outline MCP connection, and the Vault structure without changing anything. Safe to run anytime.
disable-model-invocation: true
---

Run a read-only diagnostic of the framework setup. Unlike `/framework:setup`,
never create, modify, or fix anything here — only report status. The point
is that a status check must never risk accidentally writing to a shared
system like Outline.

Check each of the following in order and report ✅/❌:

1. **Dependency plugins** — run `claude plugin list --json` via Bash (if the
   `claude` CLI call doesn't work that way in this environment, note that
   briefly and skip this check instead of aborting the whole command).
   Report the status of `superpowers`, `skill-creator`,
   `claude-md-management`, `code-review`, `code-simplifier`,
   `security-guidance`, `frontend-design`, `context7`, and `ralph-loop`.
   Also mention whether the optional `framework-code-navigation` is
   installed (not an error if it isn't — just informational).
2. **Outline MCP connection** — a lightweight read call (e.g.
   `list_collections`). ✅ if it responds, ❌ with the likely cause (not
   connected / needs OAuth login / server unreachable) if not.
3. **Vault structure** — does the "Vault" collection exist, and are all
   five category documents present (Research Material, Projekte, Konzepte &
   Themen, Quellen, Personen & Organisationen)?

Close with a one-line overall verdict ("Everything looks good" / "N items
need attention") and, for each ❌, the concrete next step:
`/framework:setup` for Vault structure issues, the matching
`claude plugin install <name>@claude-plugins-official` command for missing
dependencies, or a pointer to the Outline OAuth login flow.
