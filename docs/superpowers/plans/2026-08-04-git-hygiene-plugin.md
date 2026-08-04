# Git Hygiene Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new `git-hygiene` plugin to this Claude Code plugin marketplace — a skill that keeps
commit messages, branch names, PR titles and bodies, issue comments and release notes free of AI
tool branding, session URLs, machine typography and machine phrasing — per
`docs/superpowers/specs/2026-08-04-git-hygiene-plugin-design.md`.

**Architecture:** One skill (`git-hygiene`) with four `references/` files, one explicit-trigger
command (`setup`), one `PreToolUse` hook, and three scripts. The skill body carries the always-loaded
rules; the references carry the lookup tables. The settings snippet is the primary mechanism and is
delivered by the command, because a plugin cannot ship the `attribution` setting itself. The hook
and the scripts are the safety net. All three plugin manifests ship (`.claude-plugin`,
`.codex-plugin`, `.antigravity-plugin`) with the hook and command documented as not carrying over.
The plugin is then added to `framework`'s `dependencies` array so it installs and enables
automatically with the core bundle, without giving up its standalone installability.

**Tech Stack:** Markdown with YAML frontmatter, JSON (manifests, `hooks.json`), POSIX shell and Perl
for the scripts. No build step and no test framework in this repo — "tests" here are structural
checks (`jq`, `grep`, `claude plugin validate`) plus behavioural checks of the scripts against
fixture messages, matching `docs/superpowers/plans/2026-07-25-agent-orchestrator-plugin.md`.

## Global Constraints

- Plugin name: `git-hygiene`. Skill name: `git-hygiene`. Command name: `setup` (invoked as
  `/git-hygiene:setup`). All lowercase, kebab-case.
- `SKILL.md` frontmatter: exactly `name` and `description`, no other keys.
- `commands/setup.md` frontmatter: `name`, `description`, `disable-model-invocation: true`.
- Skill body and all references are **English**. German typography is content, not language — it is
  documented in English with German examples.
- **Scope is Git/GitHub artifacts only.** No task in this plan modifies `README.md` prose, existing
  `SKILL.md` files, `docs/`, or any `description` field of an existing plugin *for typographic
  reasons*. The only edits to existing files are the registration entries in Task 12 and the
  `framework` bundling in Task 13 — both functional, neither a style fix.
- The plugin ships as a `framework` dependency so it is installed everywhere by default (Task 13),
  while remaining a standalone, separately installable plugin.
- The settings block is exactly `{"attribution": {"commit": "", "pr": "", "sessionUrl": false}}`.
  `includeCoAuthoredBy` may appear only as a labelled legacy fallback; `gitAttribution` must never
  appear except in the anti-pattern block that names it as non-existent.
- Detection patterns must be **case-insensitive** and **model-name-agnostic**. Never hardcode a model
  name. Never match on the bare keyword `claude` or `anthropic` — this repo legitimately mentions
  both 11 times in commit bodies and in 14 markdown files.
- Never use `\p{Pd}` as a dash detector. Never write an invisible character literally into a pattern
  — always `\x{...}` or `printf '\xNN'`.
- Protected trailers that no script may ever touch: `Signed-off-by:`, `BREAKING CHANGE:` /
  `BREAKING-CHANGE:`, `Refs:` / `Fixes:` / `Closes:`, `Release-As:`, and any `Co-authored-by:` whose
  address is not a known bot address.
- Every manifest and `marketplace.json` must remain valid JSON (`jq empty <file>` exits 0).
- Every shipped script must be executable (`chmod +x`) and pass `shellcheck` where available.
- **The plan's own commits must comply with the skill they add.** No trailers, no session URLs, no
  em dashes in commit messages.

---

### Task 1: Plugin scaffold — three manifests

**Files:**
- Create: `plugins/git-hygiene/.claude-plugin/plugin.json`
- Create: `plugins/git-hygiene/.codex-plugin/plugin.json`
- Create: `plugins/git-hygiene/.antigravity-plugin/plugin.json`

**Interfaces:** Produces the plugin directory that Tasks 2-11 populate. The Codex manifest adds
`"skills": "./skills/"` and `"hooks": {}`; the Antigravity manifest adds only `"skills": "./skills/"`;
neither carries `displayName`. This mirrors `plugins/release-engineering/` exactly.

- [ ] **Step 1: Verify the directory does not exist yet**

```bash
test -d plugins/git-hygiene && echo "UNEXPECTED: already exists" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Write the three manifests**

`.claude-plugin/plugin.json`:

```json
{
  "name": "git-hygiene",
  "displayName": "Git Hygiene",
  "version": "0.1.0",
  "description": "Keeps commit messages, branch names, PR titles and bodies, issue comments and release notes free of AI tool branding, session URLs, machine typography and machine phrasing. Ships the attribution settings, a PreToolUse safety net, and an optional commit-msg hook.",
  "author": { "name": "OneLiteFeather", "url": "https://github.com/OneLiteFeatherNET" },
  "license": "MIT",
  "keywords": ["git", "github", "commit-messages", "pull-requests", "attribution", "typography", "conventional-commits"]
}
```

The Codex and Antigravity manifests carry the same `name`, `version`, `description`, `author`,
`license` and `keywords`, drop `displayName`, and add the keys described under Interfaces.

- [ ] **Step 3: Verify all three are valid JSON with matching names**

```bash
for f in plugins/git-hygiene/.*-plugin/plugin.json; do
  jq -e '.name == "git-hygiene"' "$f" >/dev/null && echo "OK: $f" || echo "FAIL: $f"
