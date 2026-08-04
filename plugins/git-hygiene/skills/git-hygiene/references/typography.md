# Typography reference

This is the single source of truth for `detypo.pl` (the replacement script) and for the audit
command in `SKILL.md`. Every character the script or the audit command touches must appear in the
codepoint tables below, and every row in those tables must be handled by the script — the two are
kept in lockstep by hand, there is no generated artifact in between.

Scope, per the design spec's decision (c): this covers **Git/GitHub artifacts** — commit messages,
branch names, PR titles and bodies, issue and review comments, release notes, tag messages. It does
not cover repository documentation, which keeps its existing house style (see the design spec's
"inverted distributions" table: 865 em dashes across 51 of 51 markdown files in this repo, none of
which this reference asks anyone to touch).

## 1. Codepoint tables

Each row lists the exact codepoint, its Unicode name, the glyph, the ASCII form it becomes, the
action the script takes, and a usage note. **Action** is one of `DELETE` (the character is removed,
nothing replaces it) or `REPLACE` (it becomes the listed ASCII form) — see "Delete versus replace"
below for why the split falls where it does.

### Dashes and minus (U+2010-U+2015, U+2212)

| Codepoint | Name | Glyph | ASCII | Action | Notes |
|---|---|---|---|---|---|
| U+2010 | HYPHEN | ‐ | `-` | REPLACE | Visually identical to the ASCII hyphen; a direct swap. |
| U+2011 | NON-BREAKING HYPHEN | ‑ | `-` | REPLACE | Loses the no-break behavior, which is not preserved in plain-text commit/PR bodies anyway. |
| U+2012 | FIGURE DASH | ‒ | `-` | REPLACE | Rare; meant to be digit-width, indistinguishable from a hyphen once ASCII. |
| U+2013 | EN DASH | – | `-` | REPLACE | **German exception applies — see section 3.** In English text, spaced or unspaced en dash both collapse to a plain hyphen; the two-stage resolution in section 7 governs the spaced case. |
| U+2014 | EM DASH | — | ` - ` | REPLACE | Mechanical fallback is spaced hyphen; prefer the function-appropriate resolution in section 7. **Never correct in German — see section 3, it is not used there at all.** |
| U+2015 | HORIZONTAL BAR | ― | `-` or ` - ` | REPLACE | Used as a dialogue dash in some typesetting; treat like em dash when it opens a line, like en dash otherwise. |
| U+2212 | MINUS SIGN | − | `-` | REPLACE | Math minus, not a dash; still collapses to ASCII hyphen since plain text has one character for both. |

### Quotes and punctuation

| Codepoint | Name | Glyph | ASCII | Action | Notes |
|---|---|---|---|---|---|
| U+2018 | LEFT SINGLE QUOTATION MARK | ' | `'` | REPLACE | English-style opening single/apostrophe-adjacent quote. |
| U+2019 | RIGHT SINGLE QUOTATION MARK | ' | `'` | REPLACE | Also the character macOS/Word autocorrect substitutes for a plain apostrophe — watch for false positives inside contractions in code identifiers. |
| U+201C | LEFT DOUBLE QUOTATION MARK | " | `"` | REPLACE | English-style opening double quote. Also the **closing** mark of a German pair — see section 3. |
| U+201D | RIGHT DOUBLE QUOTATION MARK | " | `"` | REPLACE | English-style closing double quote. |
| U+201E | DOUBLE LOW-9 QUOTATION MARK | „ | `"` | REPLACE | German/Central-European opening double quote. **Never replace when it is half of an intact German pair — see section 3.** |
| U+201A | SINGLE LOW-9 QUOTATION MARK | ‚ | `'` | REPLACE | German/Central-European opening single quote. Same protection as U+201E. |
| U+2026 | HORIZONTAL ELLIPSIS | … | `...` | REPLACE | Three literal periods, not two or four. |

### Whitespace

