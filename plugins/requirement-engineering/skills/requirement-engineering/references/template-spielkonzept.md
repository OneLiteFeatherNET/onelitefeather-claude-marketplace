# Vorlage: Anforderungen (Spielkonzept)

Kanonisch in Outline: https://outline.onelitefeather.dev/doc/vorlage-anforderungen-spielkonzept-TJ3GWxFdN1

Rolle in User Stories: "Als Spieler". Für Minigames, Events, Spielmechaniken.

```markdown
---

**Verantwortlichkeiten:** Konzept: @<Name> · Anforderungen gepflegt von: @<Name>
**Stand (TT.MM.JJJJ):** <Datum>

---

## 1. Kontext & Ausgangslage

<Kurzer Fließtext: Problem, Motivation, Einordnung ins OLF-Ökosystem. Bei einer Umstellung aus einem bestehenden Fließtext-Dokument: der gekürzte Originaltext gehört hierhin.>

## 2. Ziele & Nicht-Ziele

**Ziele:**
* <...>

**Nicht-Ziele:**
* <...>

## 3. Stakeholder & Rollen

| Rolle | Person | Interesse |
|---|---|---|
| Game Designer | @<Name> | Definiert Spielregeln |
| Building | @<Name> | Baut die Spielumgebung |
| Entwickler | @<Name> | Setzt Spiellogik um |

## 4. Ausbaustufen-Übersicht

| Stufe | Kurzbeschreibung | Dokument |
|---|---|---|
| Stufe 1 | <...> | <Link auf "User Stories: Stufe 1" nach Anlage> |

## 5. Nicht-funktionale Anforderungen

| ID | Kategorie | Anforderung (EARS) | Priorität |
|---|---|---|---|
| NFR-001 | Performance | While eine Runde läuft, shall der Server ≤5 Ticks Verzögerung haben. | Must |

## 6. Offene Fragen / Risiken

| Frage/Risiko | Verantwortlich | Status |
|---|---|---|
| <...> | @<Name> | offen |

## 7. Abnahmekriterien

- [ ] (Abnahmekriterium beschreiben)

---

*Verwendet EARS-Syntax (When/While/If … shall …) für Akzeptanzkriterien und MoSCoW (Must/Should/Could/Won't) für Priorisierung.*
```

## Unterdokument je Ausbaustufe: "User Stories: Stufe X"

```markdown
## User Stories: Stufe <X> — <Kurzname der Stufe>

| ID | Story ("Als Spieler möchte ich … damit …") | Akzeptanzkriterium (EARS) | Priorität | Status |
|---|---|---|---|---|
| US-X.01 | Als Spieler möchte ich ... damit ... | When ..., shall ... | Must | offen |
```
