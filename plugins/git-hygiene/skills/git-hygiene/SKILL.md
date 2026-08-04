---
name: git-hygiene
description: Strips AI-tool attribution, machine typography and machine phrasing from Git and GitHub artifacts. Applies whenever writing a commit message, opening a PR with `gh pr create`, writing a PR title or body, commenting on an issue or review, naming a branch, or drafting release notes. Not for prose in repository documentation, READMEs or skill files - those keep this repository's existing house style.
---

# Git Hygiene

AI-tool attribution in a commit or PR breaks things that matter beyond style. CLA checks that run
over co-authors (Kubernetes/CNCF-style) treat a `Co-Authored-By:` trailer naming a bot as unsignable,
making the PR technically unmergeable. A `Claude-Session:` URL is a plain information leak: a session
identifier with no business in public history. Release Please builds `CHANGELOG.md` and GitHub
release notes directly from commit messages, so noise left in a commit body becomes a permanent line
in a public artifact with no later chance to catch it.

## Scope

| In scope | Out of scope |
|---|---|
| Commit messages, branch names, PR titles and bodies, issue and review comments, release notes, tag messages | Repository documentation: READMEs, skill files, `docs/`, and any other prose in this repo, which keeps its existing house style |

## Step 1: turn it off at the source

A plugin cannot ship the `attribution` setting itself, so this is delivered via `/git-hygiene:setup`
into `.claude/settings.json`. All three keys must be set together - leaving `sessionUrl` out is a
common half-fix, since it defaults to `true`:

```json
{
  "attribution": {
    "commit": "",
    "pr": "",
    "sessionUrl": false
  }
}
```

**Anti-pattern - do not reach for these instead:**

- `includeCoAuthoredBy` - deprecated, and it only ever covered the commit trailer. It does nothing
  about the PR footer or the session-URL trailer.
- `gitAttribution` - does not exist. It is a silently ignored, unrecognized key, which is worse than
  configuring nothing because it creates false confidence that attribution is off.

## Never emit these

Four artifacts, matched on structural markers (a trailer label, a bot email domain, a footer phrase,
a URL shape), never on a model name - the same rule works regardless of which model wrote the text,
case-insensitively on the label:

1. A `Co-authored-by:` trailer whose address belongs to a known harness bot domain, e.g.
   `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`.
2. A `Claude-Session:` trailer carrying a session URL.
3. A "Generated with" footer, typically paired with a robot emoji.
4. A bare session URL sitting alone on its own line, with no label in front of it.

## Never touch these