| Codepoint | Name | Glyph (visual) | ASCII | Action | Notes |
|---|---|---|---|---|---|
| U+00A0 | NO-BREAK SPACE | `⎵` | ` ` | REPLACE | Common paste artifact from web pages and word processors. |
| U+202F | NARROW NO-BREAK SPACE | `⎵` | ` ` | REPLACE | Used before `%` and units in French/Duden-adjacent typesetting; still collapses to a plain space here. |
| U+2002 | EN SPACE | `⎵` | ` ` | REPLACE | |
| U+2003 | EM SPACE | `⎵` | ` ` | REPLACE | |
| U+2007 | FIGURE SPACE | `⎵` | ` ` | REPLACE | Digit-width space, sometimes used to align numbers in tables. |
| U+2009 | THIN SPACE | `⎵` | ` ` | REPLACE | |
| U+200A | HAIR SPACE | `⎵` | ` ` | REPLACE | |
| U+200B | ZERO WIDTH SPACE | *(invisible)* | *(nothing)* | **DELETE** | Renders as nothing; replacing it with a visible space would insert a space that was never there. |
| U+FEFF | ZERO WIDTH NO-BREAK SPACE (byte-order mark) | *(invisible)* | *(nothing)* | **DELETE** | A stray BOM pasted mid-text, not at file start, is pure noise. |

### Symbols

| Codepoint | Name | Glyph | ASCII | Action | Notes |
|---|---|---|---|---|---|
| U+2192 | RIGHTWARDS ARROW | → | `->` | REPLACE | |
| U+2190 | LEFTWARDS ARROW | ← | `<-` | REPLACE | |
| U+21D2 | RIGHTWARDS DOUBLE ARROW | ⇒ | `=>` | REPLACE | |
| U+21D0 | LEFTWARDS DOUBLE ARROW | ⇐ | `<=` | REPLACE | |
| U+2022 | BULLET | • | `-` | REPLACE | Only outside an existing Markdown list context — see edge case 1 in section 8, a converted bullet at line start can itself be misread as a Markdown list marker. |
| U+00D7 | MULTIPLICATION SIGN | × | `x` | REPLACE | Also appears in dimension strings like `1920×1080`; becomes `1920x1080`, no spaces added either side. |
| U+2122 | TRADE MARK SIGN | ™ | `(TM)` | REPLACE | |
| U+00A9 | COPYRIGHT SIGN | © | `(C)` | REPLACE | |

31 codepoints total across the four groups. Any character not in these tables is out of scope for
`detypo.pl` — most importantly, **umlauts and ß are never in scope** (see section 3).

## 2. Delete versus replace

The two actions are not interchangeable, and mixing them up is the single most common way a naive
implementation corrupts text:

- **Zero-width characters are deleted, never replaced with a space.** U+200B and U+FEFF render as
  nothing. Substituting a visible space in their place inserts spacing that was never visually
  present, which can turn `word` + U+200B + `word` (rendered as `wordword`) into `word word` — a
  change a human reviewer would not have made.
- **Spacing characters become a plain ASCII space (U+0020), never deleted.** U+00A0 and the rest of
  the whitespace table *do* render as visible space; deleting one collapses two words together
  (`10` + U+00A0 + `%` becomes `10%`, silently changing "10 percent" into an unspaced token). Replace,
  don't delete.
- **Dashes and quotes are replaced, never deleted.** They carry meaning (a range, a pause, a quoted
  span); deleting one leaves the surrounding text grammatically broken (`10-12` losing its dash
  becomes `1012`).

Confirmed by hand against this repository's own text:

```bash
printf 'zero\xe2\x80\x8bwidth\n' | perl -CSD -pe 's/[\x{200B}\x{FEFF}]//g'
```

produces `zerowidth` (deletion, no residual space), while

```bash
printf 'a\xc2\xa0b\n' | perl -CSD -pe 's/[\x{00A0}\x{202F}\x{2002}\x{2003}\x{2007}\x{2009}\x{200A}]/ /g'
```

produces `a b` (replacement with a real space) — both exit `0`.

## 3. German exceptions

These are orthographic facts (Duden, DIN 5008), not stylistic preferences, and `detypo.pl` gets them
wrong at its peril if it treats German prose the same way it treats a commit subject line.

- **U+2013 (en dash) with a space on both sides is the correct German dash** (the *Gedankenstrich*),
  e.g. `Der Server lief stabil – bis zum Update.` Duden and DIN 5008 both specify the spaced en dash
  here, never the em dash. **Never blanket-replace a spaced U+2013 in German text.**