done
```

Expected: three `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/git-hygiene/
git commit -m "feat: scaffold git-hygiene plugin manifests"
```

---

### Task 2: `references/attribution.md`

**Files:**
- Create: `plugins/git-hygiene/skills/git-hygiene/references/attribution.md`

**Interfaces:** Consumed by `SKILL.md` (Task 6) under "Further reference" and by `commands/setup.md`
(Task 11), which implements the setup path this file documents. Task 8's guard script implements the
detection patterns defined here — the patterns must be written once here and referenced, not
duplicated with drift.

**Required content:**

1. The settings block, all three keys, with the note that `commit` + `pr` alone leave the session
   trailer in place.
2. Settings precedence: managed (`/etc/claude-code/managed-settings.json`) > CLI flags >
   `.claude/settings.local.json` > `.claude/settings.json` > user settings. Plus the verified fact
   that a committed project `attribution` applies even in an untrusted workspace, while
   `permissions.allow` from the same file does not.
3. Minimum versions: `attribution.sessionUrl` needs >= 2.1.183, `includeGitInstructions` needs
   >= 2.1.78 (bugfix). How to check: `claude --version`.
4. The self-test: how to confirm the instruction is gone rather than merely filtered.
5. **Anti-pattern block** naming `includeCoAuthoredBy` (deprecated, covers only the commit trailer)
   and `gitAttribution` (does not exist, silently ignored, creates false confidence).
6. The four leak paths, each with its mitigation:
   - `gh pr create --fill` / `--fill-verbose` / `--fill-first` copies contaminated commit bodies into
     the PR body regardless of `attribution.pr`.
   - Squash merge with `squash_merge_commit_message: COMMIT_MESSAGES` copies commit bodies onto the
     default branch permanently. Include the `gh api` command to read and to change the setting.
   - CI committers and GitHub App bot accounts.
   - Release notes and `CHANGELOG.md` generated from commit messages (state this as a mechanism, and
     mark the specific Release Please trailer-passthrough behaviour as **unverified** — no agent
     could confirm it and no OLF repo with a generated CHANGELOG was available locally).
7. `includeGitInstructions: false` as a footnote for CLIs older than 2.1.183, with the explicit
   warning that it also removes the git status snapshot and the built-in commit workflow guidance.

- [ ] **Step 1: Write the file**
- [ ] **Step 2: Verify the forbidden keys appear only in the anti-pattern block**

```bash
grep -n 'gitAttribution' plugins/git-hygiene/skills/git-hygiene/references/attribution.md
```

Expected: hits only on lines inside the anti-pattern section, each marked as non-existent.

- [ ] **Step 3: Verify no model name is hardcoded as a required literal**

```bash
grep -nE 'Claude (Sonnet|Opus|Haiku) [0-9]' plugins/git-hygiene/skills/git-hygiene/references/attribution.md
```

Expected: hits only in illustrative examples, never inside a pattern the reader is told to use.

- [ ] **Step 4: Commit**

```bash
git add plugins/git-hygiene/skills/git-hygiene/references/attribution.md
git commit -m "feat: add attribution reference for git-hygiene"
```

---

### Task 3: `references/typography.md`

**Files:**
- Create: `plugins/git-hygiene/skills/git-hygiene/references/typography.md`

**Interfaces:** The codepoint table defined here is the single source of truth for Task 9's
`detypo.pl` and for the audit command in `SKILL.md`. Any character in the script must appear in this
table and vice versa.

**Required content:**

1. **Four codepoint groups**, each row: codepoint, name, glyph, ASCII replacement, notes.
   - Dashes: U+2010-U+2015 (figure dash, en dash, em dash, horizontal bar), U+2212 minus.
   - Quotes and punctuation: U+2018, U+2019, U+201C, U+201D, U+201E, U+201A, U+2026.
   - Whitespace: U+00A0, U+202F, U+2002, U+2003, U+2007, U+2009, U+200A, U+200B, U+FEFF.
   - Symbols: U+2192, U+2190, U+21D2, U+21D0, U+2022, U+00D7, trademark and copyright signs.
2. **Delete versus replace** kept strictly apart: zero-width characters are deleted, spacing
   characters become a plain space, dashes and quotes are replaced.
3. **German exceptions**, prominently and unambiguously:
   - U+2013 with surrounding spaces is the orthographically correct German dash (Duden, DIN 5008);
     without spaces it is the range dash. Never blanket-replaced in German text.
   - German quote pairs stay intact; blanket replacement produces half-typographic mush.
   - Umlauts and ß are never transliterated. Never put a range over Latin-1.
   - In German, U+2014 *is* a tell, and there it is simply a spelling error.
4. **The four protection zones**, all four verified present in this repo: fenced code blocks (both
   ``` and ~~~, including up to 3 leading spaces), inline code spans, indented code blocks, URLs and
   link targets. Plus blockquotes as a fifth, softer zone (changing them falsifies a quotation).
