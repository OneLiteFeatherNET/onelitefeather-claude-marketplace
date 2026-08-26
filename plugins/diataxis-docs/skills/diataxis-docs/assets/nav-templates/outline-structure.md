# Outline layout

The unit is a hub document inside an existing collection, never a new
collection. The quadrant is a title prefix on the children.

```
Collection: Entwicklung                       exists already, do not create one
└── <Subjekt>                                 ⚙️  hub, top-level document
    ├── Tutorial: <einmaliger Lernpfad>
    ├── How-To: <Tätigkeit im Infinitiv>
    ├── Reference: <was nachgeschlagen wird>       generiert oder von Hand — pro Seite entscheiden
    │   └── Vorlage: <Name>                        templates nest under their page
    └── Explanation: <Frage, die beantwortet wird>
```

Volume and promotion rules: `SKILL.md` and
`references/publishing/outline.md`.

---

## Hub document skeleton

```markdown
Kurzbeschreibung, ein bis zwei Sätze. Diese Seite ist ein Hub — die
Inhalte liegen in den Unterseiten.

Repository: [<org/repo>](https://github.com/…) · Lizenz: <aus der LICENSE-Datei lesen> · Aktuell: **<aktuelles Release-Tag>**

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
```

---

## Mapping file

Kept in the code repository next to the generator, so it updates pages
instead of creating duplicates. Titles are not stable, IDs are.

`docs-outline.json`:

```json
{
  "collection": "Entwicklung",
  "hub": "<documentId>",
  "pages": {
    "reference/configuration.md":      "<documentId>",
    "reference/permissions.md":        "<documentId>",
    "reference/supported-versions.md": "<documentId>"
  }
}
```

## Banner at the top of the document

Only once the generator and its gate actually exist:

```
:::info
🤖 Generiert aus `src/main/resources/config.yml` durch den Workflow
`publish-docs`. Manuelle Änderungen werden beim nächsten Release
überschrieben.
:::
```

Solange es noch keinen Generator gibt, gilt stattdessen der Pending-Banner —
der obige wäre eine Falschaussage:

```
:::warning
✍️ Von Hand aus `src/main/resources/config.yml` übertragen am <Datum>. Es
gibt noch keinen Generator: vor dem Vertrauen oder Ändern dieser Seite die
Quelle erneut lesen. Offener Punkt: Generator plus CI-Drift-Gate.
:::
```

## Not the quadrants

The operational record keeps its own parent nodes and title patterns. See
`references/publishing/outline.md`, section "What the quadrants do not
cover".