`Signed-off-by:`, `BREAKING CHANGE:`, `Refs:`/`Fixes:`/`Closes:`, and `Release-As:` are protected git
trailers - DCO compliance and Release Please's own parsing depend on these exact tokens. A human
`Co-authored-by:` trailer (a real teammate's address, not a bot domain) is never touched either; only
the bot-domain match above is in scope.

## Typography

Scope is Git/GitHub artifacts only - repository documentation keeps its em dashes. Within scope, the
rule is ASCII: dashes, curly quotes, ellipses and invisible or exotic spaces normalize to their ASCII
forms. Resolve a dash by function first, applied when writing or editing: a parenthetical aside
becomes a comma pair or parentheses, an explanation becomes a colon, a turn or contrast becomes a new
sentence. A mechanical spaced hyphen (` - `) is the last-resort fallback only, at most once per
paragraph - more than that means function-based resolution should have been used instead.

German prose gets one exception: a spaced en dash (the *Gedankenstrich*, per Duden and DIN 5008) is
correct German and must never be blanket-replaced; an unspaced en dash as a range marker (`Mo-Fr`)
stays too. The em dash has no place in German at all and is corrected there like any other spelling
error. Umlauts and ss-sharp-s are letters, never touched.

Replacement never runs inside four protection zones: fenced code blocks, inline code spans, indented
code blocks, and URLs or link targets - a naive substitution inside a URL silently breaks the link.
Blockquotes are a softer, fifth zone: changing a quoted line changes what is attributed to whoever is
being quoted.

## Phrasing

Prefer concrete over vague: name a file, a function, a config key, a test, or a ticket number. A
message that never names any of those - staying at "improves", "fixes", "updates" - is the strongest
tell there is, stronger than any single word choice. Drop self-praise ("comprehensive", "powerful",
"critical" used as an unearned intensifier rather than an accurate severity) and ritual sentences
addressed to a reader who is not there ("Great question!", "Let me know if you have any questions!").
Do not pad a list to exactly three items when the diff only supports one or two. Uneven length is
normal: some commits get one line, some get ten, in proportion to what actually happened - a history
that is uniformly thorough regardless of diff size is itself a signal, not a virtue.

## ANTI-PATTERN / good example

Before (attribution, self-praise, forced three-item structure, ritual closer, and an em dash, all in
one commit):

```
feat: improve the authentication system

This is a comprehensive, powerful fix that significantly improves the security
and reliability of the authentication system — a critical enhancement. Three
key improvements were made: 1) validation was strengthened 2) error handling
was improved 3) overall code quality was enhanced.

Let me know if you have any questions!

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_012abc
```

After:

```
fix: reject expired JWTs in AuthMiddleware.verify()

Tokens past exp were accepted because verify() only checked the signature. Adds
an expiry check and a regression test (auth_middleware_test.go).

Fixes #482.
```

Same underlying change. The second version names the function, the field, and the test, and carries
nothing that was not true of the diff.

## Verify before you push

Attribution audit, over every commit on the current branch:

```bash
git log --format='%H%n%B' | "${CLAUDE_PLUGIN_ROOT}"/scripts/strip-attribution.sh --check \
  || echo "found: see stderr for matched commits"
```

Typography audit, corpus-wide. `--hidden` is required: plugin manifests live under dot-prefixed
directories, and ripgrep will not descend into one without it:

```bash
rg -n --hidden -P '[\x{2010}-\x{2015}\x{2212}\x{2018}\x{2019}\x{201C}\x{201D}\x{201E}\x{201A}\x{2026}\x{00A0}\x{202F}\x{2002}\x{2003}\x{2007}\x{2009}\x{200A}\x{200B}\x{FEFF}\x{2192}\x{2190}\x{21D2}\x{21D0}\x{2022}\x{00D7}\x{2122}\x{00A9}]' -g '*.md' -g '*.json'
```

Both commands are read-only: they report, they do not rewrite anything.

## Contributing to repos you do not own

Check the target repository's policy before stripping anything: `CONTRIBUTING.md`, a
`.github/PULL_REQUEST_TEMPLATE.md`, or any stated AI-disclosure policy. Where a disclosure is
required, keep the disclosure and remove only the tool-branding text (the trailer, the session URL,
the footer). `Signed-off-by:` is never removed, and it is never forged on someone else's behalf
either.

## Further reference

- `references/attribution.md` - the settings block and precedence, the self-test that proves the
  instruction is gone rather than merely filtered, the two anti-pattern settings, the canonical
  detection patterns, and the four leak paths that still reach a repo around a correct setting.
- `references/typography.md` - the full codepoint tables, delete-versus-replace, the German
  exceptions, the four-plus-one protection zones, and the URL trap.
- `references/ai-tells.md` - the phrasing tell categories, the evidence-backed vocabulary cluster,
  the do-not-touch list, and before/after examples drawn from this repository's own real history.
- `references/enforcement.md` - the `PreToolUse` exit-code contract, hook matcher and `if` scoping,
  the `--body-file` blind spot, the `--no-verify` scoping bug, the opt-in `commit-msg` git hook, and
  the CI job sketch.

For the commit -> CHANGELOG -> public release-notes chain this feeds into, see
`release-engineering:release-please`.