5. **The URL trap**, spelled out with the reproduced example: `https://ex.ample/a—b` becoming
   `.../a - b` is a silent 404.
6. **The two hard prohibitions**: `\p{Pd}` as a detector (matches the ASCII hyphen, and nearly every
   Conventional Commit message contains one), and invisible characters written literally into a
   pattern.
7. **Function-appropriate resolution**, since mechanical ` - ` is itself a tell: parenthetical aside
   becomes a comma pair or parentheses, explanation becomes a colon, turn becomes a full stop and a
   new sentence. Rule of thumb: at most one ` - ` per paragraph.
8. **Four edge cases**: dash at line start (must not become a stray list bullet or leading
   whitespace), dash at line end, dash without surrounding spaces, markdown hard line breaks.
9. Verified `rg` detection commands and `perl` replacement commands, with `--hidden` wired in so the
   ten manifest JSONs under the dot-prefixed plugin directories are not missed.

- [ ] **Step 1: Write the file**
- [ ] **Step 2: Verify `\p{Pd}` appears only as a prohibition**

```bash
grep -n 'p{Pd}' plugins/git-hygiene/skills/git-hygiene/references/typography.md
```

Expected: every hit is inside the prohibition section.

- [ ] **Step 3: Verify each documented rg command actually runs**

Run each command block from the file against the repo. Every one must exit 0 or 1 (match / no match),
never 2 (regex error).

- [ ] **Step 4: Commit**

```bash
git add plugins/git-hygiene/skills/git-hygiene/references/typography.md
git commit -m "feat: add typography reference for git-hygiene"
```

---

### Task 4: `references/ai-tells.md`

**Files:**
- Create: `plugins/git-hygiene/skills/git-hygiene/references/ai-tells.md`

**Interfaces:** Consumed by `SKILL.md`'s "Phrasing" section. This file is documentation only — no
script implements it, deliberately, because the false-positive rate on phrasing is too high to
automate.

**Required content:**

1. **Categories, not a word list**: antithesis ("not just X, it's Y"), ritual openers and closers,
   self-praise and significance inflation, forced three-item structure, formatting excess (nested
   bullets, emoji in headings, bold lead-ins).
2. The evidence-backed vocabulary cluster *with a context rule attached* — "delve" (frequency ratio
   28.0 against human baseline), "underscores" (13.8), "showcasing" (10.7). Each entry states when
   the word is legitimate.
