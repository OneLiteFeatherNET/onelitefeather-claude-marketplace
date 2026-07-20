---
name: vault-knowledge-graph
description: Baut und pflegt einen Wissensgraphen in der "Vault"-Collection in Outline — legt Research Material, Projekt-Infos, Konzepte, Quellen und Personen als verknüpfte Dokumente ab und lädt später gezielt relevanten Kontext daraus. Nutze diesen Skill IMMER, wenn der Nutzer etwas "im Vault", "in Outline" oder "in der Wissensdatenbank" ablegen, festhalten oder nachschlagen will — auch wenn er nur "merk dir das", "speicher das Research dazu" oder "was wissen wir schon über X" sagt, ohne Outline oder Vault explizit zu nennen. Gilt sowohl für das Schreiben (neue Erkenntnisse, Projektstände, Recherche-Ergebnisse) als auch für das gezielte Laden von Hintergrundwissen, bevor eine Aufgabe bearbeitet wird.
---

# Vault Knowledge Graph

Dieser Skill macht aus der Outline-Collection **"Vault"** einen Wissensgraphen: Dokumente sind Knoten, gegenseitige Hyperlinks im Text sind Kanten. Outline selbst kennt keinen Graphen — die Graph-Eigenschaft entsteht ausschließlich dadurch, dass jedes Dokument seine verwandten Dokumente explizit verlinkt und diese Links in beide Richtungen gepflegt werden. Ohne konsequente Backlinks verkommt der Vault zur gewöhnlichen Dokumentenablage.

Nutze für alle Aktionen die Outline-MCP-Tools (`list_collections`, `list_collection_documents`, `list_documents`, `fetch`, `create_document`, `update_document`, `move_document`, `create_collection`). Sind sie als deferred markiert, lade sie zuerst per ToolSearch.

## Grundprinzip: Suchen vor Erstellen

Bevor du irgendetwas Neues anlegst, durchsuche den Vault (`list_documents` mit `collectionId` der Vault-Collection) nach verwandten Begriffen. Ein Wissensgraph gewinnt seinen Wert aus Verknüpfung, nicht aus der Menge an Dokumenten — ein neuer Fund ist fast immer mit etwas Bestehendem verwandt (gleiches Projekt, gleiches Konzept, gleiche Quelle). Diese Treffer werden später zu Kanten.

## Setup: Struktur sicherstellen

Ermittle die Vault-Collection-ID über `list_collections(query="Vault")`. Existiert sie nicht, frage den Nutzer nach, bevor du sie anlegst — eine neue Collection ist eine sichtbare Strukturänderung im (ggf. geteilten) Workspace.

Prüfe mit `list_collection_documents` die Top-Level-Dokumente. Fehlt eine der fünf Kategorien, lege sie an (unkritisch, reine Struktur, kein Rückfrage nötig):

| Icon | Kategorie | Gehört hinein |
|---|---|---|
| 📚 | Research Material | Paper, Artikel, Recherche-Notizen, Experimentergebnisse, Zusammenfassungen |
| 🗂️ | Projekte | Ein Dokument pro Projekt: Ziel, Status, Architektur-Entscheidungen, offene Fragen |
| 💡 | Konzepte & Themen | Wiederkehrende Begriffe, Definitionen, Muster, projektübergreifende Ideen |
| 🔗 | Quellen | Externe Referenzen: Links, Zitate, Tools, bibliografische Angaben |
| 👤 | Personen & Organisationen | Wer ist wer, Rolle, Bezug zu Projekten/Themen |

Jede Kategorie ist ein Top-Level-Dokument in der Vault-Collection, jeder einzelne Eintrag wird als Kind-Dokument darunter angelegt (`parentDocumentId`). Die Kategorie liefert also die grobe Ordnung; die eigentlichen Beziehungen zwischen Knoten — auch quer über Kategorien hinweg — entstehen über Links im Text, nicht über Verschachtelung.

## Metadaten-Block

Jedes Knoten-Dokument beginnt mit einem Metadaten-Block als Tabelle, gefolgt von einer Trennlinie und dem eigentlichen Inhalt:

```markdown
| Feld | Wert |
|---|---|
| Typ | Research Material |
| Tags | #rag #llm #retrieval #embeddings |
| Erstellt | 2026-07-20 |
| Verwandte Dokumente | [Projekt Onelitefeather](/doc/projekt-onelitefeather-abc123) · [Konzept: Retrieval](/doc/konzept-retrieval-def456) |

---

(eigentlicher Inhalt)
```