- **U+2013 without surrounding spaces is the range dash** (the *Bis-Strich*), e.g. `Mo–Fr` or
  `10–12 Uhr`. This is correct in German *and* in English (`pages 10–12`). Never insert spaces around
  it during replacement, and never blanket-replace it either — collapsing `10–12` to `10-12` is a
  narrower, more defensible edit than collapsing it to `10 - 12`, but outside the Git/GitHub scope
  this reference covers, leave it alone entirely.
- **German quote pairs stay intact.** `„Hallo"` uses U+201E to open and U+201C to close — note that
  the *closing* German mark is the same codepoint (U+201C) an English-oriented script would expect to
  find *opening* an English double quote. A script that maps U+201C to `"` unconditionally, while
  leaving U+201E untouched because it "isn't in the English pairs list," produces `„Hallo"` — an
  opening low quote next to a straight ASCII closing quote, which is neither German nor English
  typography. This is the "half-typographic mush" the design spec warns about: touch both marks of a
  German pair together, or touch neither.
- **Umlauts and ß are never transliterated.** `ä`, `ö`, `ü`, `Ä`, `Ö`, `Ü` (U+00E4, U+00F6, U+00FC,
  U+00C4, U+00D6, U+00DC) and `ß` (U+00DF) are correct German letters, not typographic noise — `ä`
  must never become `ae`. Critically, **never write a codepoint range over the Latin-1 Supplement
  block** (e.g. `[\x{00C0}-\x{00FF}]`) as a "strip accents" shortcut: that range contains every one of
  the umlaut and ß codepoints above, so it would silently mangle every German word in scope.
- **U+2014 (em dash) is a tell in German, and there it is simply a spelling error.** The em dash is
  not part of German orthography at all — Duden does not list it as an alternative to the en dash.
  Its presence in German prose is not a style choice to weigh against the German exceptions above; it
  is exactly the same kind of error as a misspelled word, and correcting it is not "blanket
  replacement" in the sense this section warns against.

## 4. Protection zones

Four hard zones, where replacement must never run, plus one softer zone:

1. **Fenced code blocks** — opened by ` ``` ` or `~~~`, with up to three leading spaces of
   indentation permitted before the fence marker (the CommonMark allowance for a fence nested one
   level into a list item). Everything between the opening and matching closing fence is off-limits,
   including the language tag line itself.
2. **Inline code spans** — one or more backticks delimiting a run within a single line, e.g.
   `` `git commit --no-verify` ``. A dash or quote inside backticks is part of a literal command,
   flag, or identifier, not prose.
3. **Indented code blocks** — four or more spaces of indentation (or a tab), outside any fence and
   not part of a list item's hanging indent. This repository's own tracked markdown does not
   currently contain a bare example — every code sample here uses fences — but the zone is still
   mandatory: `detypo.pl` runs over Git/GitHub text (per the scope note in section 1), and PR bodies
   and issue comments routinely paste raw terminal output or `git diff` fragments at four-space
   indent without ever fencing them.
4. **URLs and link targets** — both bare URLs (`https://example.com/a-b`) and Markdown link targets
   (the `(...)` part of `[text](url)`, and the destination line of a reference-style link
   `[label]: https://...`). See section 5 for why this one is non-negotiable.

A fifth, softer zone:

5. **Blockquotes** (`> ` prefixed lines) — changing a quoted line changes what is being attributed to
   whoever is being quoted, which is a different kind of harm than the other four (those risk breaking
   *rendering*; this risks *misquoting*). Treat it as protected by default, but it is the one zone
   where a human reviewer overriding the default is a reasonable, deliberate choice — the other four
   are never appropriate to override.

Verified present in this repository (commands and counts, run from the repository root):

| Zone | Command | Result |
|---|---|---|
| Fenced blocks | `rg -c --hidden -g '*.md' '^ {0,3}\`\`\`'` | 34 files match (includes this file) |
| Inline code spans | `rg -c --hidden -g '*.md' '\`[^\`\n]+\`'` | 50 files match (includes this file) |
| URLs | `rg -c --hidden -g '*.md' 'https?://'` | 23 files match (includes this file) |
| Blockquotes | `rg -c --hidden -g '*.md' '^> '` | 4 files match |

