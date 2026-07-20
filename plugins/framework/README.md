# framework

Baut und pflegt einen **Wissensgraphen** in der Outline-Collection **"Vault"**:
Research Material, Projektwissen, Konzepte, Quellen und Personen als
verknüpfte Dokumente — und lädt später gezielt relevanten Kontext daraus,
statt ganze Dokumente in den Kontext zu dumpen.

## Was drinsteckt

- **MCP-Server `outline`** — Anthropics offizieller Outline-MCP-Server
  (seit Februar 2026 in jedem Outline-Workspace enthalten), verbunden per
  HTTP/OAuth mit `https://outline.onelitefeather.dev/mcp`.
- **Skill `vault-knowledge-graph`** — Anleitung für den Agenten, wie Dokumente
  im Vault als Graph-Knoten angelegt (Metadaten-Tabelle, Kategorien,
  Backlinks) und später gezielt wieder abgerufen werden (Suchen → Laden →
  einen Hop weitergehen → Verdichten).
- **Command `/framework:setup`** — legt die Vault-Collection und die fünf
  Kategorie-Dokumente an, falls sie noch fehlen. Idempotent, jederzeit erneut
  ausführbar (z. B. nach dem Onboarding eines neuen Teammitglieds).
- **Dependency `superpowers`** (aus `claude-plugins-official`) — wird bei der
  Installation automatisch mitinstalliert. Bringt Team-Arbeitsweisen wie
  Brainstorming vor Umsetzung, systematisches Debugging, TDD und
  strukturierte Code-Reviews mit, die unabhängig vom Vault nützlich sind.

## Install

```bash
/plugin install framework@onelitefeather-claude-marketplace
```

Installiert `superpowers@claude-plugins-official` automatisch mit (dafür
muss `claude-plugins-official` als Marketplace bereits registriert sein —
bei den meisten Setups schon der Fall; falls nicht, meldet der Installer das
und schlägt `/plugin marketplace add` vor).

Beim ersten Zugriff auf Outline öffnet sich ein Browser-Login (OAuth) —
jedes Teammitglied braucht dafür einen eigenen Outline-Account mit Zugriff auf
die "Vault"-Collection. Danach einmalig `/framework:setup` ausführen, um die
Collection und die fünf Kategorien einzurichten.

## Selbst gehostete Outline-Instanz

Die URL in `.claude-plugin/plugin.json` ist bewusst fest auf
`outline.onelitefeather.dev` eingestellt — dieses Plugin ist kein generisches
Outline-Tool, sondern das Wissensgraph-Setup für unser Team. Bei einer
Instanz-Migration muss nur diese URL angepasst werden.

## Getestet

Iterativ mit `skill-creator` gegen die echte Vault-Collection verifiziert:
Kategorie-Struktur, Metadaten-Tabellenformat (übersteht Outlines
Markdown-Speicherung zuverlässig), deutsche Sonderzeichen, LaTeX-Formeln,
Capture- und Recall-Workflow. Details siehe Commit-Historie.