- **Tabelle statt Blockquote:** Eine frühere Version dieses Skills nutzte vier `> **Feld:**`-Zeilen in einem gemeinsamen Blockquote. Getestet gegen echtes Outline zeigte sich, dass Outline mehrzeilige Blockquotes beim Speichern zu einem einzigen Absatz zusammenfasst (die Zeilenumbrüche gehen verloren) — danach ließ sich keine einzelne Metadaten-Zeile mehr gezielt patchen. Eine Tabelle ist in Outline dagegen ein eigener Blocktyp mit echten, separat adressierbaren Zeilen und übersteht das Speichern zuverlässig.
- **Tags** sind kurz, klein geschrieben, mit `#`-Präfix, und decken zwei Ebenen ab: mindestens ein Tag für das übergeordnete Thema/Projekt (z. B. `#kundenportal`) und ein bis drei Tags für die konkreten Begriffe aus dem Inhalt (z. B. `#rag`, `#embeddings`) — so bleibt sowohl die grobe als auch die gezielte Suche später treffsicher.
- **Verwandte Dokumente** enthält die relative Outline-URL (`url`-Feld aus der Tool-Antwort von `create_document`/`fetch`), nicht nur den Titel als Text — nur so wird der Link beim Klick tatsächlich zur Kante.
- Dieser feste Aufbau ist absichtlich: Die "Verwandte Dokumente"-Zeile lässt sich später per `update_document` mit `editMode: "patch"` gezielt ändern (`findText` = die exakte bestehende Tabellenzeile, z. B. `| Verwandte Dokumente | ... |`), ohne den restlichen Inhalt anzufassen.

## Schreibkonventionen

- **Deutsche Sonderzeichen korrekt setzen:** Titel, Tags und Inhalt verwenden echte Unicode-Umlaute und ß (ä, ö, ü, ß) statt ASCII-Ersatzschreibweisen (ae, oe, ue, ss) — außer ein wörtlich zitierter Fremdtext enthält bereits die ASCII-Variante.
- **Formeln als LaTeX:** Mathematische Formeln und Gleichungen werden als LaTeX geschrieben (`$...$` inline, `$$...$$` als eigener Block) statt in Prosa umschrieben — Outline rendert LaTeX nativ, und nur so bleiben Formeln später exakt wiederverwendbar.

## Workflow: Wissen ablegen (Capture)

1. **Typ bestimmen** — welche der fünf Kategorien passt am besten. Bei echter Mehrdeutigkeit im Zweifel die naheliegendste Wahl treffen statt nachzufragen.
2. **Verwandtes suchen** — `list_documents` mit Stichworten aus dem neuen Inhalt, gefiltert auf die Vault-Collection. Die relevantesten Treffer werden zu Kanten.
3. **Dokument erstellen** — `create_document` mit Titel, Metadaten-Block + Inhalt als `text`, und `parentDocumentId` der passenden Kategorie. Fasse große Quellen (ganze Paper, lange Threads) sinnvoll zusammen statt sie 1:1 hineinzukopieren — ein Recall-Vorgang später soll gezielt laden können, nicht einen Roman durchsuchen.
4. **Backlinks pflegen** — für jedes in Schritt 2 gefundene verwandte Dokument: dessen aktuellen Text per `fetch` lesen, die vorhandene `Verwandte Dokumente`-Tabellenzeile per `update_document` (`editMode: "patch"`, `findText` = exakte bestehende Zeile, z. B. `| Verwandte Dokumente | ... |`) um den Link zum neuen Dokument ergänzen. Ohne diesen Schritt entsteht nur eine einseitige Verknüpfung — der Graph bleibt unvollständig.

## Workflow: Gezielt Kontext laden (Recall)

Ziel ist es, für eine anstehende Aufgabe genau den relevanten Ausschnitt des Vaults ins Kontextfenster zu holen — nicht möglichst viel, sondern möglichst treffend.

1. **Suchen** — `list_documents` mit den Kernbegriffen der aktuellen Aufgabe, auf die Vault-Collection eingegrenzt.
2. **Laden** — die relevantesten Treffer per `fetch(resource: "document", id)` vollständig laden.
3. **Einen Hop weitergehen** — aus deren Metadaten-Block die verlinkten Dokumente extrahieren und nur diejenigen zusätzlich laden, die für die konkrete Aufgabe plausibel beitragen. Blind der gesamten Nachbarschaft zu folgen sprengt das Kontextfenster und verwässert die Relevanz — im Zweifel lieber einen Nachbarn zu wenig als zehn zu viel laden.
4. **Verdichten** — das Ergebnis kompakt für die eigentliche Aufgabe aufbereiten (relevante Fakten, keine Rohdumps aller geladenen Dokumente).

## Weitere Leitplanken

- Lösche nie bestehende Vault-Dokumente ohne ausdrückliche Anweisung — Backlink-Pflege heißt ergänzen, nicht ersetzen.
- Wenn ein neuer Fund thematisch eindeutig zu einem bestehenden Dokument gehört (z. B. neuer Stand desselben Projekts), aktualisiere das bestehende Dokument (`update_document`, meist `editMode: "append"` oder `"patch"`) statt ein Duplikat anzulegen.
- Bei Unsicherheit über Kategorie oder Verknüpfung: eine sinnvolle Annahme treffen und sie kurz im Chat nennen, statt den Ablauf mit Rückfragen zu unterbrechen — der Nutzer kann jederzeit korrigieren.