(No file in this repository currently uses `~~~` fences; the marker is still recognized because
third-party PR bodies and issue comments — the actual scope of `detypo.pl` — are not under this
repository's style control.)

## 5. The URL trap

A blanket character replacement that does not honor zone 4 breaks links. Reproduced against this
exact example:

```bash
printf 'https://ex.ample/a\xe2\x80\x94b' | sed 's/—/ - /g'
```

outputs:

```
https://ex.ample/a - b
```

`https://ex.ample/a—b` is a valid, resolvable URL (the em dash is a legal, if unusual, URL
character). `https://ex.ample/a - b` is not the same URL — the path segment now contains literal
spaces — and depending on how it is rendered downstream, it is either a broken Markdown link or a
silent 404 when a reader copies it. This is not a hypothetical: `sed`, run without any URL-awareness,
does exactly this to every dash inside a URL it finds.

## 6. Two hard prohibitions

- **Never use `\p{Pd}` (Unicode general category "Dash Punctuation") as a dash detector.** It
  includes the plain ASCII hyphen-minus, U+002D — confirmed directly:

  ```bash
  printf 'a-b' | rg -c '\p{Pd}'
  ```

  outputs `1` (one matching line), exit `0`. Since nearly every Conventional Commit subject contains
  a hyphen (`fix(git-hygiene): ...`, `feat(release-please): ...`), a `\p{Pd}`-based detector flags
  essentially every commit message the audit command touches, which is not detection, it is noise.
  Use the explicit codepoint class from section 1 instead:
  `[\x{2010}-\x{2015}\x{2212}]` — it excludes U+002D by construction.

- **Never write an invisible or exotic-space character literally into a pattern's source text.**
  Always use an explicit `\x{XXXX}` escape. A character typed or pasted directly into a script or a
  regex literal can be silently normalized by an editor, a clipboard, or a copy-paste round trip
  through this very file — a U+00A0 intended in the pattern can arrive as a plain U+0020, and a
  pattern that was meant to match "non-breaking space" instead becomes `[ ]` and matches almost every
  line in the corpus. Codepoints in section 1 are the canonical source; copy the escape, not the
  glyph.

## 7. Function-appropriate resolution

Mechanical ` - ` is itself a tell. Measured on this repository: after a blanket em-dash-to-`-`
replacement, `xerus/SKILL.md`'s description contains three ` - ` on a single line — not more human,
just differently mechanical. Resolution is two-stage:

**Stage 1 — resolve by function (preferred, applied when writing or editing text):**

| Dash's function | Becomes | Example |
|---|---|---|
| Parenthetical aside | Comma pair or parentheses | `The hook (added in 2.1.183) blocks it.` instead of `The hook — added in 2.1.183 — blocks it.` |
| Explanation / elaboration | Colon | `One rule matters here: protect code fences.` instead of `One rule matters here — protect code fences.` |
| Turn / contrast | Full stop, new sentence | `The setting works. It just isn't documented.` instead of `The setting works — it just isn't documented.` |

**Stage 2 — mechanical fallback (last resort, when a script cannot infer function):** spaced hyphen
` - `. This is what `detypo.pl` falls back to when it cannot classify the dash's role. Rule of
thumb: **at most one mechanical ` - ` per paragraph.** More than that is a signal stage 1 should have
been applied instead, and it is exactly the pattern the audit command should flag as still-mechanical
rather than treat as done.

The mechanical fallback is also visibly crude in a way stage 1 is not — verified:

```bash
printf 'a\xe2\x80\x94b test line\n' | perl -CSD -pe 's/\x{2014}/-/g unless /https?:\/\//'
```

outputs `a-b test line`, tight with no spaces because the source had none either. But when the source
already carries spaces around the dash (` — `), naively substituting ` - ` for the single dash
character leaves *doubled* spaces (`  -  `) unless the script also collapses the redundant whitespace
— one more reason stage 1, applied by a human or by an editor with real judgment, does not have this
artifact at all: it is not preserving the original spacing, it is rewriting the sentence.

## 8. Four edge cases

1. **Dash at line start.** A line-initial dash followed by a space (`- `) is valid CommonMark list
   marker syntax. If an em dash opens a line (`— And another thing.`) and is replaced with a bare
   `- `, the line is reparsed as a new list item, changing block structure that was never meant to
   change. The replacement must not produce `-` immediately followed by a space at column 0 unless
   the source already was a list marker; prefer resolving by function (section 7) or escaping the
   hyphen (`\-`) at line start instead.
2. **Dash at line end.** A trailing dash at end-of-line is ambiguous between "hyphenated word wrapped
   across lines" and "sentence trails off." More importantly, if the two characters immediately before
   it are the two significant trailing spaces of a Markdown hard line break, a substitution that
   normalizes or trims trailing whitespace as a side effect (plausible, since section 2 already
   requires normalizing several kinds of trailing whitespace-like characters) can eat the hard break
   along with the dash.
3. **Dash without surrounding spaces.** An unspaced dash (`2020–2024`, `COVID-19`-style ranges) must
   stay tight after replacement — `2020-2024`, never `2020 - 2024`. Inserting spaces where the source
   had none changes an unspaced range into what reads as a parenthetical aside, which is both a
   meaning change and, per section 7, exactly the pattern that should have zero or one occurrence per
   paragraph, not one manufactured by the substitution itself.
4. **Markdown hard line breaks.** CommonMark forces a line break inside a paragraph two ways: two or
   more trailing spaces before the newline, or a trailing backslash before the newline. A whitespace
   substitution pass (section 2 turns several exotic space characters into plain spaces) must not
   collapse or strip trailing spaces as a side effect, and a dash/quote substitution pass must not
   consume a trailing backslash as part of a wider "trim trailing punctuation" step. Either mistake
   silently merges two lines the author deliberately kept apart.

## 9. Detection and replacement commands

Every command below was run against this repository while writing this reference and exited `0` or
`1` (match / no match) — never `2` (regex error). `--hidden` is required throughout: the plugin
manifests live under dot-prefixed directories (`.claude-plugin/`, `.codex-plugin/`,
`.antigravity-plugin/`), and ripgrep does not descend into a dot-directory at all without it — without
`--hidden`, a glob rooted at one of them matches zero files and ripgrep exits `2` with "No files were
searched," which is a different failure mode than a genuine no-match and is easy to misdiagnose as a
bad pattern when the real cause is the missing flag.

**Detect every in-scope codepoint, corpus-wide** (what the audit command runs):

```bash
rg -n --hidden -P '[\x{2010}-\x{2015}\x{2212}\x{2018}\x{2019}\x{201C}\x{201D}\x{201E}\x{201A}\x{2026}\x{00A0}\x{202F}\x{2002}\x{2003}\x{2007}\x{2009}\x{200A}\x{200B}\x{FEFF}\x{2192}\x{2190}\x{21D2}\x{21D0}\x{2022}\x{00D7}\x{2122}\x{00A9}]' -g '*.md' -g '*.json'
```

**Detect the same set restricted to the plugin manifests** (every `plugin.json` lives under a
dot-prefixed directory — `.claude-plugin/`, `.codex-plugin/`, `.antigravity-plugin/` — that a
non-hidden search would silently skip; glob must use `**/`, not a bare leading segment, or ripgrep
again finds nothing to search):

```bash
rg -c --hidden -P '[\x{2010}-\x{2015}\x{2212}\x{2018}\x{2019}\x{201C}\x{201D}\x{201E}\x{201A}\x{2026}\x{00A0}\x{202F}\x{2002}\x{2003}\x{2007}\x{2009}\x{200A}\x{200B}\x{FEFF}\x{2192}\x{2190}\x{21D2}\x{21D0}\x{2022}\x{00D7}\x{2122}\x{00A9}]' -g '**/*-plugin/plugin.json'
```

**Detect only dashes, the explicit codepoint class from section 6 — not the Unicode dash-punctuation
category, which is prohibited as a detector (section 6 explains why):**

```bash
rg -n --hidden -P '[\x{2010}-\x{2015}\x{2212}]' -g '*.md'
```

**Delete zero-width characters:**

```bash
perl -CSD -pe 's/[\x{200B}\x{FEFF}]//g'
```

**Replace exotic spacing characters with a plain space:**

```bash
perl -CSD -pe 's/[\x{00A0}\x{202F}\x{2002}\x{2003}\x{2007}\x{2009}\x{200A}]/ /g'
```

**Replace an em dash, skipping any line that contains a URL** (the simplest possible protection-zone
check; `detypo.pl` implements the full four-zone state machine from section 4, this is the one-line
illustration of the principle):

```bash
perl -CSD -pe 's/\x{2014}/-/g unless /https?:\/\//'
```
