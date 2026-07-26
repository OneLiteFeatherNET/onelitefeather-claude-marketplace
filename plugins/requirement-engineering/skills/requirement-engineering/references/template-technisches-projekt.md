# Vorlage: Anforderungen (Technisches Projekt)

Kanonisch in Outline: https://outline.onelitefeather.dev/doc/vorlage-anforderungen-technisches-projekt-hxhskx5niZ

Rolle in User Stories: "Als Entwickler/Betreiber". Für Libraries, Infrastruktur-Tools. Zusätzliche Spalte "Schnittstelle/API-Bezug" statt Spielmechanik-Bezug.

```markdown
---

**Verantwortlichkeiten:** Konzept: @<Name> · Anforderungen gepflegt von: @<Name>
**Stand (TT.MM.JJJJ):** <Datum>

---

## 1. Kontext & Ausgangslage

<Kurzer Fließtext: Problem, Motivation, Einordnung ins OLF-Ökosystem — z. B. welche anderen Repos/Projekte davon abhängen.>

## 2. Ziele & Nicht-Ziele

**Ziele:**
* <...>

**Nicht-Ziele:**
* <...>

## 3. Stakeholder & Rollen

| Rolle | Person | Interesse |
|---|---|---|
| Maintainer | @<Name> | Verantwortlich für Architektur & Reviews |
| Betreiber | @<Name> | Betreibt das Deployment (z. B. CloudNet, Kubernetes) |

## 4. Ausbaustufen-Übersicht

| Stufe | Kurzbeschreibung | Dokument |
|---|---|---|
| Stufe 1 | <...> | <Link auf "User Stories: Stufe 1" nach Anlage> |

## 5. Nicht-funktionale Anforderungen

| ID | Kategorie | Anforderung (EARS) | Priorität |
|---|---|---|---|
| NFR-001 | Kompatibilität | The <Library> shall mit Minestom-Version <X> kompatibel sein. | Must |
| NFR-002 | Sicherheit | If eine ungültige Konfiguration geladen wird, then shall das System beim Start fehlschlagen statt stillschweigend Defaults zu verwenden. | Must |

## 6. Offene Fragen / Risiken

| Frage/Risiko | Verantwortlich | Status |
|---|---|---|
| <...> | @<Name> | offen |

## 7. Abnahmekriterien

- [ ] (Abnahmekriterium beschreiben)

---

*Verwendet EARS-Syntax und MoSCoW wie die Spielkonzept-Variante. Rollen sind "Entwickler/Betreiber" statt "Spieler".*
```

## Unterdokument je Ausbaustufe: "User Stories: Stufe X"

```markdown
## User Stories: Stufe <X> — <Kurzname der Stufe>

| ID | Story ("Als Entwickler/Betreiber möchte ich … damit …") | Akzeptanzkriterium (EARS) | Schnittstelle/API-Bezug | Priorität | Status |
|---|---|---|---|---|---|
| US-X.01 | Als Betreiber möchte ich ... damit ... | When ..., shall ... | <API/Endpoint/Config> | Must | offen |
```
