# Outline layout

The unit is a hub document inside an existing collection, never a new
collection. The quadrant is a title prefix on the children.

Collection: Entwicklung                       exists already, do not create one
└── <Subjekt>                                 ⚙️  hub, top-level document
    ├── Tutorial: <einmaliger Lernpfad>
    ├── How-To: <Tätigkeit im Infinitiv>
    ├── Reference: <was nachgeschlagen wird>       generated, do not edit
    │   └── Vorlage: <Name>                        templates nest under their page
    └── Explanation: <Frage, die beantwortet wird>

Create quadrants on demand — two how-tos and nothing else is a complete
set. Start without a hub: a single document until it serves two reader
states at once, then promote that same document (keeping title, ID and
inbound links) and move its sections out into children.

---

## Hub document skeleton

Kurzbeschreibung, ein bis zwei Sätze. Diese Seite ist ein Hub — die
Inhalte liegen in den Unterseiten.

Repository: [org/repo](https://github.com/…) · Lizenz: MIT · Aktuell: **v1.0.0**

## Wo soll ich lesen?

| Du willst… | Geh zu |
|------------|--------|
| 🎓 …es von vorn Schritt für Schritt durchgehen | [Tutorial: …](…) |
| 🛠️ …eine konkrete Sache erledigen | [How-To: …](…) |
| 📑 …einen Wert oder ein Feld nachschlagen | [Reference: …](…) |
| 💡 …verstehen, warum es so entschieden wurde | [Explanation: …](…) |

## Was ist enthalten?

Kurze Aufzählung dessen, was das Thema umfasst.

## Weiterführend

* Verwandte Hubs und Dokumente

## Pflege

Wer pflegt die Seite, was die Source of Truth ist, wohin Lücken gemeldet
werden.

---

## Mapping file

Kept in the code repository next to the generator, so it updates pages
instead of creating duplicates. Titles are not stable, IDs are.

  docs-outline.json
  {
    "collection": "Entwicklung",
    "hub": "<documentId>",
    "pages": {
      "reference/configuration.md":      "<documentId>",
      "reference/permissions.md":        "<documentId>",
      "reference/supported-versions.md": "<documentId>"
    }
  }

## Banner at the top of every generated document

:::info
🤖 Generiert aus `src/main/resources/config.yml` durch den Workflow
`publish-docs`. Manuelle Änderungen werden beim nächsten Release
überschrieben.
:::

## Not the quadrants

The operational record keeps its own parent nodes and title patterns —
design docs, plans, incidents, runbooks, ADRs, game concepts. See
`references/publishing/outline.md` and the `documenting-in-outline` skill.