3. **The do-not-touch list**, which matters more than the tell list: imperative mood, Conventional
   Commit prefixes, absent contractions, domain terms that merely sound inflated ("robust error
   handling", "critical" as a severity level), and an existing PR template — a project's own template
   always wins.
4. The correction to the obvious-but-wrong rule: a "Summary / Changes / Testing" structure is **not**
   the problem; empty content under those headings is. Requirement: every heading must carry a
   checkable fact.
5. **The strongest signal is substantive, not stylistic**: missing particulars — filename, function
   name, ticket number, the concrete failure case. Human commits are uneven in length; AI commits are
   uniformly thorough.
6. The Wikipedia warning quoted verbatim, with the conclusion drawn explicitly: the goal is "sounds
   like the people in this repository", not "beats a detector".
7. Few-shot before/after examples taken from this repository's real history.

- [ ] **Step 1: Write the file**
- [ ] **Step 2: Verify the do-not-touch list is present and non-trivial**

```bash
grep -c '^| ' plugins/git-hygiene/skills/git-hygiene/references/ai-tells.md
```

Expected: a table with at least 8 do-not-touch rows.

- [ ] **Step 3: Commit**

```bash
git add plugins/git-hygiene/skills/git-hygiene/references/ai-tells.md
git commit -m "feat: add ai-tells reference for git-hygiene"
```

---

### Task 5: `references/enforcement.md`

**Files:**
- Create: `plugins/git-hygiene/skills/git-hygiene/references/enforcement.md`

**Interfaces:** Documents the contracts that Tasks 8, 9 and 10 implement. The hook JSON shape shown
here must match `hooks/hooks.json` byte-for-byte in structure.

**Required content:**

1. The `PreToolUse` contract, stated so it cannot be got wrong: **exit 1 does not block**. Only
   exit 0 with `{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny",
   ...}}`, or exit 2 with a message on stderr.
2. The `if` pre-filter syntax (`"if": "Bash(git commit:*)"`) and the fact that `matcher` only matches
   the tool name.
3. Hook merging: user, project and plugin hooks are merged and run in parallel; the first `deny`
   wins immediately.
4. The `--body-file` blind spot and the extraction loop that covers it (also intercept the `Write`
   tool when the target path looks like a PR or commit body).
5. The `--no-verify` scoping bug: detection must be limited to `git commit|merge|push|tag`, otherwise
   `gh release create -n "Release notes"` is falsely blocked because there `-n` means `--notes`.
6. The `set -euo pipefail` trap: an empty `grep` result exits 1 and aborts the script.
7. The `commit-msg` git hook plus the `core.hooksPath` bootstrap, and the verified caveat that
   `core.hooksPath` is **not** carried over on clone (it lives in `.git/config`), plus the fact that
   `git commit --no-verify` bypasses it entirely. This is why the git hook is opt-in and not
   installed automatically.
8. A CI job sketch over `gh pr view --json title,body,commits`.
9. Audit and remediation commands for the existing state, explicitly read-only.

- [ ] **Step 1: Write the file**
- [ ] **Step 2: Verify the exit-code contract is stated unambiguously**

```bash
grep -n 'exit 1' plugins/git-hygiene/skills/git-hygiene/references/enforcement.md
```

Expected: at least one line stating that exit 1 does *not* block.

- [ ] **Step 3: Commit**

```bash
git add plugins/git-hygiene/skills/git-hygiene/references/enforcement.md
git commit -m "feat: add enforcement reference for git-hygiene"
```

---

### Task 6: `SKILL.md`

**Files:**
- Create: `plugins/git-hygiene/skills/git-hygiene/SKILL.md`

**Interfaces:** The entry point. Links all four references under "Further reference" and
cross-references `release-engineering:release-please` for the commit -> CHANGELOG -> release notes
chain. Target length ~140 lines, within the repo's 59-301 range.

**Required structure:**

```
---
name: git-hygiene
description: <English, 3-5 lines. Names the artifacts: writing a commit message,
             opening a PR with `gh pr create`, writing a PR title or body, commenting
             on an issue or review, naming a branch, drafting release notes. States
             the exclusion: not for prose in repo docs, READMEs or skill files.>
---

# Git Hygiene

<4 lines on why: CLA compatibility, session URL as an information leak, the
 commit -> CHANGELOG -> public release notes chain. No mention of detection.>

## Scope                      table: in scope | out of scope
## Step 1: turn it off at the source    the settings block + anti-pattern block
## Never emit these           the four artifacts, model-agnostic, case-insensitive
## Never touch these          Signed-off-by, BREAKING CHANGE, Refs/Fixes/Closes, human Co-authored-by
## Typography                 ASCII rule, function-appropriate resolution, German exception, protection zones
## Phrasing                   concrete over vague, no self-praise, no ritual sentences, uneven length is normal
## ANTI-PATTERN / good example   one full bad commit next to its cleaned version
## Verify before you push     two commands: attribution audit, typography audit (with --hidden)
## Contributing to repos you do not own   policy check first, never forge Signed-off-by
## Further reference          four lines, one per reference, plus the release-please cross-link
```

- [ ] **Step 1: Write the file**
- [ ] **Step 2: Verify frontmatter has exactly `name` and `description`**

```bash
awk '/^---$/{n++; next} n==1 && /^[a-z-]+:/{print $1}' \
  plugins/git-hygiene/skills/git-hygiene/SKILL.md
```

Expected: exactly `name:` and `description:`.

- [ ] **Step 3: Verify all four references are linked and all four files exist**

```bash
for r in attribution typography ai-tells enforcement; do
  grep -q "references/$r.md" plugins/git-hygiene/skills/git-hygiene/SKILL.md \
    && test -f "plugins/git-hygiene/skills/git-hygiene/references/$r.md" \
    && echo "OK: $r" || echo "FAIL: $r"
done
```

Expected: four `OK:` lines.

- [ ] **Step 4: Verify the skill practises what it preaches**

```bash
rg --pcre2 -n '[\x{2010}-\x{2015}\x{2018}\x{2019}\x{201C}\x{201D}\x{2026}\x{00A0}\x{200B}]' \
  plugins/git-hygiene/skills/git-hygiene/SKILL.md
```

Expected: hits only inside the codepoint examples and the anti-pattern block, nowhere in prose.
This file is the one place in the repo where the ASCII rule is applied to documentation, because it
is the skill's own showcase.

- [ ] **Step 5: Commit**

```bash
git add plugins/git-hygiene/skills/git-hygiene/SKILL.md
git commit -m "feat: add git-hygiene skill"
```

---

### Task 7: `scripts/strip-attribution.sh`

**Files:**
- Create: `plugins/git-hygiene/scripts/strip-attribution.sh`

**Interfaces:** Reads a message on stdin or from a file argument, writes the cleaned message to
stdout. Used by Task 8's guard (detection mode, `--check`) and Task 10's commit-msg hook (rewrite
mode). Exit 0 clean, exit 1 when `--check` finds something.

**Behaviour:** Removes lines matching, case-insensitively:
- a co-author trailer whose address is a known harness bot address (generalized beyond
  `noreply@anthropic.com`),
- `^Claude-Session:` and equivalent session trailers,
- the `🤖 Generated with [...]` footer line and a bare harness session URL on its own line.

Everything else survives, including every protected trailer from the Global Constraints.

- [ ] **Step 1: Write a failing behavioural test**

Create a fixture message containing, in this order: a subject line, a body line mentioning "Claude
Code" as a product name, `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`,
`Claude-Session: https://claude.ai/code/session_abc`, `Co-authored-by: TheMeinerLP <x@y.z>`,
`Signed-off-by: TheMeinerLP <x@y.z>`, and `Refs: #42`.

```bash
test -x plugins/git-hygiene/scripts/strip-attribution.sh \
  && echo "UNEXPECTED: exists" || echo "OK: missing as expected"
```

- [ ] **Step 2: Write the script**
- [ ] **Step 3: Verify machine and human are separated correctly**

```bash
out=$(plugins/git-hygiene/scripts/strip-attribution.sh < /tmp/fixture-msg.txt)
echo "$out" | grep -qi 'noreply@anthropic' && echo "FAIL: bot trailer survived" || echo "OK: bot trailer gone"
echo "$out" | grep -q 'Claude-Session'      && echo "FAIL: session survived"     || echo "OK: session gone"
echo "$out" | grep -q 'TheMeinerLP'         && echo "OK: human trailer kept"     || echo "FAIL: human trailer lost"
echo "$out" | grep -q 'Signed-off-by'       && echo "OK: sign-off kept"          || echo "FAIL: sign-off lost"
echo "$out" | grep -q 'Refs: #42'           && echo "OK: refs kept"              || echo "FAIL: refs lost"
echo "$out" | grep -q 'Claude Code'         && echo "OK: product mention kept"   || echo "FAIL: over-stripped"
```

Expected: six `OK:` lines. The last one is the regression guard against keyword blocking.

- [ ] **Step 4: Verify the lowercase variant is caught**

Repeat with `Co-authored-by:` lowercase — the one form that `git log --grep` missed and that caused
the 37-versus-38 discrepancy during research.

- [ ] **Step 5: `chmod +x`, shellcheck, commit**

```bash
chmod +x plugins/git-hygiene/scripts/strip-attribution.sh
command -v shellcheck >/dev/null && shellcheck plugins/git-hygiene/scripts/strip-attribution.sh
git add plugins/git-hygiene/scripts/strip-attribution.sh
git commit -m "feat: add attribution stripper script"
```

---

### Task 8: `hooks/hooks.json` and `scripts/guard.sh`

**Files:**
- Create: `plugins/git-hygiene/hooks/hooks.json`
- Create: `plugins/git-hygiene/scripts/guard.sh`

**Interfaces:** `hooks.json` registers a `PreToolUse` hook with `matcher: "Bash"`, pre-filtered by
`if` to git and gh commands, invoking `"${CLAUDE_PLUGIN_ROOT}"/scripts/guard.sh`. The guard calls
Task 7's stripper in `--check` mode.

**Behaviour, graded exactly as decided:**
- **Deny** (exit 0 + `permissionDecision: "deny"`) on the four deterministic attribution patterns.
  These have zero false-positive risk, so hard blocking is justified.
- **Warn only** (allow, with a message) on typography and phrasing. Their false-positive rate is
  documented as high; blocking would be unbearable.
- Scope `--no-verify` detection to `git commit|merge|push|tag` so `gh release create -n` is not hit.

- [ ] **Step 1: Write a failing test — the hook must not exist yet**
- [ ] **Step 2: Write both files**
- [ ] **Step 3: Verify `hooks.json` is valid JSON with the right shape**

```bash
jq -e '.hooks.PreToolUse[0].matcher == "Bash"' plugins/git-hygiene/hooks/hooks.json >/dev/null \
  && echo "OK" || echo "FAIL"
```

- [ ] **Step 4: Verify the deny path emits the correct contract**

```bash
echo '{"tool_input":{"command":"git commit -m \"fix: x\n\nCo-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>\""}}' \
  | plugins/git-hygiene/scripts/guard.sh; echo "exit=$?"
```

Expected: exit 0, stdout containing `"permissionDecision":"deny"`. Explicitly assert the exit code is
0 and not 1 — exit 1 would not block.

- [ ] **Step 5: Verify the false-positive guards**

```bash
echo '{"tool_input":{"command":"gh release create v1.0.0 -n \"Release notes\""}}' \
  | plugins/git-hygiene/scripts/guard.sh; echo "exit=$?"
echo '{"tool_input":{"command":"git commit -m \"feat: add multi-word-flag support\""}}' \
  | plugins/git-hygiene/scripts/guard.sh; echo "exit=$?"
```

Expected: both allowed. The second is the `\p{Pd}` regression guard — a hyphenated Conventional
Commit subject must never be blocked.

- [ ] **Step 6: Verify the whole plugin validates**

```bash
claude plugin validate plugins/git-hygiene
```

- [ ] **Step 7: Commit**

```bash
chmod +x plugins/git-hygiene/scripts/guard.sh
git add plugins/git-hygiene/hooks/ plugins/git-hygiene/scripts/guard.sh
git commit -m "feat: add PreToolUse guard hook for git-hygiene"
```

---

### Task 9: `scripts/detypo.pl`

**Files:**
- Create: `plugins/git-hygiene/scripts/detypo.pl`

**Interfaces:** `detypo.pl [--check] [--lang=de|en] [file...]`. `--check` reports and exits 1 on
findings without modifying anything; without it, rewrites to stdout. Implements exactly the codepoint
table from Task 3.

**Behaviour:**
- Protection zones enforced: fenced code blocks (``` and ~~~, up to 3 leading spaces), inline code
  spans, indented blocks, URLs and link targets, blockquotes.
- `--lang=de` leaves U+2013 and German quote pairs alone, still removes U+2014 and invisible
  characters.
- Never touches umlauts or ß. No range over Latin-1.
- At most one ` - ` per paragraph; beyond that it reports rather than replaces, because mechanical
  ` - ` is itself a tell and the resolution needs a human or the model.

- [ ] **Step 1: Write a failing test on a fixture with all four protection zones**

The fixture must contain: an em dash in prose, one inside a fenced block, one inside inline code, one
inside a URL, one inside a blockquote, a German sentence with a spaced U+2013, a word with umlauts
and ß, an NBSP, and a zero-width space.

- [ ] **Step 2: Write the script**
- [ ] **Step 3: Verify the protection zones hold**

```bash
perl plugins/git-hygiene/scripts/detypo.pl /tmp/fixture-typo.md > /tmp/out-typo.md
diff <(sed -n '/^```/,/^```/p' /tmp/fixture-typo.md) <(sed -n '/^```/,/^```/p' /tmp/out-typo.md) \
  && echo "OK: code fence untouched" || echo "FAIL: code fence modified"
grep -q 'ex.ample/a—b' /tmp/out-typo.md && echo "OK: URL untouched" || echo "FAIL: URL broken"
```

- [ ] **Step 4: Verify the German mode**

```bash
perl plugins/git-hygiene/scripts/detypo.pl --lang=de /tmp/fixture-typo.md \
  | grep -q 'Größe' && echo "OK: umlauts intact" || echo "FAIL: umlauts mangled"
```

Also assert the spaced U+2013 survives in `--lang=de` and that U+2014 does not.

- [ ] **Step 5: Verify `--check` is read-only**

```bash
cp /tmp/fixture-typo.md /tmp/fixture-typo.bak
perl plugins/git-hygiene/scripts/detypo.pl --check /tmp/fixture-typo.md; echo "exit=$?"
diff /tmp/fixture-typo.md /tmp/fixture-typo.bak && echo "OK: unmodified" || echo "FAIL: modified"
```

Expected: exit 1 (findings) and an unmodified file.

- [ ] **Step 6: Commit**

```bash
chmod +x plugins/git-hygiene/scripts/detypo.pl
git add plugins/git-hygiene/scripts/detypo.pl
git commit -m "feat: add context-aware typography script"
```

---

### Task 10: `scripts/commit-msg` (opt-in git hook)

**Files:**
- Create: `plugins/git-hygiene/scripts/commit-msg`

**Interfaces:** A standard git `commit-msg` hook taking the message file as `$1`. Installed only by
`/git-hygiene:setup` on explicit confirmation, never automatically.

**Behaviour:** Strips attribution in place via Task 7's script. Reports typography findings and
**fails the commit** rather than rewriting prose silently — an author must never discover their
message was altered behind their back. Skips comment lines starting with `#`.

- [ ] **Step 1: Write a failing test in a scratch repo**

```bash
git init /tmp/hooktest && cd /tmp/hooktest
```

- [ ] **Step 2: Write the hook, install it, verify it strips attribution and blocks typography**
- [ ] **Step 3: Verify the documented bypass is real and stated**

```bash
git commit --no-verify -m "test: bypass"; echo "exit=$?"
```

Expected: succeeds. This must be documented in `references/enforcement.md` as a known limitation, not
worked around.

- [ ] **Step 4: Commit**

```bash
chmod +x plugins/git-hygiene/scripts/commit-msg
git add plugins/git-hygiene/scripts/commit-msg
git commit -m "feat: add optional commit-msg hook"
```

---

### Task 11: `commands/setup.md`

**Files:**
- Create: `plugins/git-hygiene/commands/setup.md`

**Interfaces:** `/git-hygiene:setup`, `disable-model-invocation: true`. Follows the guided-walkthrough
style of `plugins/framework/commands/setup.md` — announce each step, report each result, pause where
the user must act.

**Steps the command performs:**

1. Report `claude --version` against the 2.1.183 minimum for `attribution.sessionUrl`.
2. Read `.claude/settings.json`, show the diff it intends to make, write the `attribution` block on
   confirmation. Never overwrite unrelated keys.
3. Run the attribution audit over the current history and report the count, without changing anything.
4. **Offer** the squash-merge change (per the resolved open question). Read the current state with
   `gh api repos/{owner}/{repo} --jq '.squash_merge_commit_message'`, explain that
   `COMMIT_MESSAGES` copies commit bodies onto the default branch permanently, and only on explicit
   confirmation switch to `PR_BODY`. State plainly that this changes merge behaviour for everyone on
   the repo.
5. **Offer** the `commit-msg` hook: copy it to `.githooks/` and set `core.hooksPath`, with the caveat
   that this is per-clone and does not travel.
6. Report orphaned `worktree-*` branches on origin and offer to delete them (per the resolved open
   question). List them first, delete only on confirmation.

- [ ] **Step 1: Write the file**
- [ ] **Step 2: Verify frontmatter**

```bash
grep -q 'disable-model-invocation: true' plugins/git-hygiene/commands/setup.md \
  && echo "OK" || echo "FAIL"
```

- [ ] **Step 3: Verify every mutating step is gated behind a confirmation**

Read the file and confirm that steps 2, 4, 5 and 6 each state explicitly that nothing is changed
without the user confirming. This is a manual review step, not a grep.

- [ ] **Step 4: Commit**

```bash
git add plugins/git-hygiene/commands/setup.md
git commit -m "feat: add git-hygiene setup command"
```

---

### Task 12: Registration

**Files:**
- Modify: `.claude-plugin/marketplace.json`
- Modify: `README.md`
- Modify: `docs/codex.md`, `docs/antigravity.md`

**Interfaces:** Makes the plugin installable and discoverable. This is the only task that touches
existing files.

- [ ] **Step 1: Add the marketplace entry**

`category: "productivity"` (the only value used so far), `source: "./plugins/git-hygiene"`, 7
keywords matching the manifest.

- [ ] **Step 2: Add the README table row under `## The plugins`**

Write it in the repo's existing house style. Note the deliberate inconsistency here: the surrounding
rows use em dashes and stay as they are, because repository documentation is out of scope by
decision (c). Do not "fix" the neighbouring rows.

- [ ] **Step 3: Add the `/plugin install` line to the bash block**

```bash
# Clean commits and PRs: no tool branding, no session URLs, ASCII typography
/plugin install git-hygiene@onelitefeather-claude-marketplace
```

- [ ] **Step 4: Add a line to `docs/codex.md` and `docs/antigravity.md`, and fix the stale count**

Both files still say "five" plugins and are missing rows for the last two. Correct the count and add
the missing entries. State in both that `hooks/` and `commands/` do not carry over, matching how
`framework` documents its non-portable parts.

- [ ] **Step 5: Verify**

```bash
jq -e '.plugins | map(select(.name == "git-hygiene")) | length == 1' .claude-plugin/marketplace.json >/dev/null \
  && echo "OK: marketplace entry" || echo "FAIL"
grep -c 'git-hygiene' README.md
jq -r '.plugins | length' .claude-plugin/marketplace.json
grep -in 'five plugins' docs/codex.md docs/antigravity.md
```

Expected: `OK`, at least 2 README hits, plugin count 7, and no remaining "five plugins" hits.

- [ ] **Step 6: Commit**

```bash
git add .claude-plugin/marketplace.json README.md docs/codex.md docs/antigravity.md
git commit -m "feat: register git-hygiene in marketplace and docs"
```

---

### Task 13: Bundle into `framework` so it installs everywhere

**Files:**
- Modify: `plugins/framework/.claude-plugin/plugin.json`
- Modify: `.claude-plugin/marketplace.json` (framework description, if it enumerates the bundle)
- Modify: `README.md` (framework row and install block note)

**Interfaces:** Makes `git-hygiene` install and enable automatically with `framework`, the core
bundle. `git-hygiene` stays independently installable — this only adds it to the bundle. Direct
precedent: `ce1e797 feat(framework): bundle context-layer, benchmark-stack, workflow as dependencies`.

**Verified mechanics (do not deviate):**
- Bare-string entry `"git-hygiene"`. The `name` field resolves within the declaring plugin's own
  marketplace, so no `marketplace` key and no `allowCrossMarketplaceDependenciesOn` change.
- **No `version` constraint.** Constraints resolve against `{plugin}--v{version}` git tags; this repo
  has zero tags, so any constraint fails with `no-matching-tag`.
- Enabling `framework` enables `git-hygiene` and writes an explicit `true` for it. Disabling
  `git-hygiene` while `framework` is enabled is refused.

- [ ] **Step 1: Confirm the current state**

```bash
jq -r '.dependencies[] | if type == "string" then . else "\(.name)@\(.marketplace // "same")" end' \
  plugins/framework/.claude-plugin/plugin.json
git tag | wc -l
```

Expected: nine `claude-plugins-official` entries, and `0` tags (confirming the no-constraint decision).

- [ ] **Step 2: Add the dependency and bump the framework version**

Append `"git-hygiene"` to the `dependencies` array. Bump `plugins/framework/.claude-plugin/plugin.json`
`version` from `0.1.0` to `0.2.0` — without a version change, installed clients have no signal to
re-resolve.

- [ ] **Step 3: Extend the framework description to name the new bundle member**

`framework`'s description enumerates what it bundles. Add git hygiene to that enumeration in
`.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `.antigravity-plugin/plugin.json` and the
`marketplace.json` entry. Keep the existing wording and typography of those descriptions otherwise
untouched — this is a functional edit, not a style pass.

Note for the Codex and Antigravity manifests: they already state that the dependency bundle is not
ported. `git-hygiene`'s *skills* do port, but only if installed separately there. Say so in one
clause rather than implying the bundle carries over.

- [ ] **Step 4: Verify the dependency resolves**

```bash
jq -e '.dependencies | index("git-hygiene") != null' plugins/framework/.claude-plugin/plugin.json >/dev/null \
  && echo "OK: dependency present" || echo "FAIL"
jq -e '.version == "0.2.0"' plugins/framework/.claude-plugin/plugin.json >/dev/null \
  && echo "OK: version bumped" || echo "FAIL"
claude plugin validate plugins/framework
claude plugin validate plugins/git-hygiene
```

- [ ] **Step 5: Document the rollout caveat in the README**

Auto-update is off by default for non-Anthropic marketplaces, so anyone who *already* has `framework`
installed does **not** get `git-hygiene` automatically. Add a short note under the install block
naming both paths: enable auto-update for the marketplace in `/plugin`, or run
`claude plugin update framework` followed by `/reload-plugins`.

This note is the difference between the team believing the plugin is active and it actually being
active. Do not skip it.

- [ ] **Step 6: Commit**

```bash
git add plugins/framework/ .claude-plugin/marketplace.json README.md
git commit -m "feat(framework): bundle git-hygiene as a dependency"
```

---

### Task 14: Repository cleanup (destructive — confirm before running)

**Files:** None. This task operates on remote refs.

**Interfaces:** Implements the resolved decision "clean from now on, delete the orphaned branches".
**No history rewrite.** Deleting a remote branch is outward-facing and irreversible for anyone
without a local copy, so each deletion is confirmed individually.

- [ ] **Step 1: List the candidates and verify they are actually merged or abandoned**

```bash
git ls-remote --heads origin 'worktree-*'
for b in $(git ls-remote --heads origin 'worktree-*' | awk '{print $2}' | sed 's|refs/heads/||'); do
  echo "== $b: $(git rev-list --count origin/main..origin/$b 2>/dev/null) commits ahead of main"
done
```

- [ ] **Step 2: Check for open PRs on those branches**

```bash
gh pr list --state open --json headRefName --jq '.[].headRefName' | grep '^worktree-' || echo "none open"
```

- [ ] **Step 3: Confirm with the user, then delete**

Only after presenting the list and the ahead-counts. Do not batch-delete without showing what is
being removed.

```bash
git push origin --delete <branch>
```

- [ ] **Step 4: Verify**

```bash
git ls-remote --heads origin 'worktree-*' || echo "OK: none left"
```

---

### Task 15: Final verification

- [ ] **Step 1: Full structural check**

```bash
claude plugin validate plugins/git-hygiene
for f in $(find plugins/git-hygiene -name '*.json'); do jq empty "$f" || echo "FAIL: $f"; done
find plugins/git-hygiene/scripts -type f -exec test -x {} \; -print
```

- [ ] **Step 2: Verify this plan's own commits comply with the skill**

```bash
git log --format='%H%n%B' origin/main..HEAD | plugins/git-hygiene/scripts/strip-attribution.sh --check \
  && echo "OK: own commits clean" || echo "FAIL: this branch violates its own skill"
```

This is the plan's acceptance test. If the branch that adds the skill violates the skill, the skill
does not work.

- [ ] **Step 3: Verify the scope boundary was respected**

```bash
git diff --stat origin/main..HEAD -- ':!plugins/git-hygiene' ':!docs/superpowers'
```

Expected exactly: `.claude-plugin/marketplace.json`, `README.md`, `docs/codex.md`,
`docs/antigravity.md` (Task 12) and the three `plugins/framework/*/plugin.json` manifests (Task 13).
Any other modified file means the scope boundary was crossed.

- [ ] **Step 4: Verify no existing description was touched for style reasons**

```bash
git diff origin/main..HEAD -- plugins/framework/ | grep '^[-+].*description'
```

Every changed description line must differ only by the added mention of git hygiene. A line that
changed only its punctuation or dashes is a scope violation — revert it.

- [ ] **Step 4: Open the PR**

Title and body written under the skill's own rules. No `--fill` — the PR body is written
deliberately, not assembled from commit bodies.
