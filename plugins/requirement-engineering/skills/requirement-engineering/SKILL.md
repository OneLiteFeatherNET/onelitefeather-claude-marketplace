---
name: requirement-engineering
description: Creates and restructures requirements documentation for OneLiteFeather (OLF) projects in Outline — both game concepts (Minigames, Events) and technical projects (libraries, infrastructure tools). Use when the user wants to write, plan, or clean up "Anforderungen"/"Requirements"/"User Stories" for an OLF project, document a game concept properly, restructure a superficial prose-only concept doc (e.g. old-style Minigame writeups) into a structured format, or asks about the OLF Requirement-Engineering standard. Combines User Story Mapping, EARS acceptance-criteria syntax, and MoSCoW prioritization into one lightweight format usable by both developers and non-technical designers.
---

# Requirement Engineering (OLF-Standard)

Systematisiert, wie Anforderungen für OneLiteFeather-Projekte in Outline dokumentiert werden — für Spielkonzepte (Minigames, Events) genauso wie für technische Projekte (Libraries, Infrastruktur-Tools). Der Standard ist keine Neuerfindung: er verallgemeinert das bereits gut funktionierende Muster des Projekts "Bildungs-Wirtschaftssystem" und ergänzt es um zwei Dinge, die dort fehlten — nicht-funktionale Anforderungen und präzise formulierte Akzeptanzkriterien.

