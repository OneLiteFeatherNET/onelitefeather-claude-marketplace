---
name: setup
description: Richtet die Outline-Collection "Vault" für den Wissensgraphen ein (Collection + fünf Kategorie-Dokumente) und bestätigt, dass der MCP-Server erreichbar ist.
disable-model-invocation: true
---

Richte die Grundstruktur für `vault-knowledge-graph` in Outline ein. Anders als
beim beiläufigen Setup-Schritt im Skill ist dieser Befehl ein expliziter,
vom Nutzer angestoßener Vorgang — eine fehlende "Vault"-Collection darfst du
hier direkt anlegen, ohne vorher nachzufragen.

1. Prüfe, ob der MCP-Server `outline` erreichbar ist (z. B. `list_collections`
   aufrufen). Schlägt das mit einem Auth-/Verbindungsfehler fehl, erkläre kurz,
   dass beim ersten Zugriff ein Browser-OAuth-Login gegen die Outline-Instanz
   nötig ist, und stoppe.
2. Suche die Collection **"Vault"** (`list_collections(query="Vault")`).
   - Existiert sie nicht: lege sie an (`create_collection`, Name "Vault").
   - Existiert sie bereits: weiterverwenden, nichts doppelt anlegen.
3. Prüfe mit `list_collection_documents` die Top-Level-Dokumente der Collection.
   Lege jede fehlende der fünf Kategorien an (`create_document`,
   `collectionId` = Vault-Collection, kein `parentDocumentId`):

   | Icon | Titel |
   |---|---|
   | 📚 | Research Material |
   | 🗂️ | Projekte |
   | 💡 | Konzepte & Themen |
   | 🔗 | Quellen |
   | 👤 | Personen & Organisationen |

4. Fasse am Ende kurz zusammen, was neu angelegt wurde und was schon vorhanden
   war (z. B. "Vault existierte bereits, 2 von 5 Kategorien fehlten und wurden
   angelegt: Quellen, Personen & Organisationen").

Für die eigentliche Nutzung (Wissen ablegen/abrufen) gilt danach der Skill
`vault-knowledge-graph` — dieser Befehl richtet nur die Struktur einmalig ein
und ist auch später jederzeit sicher erneut ausführbar (idempotent).
