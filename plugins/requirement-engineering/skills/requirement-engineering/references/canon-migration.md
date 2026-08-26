# Migration note for the Outline canon

Since the rework, this skill writes acceptance criteria in the German EARS variant. The hub and template documents in Outline may still show the old shape.

The block below is meant to be pasted unchanged into [Requirement Engineering — Start hier](https://outline.onelitefeather.dev/doc/requirement-engineering-start-hier-sga4fCEkZE), at the end, before the change history. **A human decides whether to paste it, not the agent.**

---

## Korrektur: Akzeptanzkriterien in deutscher EARS-Fassung

Seit (Datum) gilt für neue und überarbeitete Akzeptanzkriterien ausschließlich die deutsche EARS-Fassung:

`[Solange (Zustand),] [Sofern (Feature aktiv),] [Sobald|Falls (Auslöser),] muss (das System) (Reaktion).`

Die früher hier dokumentierte Form `When/While/If (Bedingung), shall (System) (Verhalten)` war aus zwei Gründen falsch:

1. **Keine gültige EARS-Syntax.** Im Original steht das Subjekt vor dem Modalverb — `the (system) SHALL (response)` — nicht dahinter.
2. **Denglisch.** Englisches Keyword plus deutscher Satz ist in keiner der beiden Sprachen prüfbar. „Wenn" verwischt zudem die Unterscheidung Zeitpunkt (*sobald*) / Zeitraum (*solange*) / Bedingung (*falls*), die den Nutzen der Schablone ausmacht.

Bestehende Dokumente werden **nicht** rückwirkend umgeschrieben. Wer ein Kriterium ohnehin anfasst, stellt es dabei auf die neue Form um — tabellenweise, nicht zeilenweise gemischt. Durchgehend englische Dokumente nutzen weiter Original-EARS.