Kanonische Dokumentation lebt in Outline, Collection **Entwicklung**, unter [Requirement Engineering — Start hier](https://outline.onelitefeather.dev/doc/requirement-engineering-start-hier-sga4fCEkZE). Dieser Skill ist die ausführbare Form davon — bei Widerspruch zwischen diesem Skill und den Outline-Dokumenten gewinnt Outline (dort steht die verbindliche, von Menschen gepflegte Fassung).

Nutze die Outline-MCP-Tools für jede Aktion (`list_collections`, `list_collection_documents`, `list_documents`, `fetch`, `create_document`, `update_document`, `move_document`). Falls als deferred markiert, zuerst per ToolSearch laden.

## Die drei Zutaten

| Zutat | Herkunft | Zweck |
|---|---|---|
| User Stories + Ausbaustufen | User Story Mapping (Jeff Patton) | "Als \<Rolle\> möchte ich \<Ziel\> damit \<Nutzen\>", gestaffelt nach Ausbaustufen |
| EARS-Satzschablone | Easy Approach to Requirements Syntax | Präzise Akzeptanzkriterien: When/While/If \<Bedingung\>, shall \<System\> \<Verhalten\> |
| MoSCoW-Priorisierung | BABOK | Must/Should/Could/Won't je Story und je nicht-funktionaler Anforderung |

Details, EARS-Muster-Tabelle und MoSCoW-Definitionen: [Reference: Anforderungs-Template Felder](https://outline.onelitefeather.dev/doc/reference-anforderungs-template-felder-vQZGwUNZSG).

## Dokumentstruktur

**Hauptdokument "Anforderungen: \<Projektname\>"** (Kind-Dokument des bestehenden Projekt-Parents):
1. Kontext & Ausgangslage — Fließtext: Problem, Motivation, Einordnung
2. Ziele & Nicht-Ziele
3. Stakeholder & Rollen (Tabelle: Rolle, @-Mention, Interesse)
4. Ausbaustufen-Übersicht (Tabelle: Stufe, Kurzbeschreibung, Link)
5. Nicht-funktionale Anforderungen (ID-Tabelle: NFR-001…, Kategorie, EARS-Satz, MoSCoW)
6. Offene Fragen / Risiken
7. Abnahmekriterien

**Unterdokument je Ausbaustufe "User Stories: Stufe X"**: Tabelle mit Spalten ID (`US-X.NN`) · Story · Akzeptanzkriterium (EARS) · Priorität (MoSCoW) · Status.

Zwei Varianten, siehe `references/`:
- `references/template-spielkonzept.md` — Rolle "Als Spieler", für Minigames/Events
- `references/template-technisches-projekt.md` — Rolle "Als Entwickler/Betreiber" + Spalte Schnittstelle/API-Bezug, für Libraries/Infra-Tools

Volltext-Vorlagen zum direkten Kopieren liegen auch in Outline als Kind-Dokumente der Reference-Seite: [Vorlage: Anforderungen (Spielkonzept)](https://outline.onelitefeather.dev/doc/vorlage-anforderungen-spielkonzept-TJ3GWxFdN1) · [Vorlage: Anforderungen (Technisches Projekt)](https://outline.onelitefeather.dev/doc/vorlage-anforderungen-technisches-projekt-hxhskx5niZ).

**Referenzbeispiel in der Praxis:** [Bildungs-Wirtschaftssystem](https://outline.onelitefeather.dev/doc/bildungs-wirtschaftssystem-survival-aktien-spielerisches-lernen-GAzhLaApZL), insbesondere [1. Anforderungen (Spielersicht)](https://outline.onelitefeather.dev/doc/1-anforderungen-spielersicht-MHvUiwgSPR) — siehe auch `references/beispiel-bildungswirtschaftssystem.md`.

## Workflow

1. **Modus bestimmen**: neues Projekt anlegen, bestehende Fließtext-Doku restrukturieren, oder nur den Standard nachschlagen.
2. **Projekttyp bestimmen**: Spielkonzept oder technisches Projekt → entscheidet, welche Template-Variante verwendet wird.
3. **Suchen statt duplizieren**: `list_documents`/`list_collections` prüfen, ob für das Projekt schon ein Parent-Dokument existiert (z. B. in "Konzepte - MiniGames" oder der projektspezifischen Collection). Nicht annehmen, dass es fehlt.

### A) Neues Anforderungsdokument anlegen

1. Passende Vorlage aus `references/` laden und mit den Projektinhalten füllen.
2. Als erstes Kind-Dokument des bestehenden Projekt-Parents anlegen: `create_document` mit `title: "Anforderungen: <Projektname>"`, `parentDocumentId` des Projekt-Parents.
3. Für jede Ausbaustufe ein Kind-Dokument `User Stories: Stufe X` unter dem Anforderungsdokument anlegen.
4. Ausbaustufen-Tabelle im Hauptdokument mit den echten Outline-URLs der Kind-Dokumente patchen (`editMode: "patch"`).
5. Falls dies der erste Einsatz des Standards in einer neuen Projekt-Collection ist: kurz in der Antwort erwähnen, dass der Standard unter [Requirement Engineering — Start hier](https://outline.onelitefeather.dev/doc/requirement-engineering-start-hier-sga4fCEkZE) dokumentiert ist — keine automatische Änderung an der Hub-Seite selbst nötig.

### B) Bestehendes Fließtext-Dokument restrukturieren

Der Standardfall für alte Docs wie die ursprünglichen Fassungen von SuicideTNT oder Slender.

1. Dokument per `fetch` laden.
2. Fakten extrahieren: Spielregeln/Constraints/implizite Anforderungen aus dem Fließtext herausziehen und als Entwurf für User Stories + nicht-funktionale Anforderungen formulieren (EARS + MoSCoW anwenden).
3. **Entwurf dem Nutzer vorlegen, bevor irgendetwas überschrieben wird.** Fließtext-Konzepte enthalten oft Nuancen und Designentscheidungen, die eine automatische Extraktion falsch verkürzen kann — nie kommentarlos ersetzen.
4. Nach Bestätigung: Originaltext (ggf. gekürzt) bleibt als Abschnitt "1. Kontext & Ausgangslage" erhalten statt gelöscht zu werden. Struktur wie unter A) ergänzen (Hauptdokument + Ausbaustufen-Kind-Dokumente).
5. Bestehendes Dokument per `update_document` (`editMode: "patch"` oder neues Kind-Dokument, je nachdem was weniger vom bisherigen Format zerstört) umbauen — nicht per `replace` blind überschreiben, wenn Teile erhaltenswert sind.

## Outline-Konventionen

- **Kein H1 als erste Zeile** — der Titel ist ein eigenes Feld in Outline, Inhalt beginnt mit Fließtext oder einer Überschrift ≥ H2.
- **Echte Umlaute/ß** (ä, ö, ü, ß) statt ASCII-Ersatz (ae, oe, ue, ss).
- **Cross-Referenzen immer als echter Markdown-Link** `[Titel](url)` mit der tatsächlichen Outline-URL aus der `create_document`/`fetch`-Antwort — keine Wikilink-Syntax (`[[...]]`), Outline rendert die nicht als Link.
- **Checkbox-Platzhalter ohne spitze Klammern**: `- [ ] <...>` wird von Outline beim Speichern fehlerhaft zu `- [ ] undefined<...>` konvertiert. Stattdessen `- [ ] (Beschreibung)` oder ausgeschriebene Platzhalter ohne führende `<...>` verwenden.
- @-Mentions für Personen: `@[Name](mention://user/<userId>)`, User-IDs über `list_users` ermitteln.

## Guardrails

- Nie ein bestehendes, ausführliches Dokument kommentarlos per `replace` überschreiben — Nutzer-Bestätigung vor jeder Restrukturierung einholen (siehe Workflow B).
- Bei Unsicherheit über Projekttyp (Spielkonzept vs. technisch): sinnvolle Annahme treffen und kurz in der Antwort erwähnen, statt den Workflow mit Rückfragen zu unterbrechen.
- Nicht jede NFR-Kategorie muss belegt sein — nur die tatsächlich relevanten (Performance, Sicherheit, Usability/UX, Betrieb/Ops, Kompatibilität).
