---
name: doctor
description: Guides the user through a read-only health check of framework — narrates each check (dependency plugins, Outline MCP connection, Vault structure) as it runs and ends with a clear, prioritized list of next steps. Safe to run anytime.
disable-model-invocation: true
---

Walk the user through a read-only diagnostic of the framework setup, one
check at a time — narrate what you're checking and why before each one, and
report its result immediately rather than saving everything for one big
dump at the end. Unlike `/framework:setup`, never create, modify, or fix
anything here, no matter what you find — this command exists specifically
so a status check carries zero risk of accidentally writing to a shared
system like Outline. If something's wrong, describe it and point to the
fix; don't attempt the fix yourself.

**Check 1 — Dependency plugins.** Say briefly what you're about to check,
then run `claude plugin list --json` via Bash (if that CLI call doesn't
work that way in this environment, note that plainly and move to Check 2
rather than failing the whole command). Report ✅/❌ per plugin:
`superpowers`, `skill-creator`, `claude-md-management`, `code-review`,
`code-simplifier`, `security-guidance`, `frontend-design`, `context7`,
`ralph-loop`. Also mention, purely informationally, whether the optional
`framework-code-navigation` is installed — its absence is never a ❌.

**Check 2 — Outline MCP connection.** Explain that you're testing whether
Outline actually responds, then try a lightweight read call (e.g.
`list_collections`). ✅ if it responds. If not, ❌ and name the likely cause
in plain terms (not connected yet / needs the browser OAuth login / server
unreachable) — this determines whether Check 3 can even be meaningful.

**Check 3 — Vault structure.** If Check 2 failed, say so and skip this
check rather than pretending it can run against a dead connection. Otherwise
verify the "Vault" collection exists and all five category documents are
present (Research Material, Projekte, Konzepte & Themen, Quellen, Personen &
Organisationen); ✅/❌ overall, naming any missing category by name.

**Wrap-up.** Close with a one-line overall verdict ("Everything looks good"
or "N items need attention") followed by a short, prioritized list: for
each ❌, the concrete next action — `/framework:setup` for anything it can
fix directly (Vault structure, and it'll re-check the connection too), the
matching `claude plugin install <name>@claude-plugins-official` command for
each missing dependency, or a pointer to complete the Outline OAuth login.
Order the list so the Outline connection (if broken) comes first, since it
blocks the Vault check.
