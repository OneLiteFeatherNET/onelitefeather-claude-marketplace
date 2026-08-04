# Git Hygiene Plugin — Design Spec

**Status:** approved (open questions resolved 2026-08-04)
**Research:** 6 parallel research agents + synthesis, run in an isolated worktree. All numeric
claims below were measured against this repository or verified by running the command.

## Problem

Git and GitHub text produced through Claude Code carries three kinds of noise that do not belong in
a public repository under the OneLiteFeather name:

1. **Tool attribution** — `Co-Authored-By: Claude <model> <noreply@anthropic.com>`, the
   `Claude-Session: https://claude.ai/code/session_...` trailer, and the
   `🤖 Generated with [Claude Code](https://claude.com/claude-code)` PR footer.
2. **Machine typography** — em dashes, smart quotes, ellipsis characters, non-breaking and
   zero-width spaces in commit messages, PR titles and bodies.
3. **Machine phrasing** — self-praise, ritual opening and closing sentences, forced three-item
   structures, vague statements without a filename, function name or ticket number.

This is measurable in this repository right now: **38 of 60 commits on `main` carry a Claude
trailer** (40x `Co-Authored-By: Claude Sonnet 5`, 17x `Claude Opus 4.8`, one lowercase
`Co-authored-by:`), and **17 of them additionally leak the same session ID**.

## Why this matters (the honest argument)

The goal is *not* to defeat AI detection. That framing is both unachievable and reputationally
risky, and the research supports dropping it:

- AI detection is unreliable in the direction that matters: human text merely edited by ChatGPT is
  falsely flagged as AI 75-85% of the time.
- Wikipedia, the primary source behind every "AI tells" list in circulation, explicitly warns
  against using those lists as a fix-list: *"Please do not merely treat these signs as the problems
  to be fixed; that could just make detection harder."*
- `blader/humanizer`, the structurally equivalent skill, was publicly attacked on Slashdot and in
  Nature as a detection-evasion tool. An OLF plugin framed that way would pull the same criticism
  onto the organization.

The defensible arguments are concrete and hold up on their own:

- **CLA / tooling correctness.** Kubernetes/CNCF forbids AI as a co-author because the CLA check
  runs over co-authors and an AI cannot sign a CLA. The trailer makes PRs technically unmergeable.
- **Information leak.** The `Claude-Session:` URL exposes a session ID; the trailer exposes the
  exact model and vendor version.
- **Downstream artifacts.** Release Please builds `CHANGELOG.md` and GitHub release notes from
  commit messages. A clean commit message makes three public artifacts clean automatically.
- **Repository typography.** ASCII-friendly commits render consistently in `git log`, in terminals,
  and in generated changelogs.

## Key research findings that shape the design

### Attribution is prompt-driven, and `attribution` cuts it at the root

The trailers are not appended deterministically by the CLI. They are injected into the model's
system prompt as an instruction, which is why contamination is inconsistent (the most recent
commit, `bdafaf8`, is clean).

A probe test against the locally installed CLI **2.1.221** established that the `attribution`
setting removes the instruction from the system prompt rather than filtering output afterwards:
without the setting the model quotes its instruction verbatim; with
`{"attribution": {"commit": "", "pr": "", "sessionUrl": false}}` it answers "NO SUCH INSTRUCTION".

Two corollaries:

- A committed `.claude/settings.json` carrying `attribution` works **even in an untrusted
  workspace**. In the same test, `permissions.allow` entries were explicitly discarded ("Ignoring 4
  permissions.allow entries ... this workspace has not been trusted") while the attribution
  instruction was still gone. Team policy by commit is effective for every clone, with no trust
  dialog.
- The hook is therefore a **safety net for attribution, not the load-bearing mechanism**. This
  contradicts the two research agents that cited issues #18253 and #7543 to argue the hook was
  mandatory; those issues concern older versions and the deprecated `includeCoAuthoredBy`.

### Settings that must NOT be used

- `includeCoAuthoredBy` is **deprecated**. It only covers the commit trailer, not the PR footer and
  not the session URL. It appears in the docs exactly once, in the deprecation note.
- `gitAttribution` **does not exist**. Zero hits across the full 266 KB settings documentation. It
  appears only in SEO blog posts. Setting it produces a silently ignored key, which is worse than
  no configuration because it creates false confidence.
- `includeGitInstructions: false` would also work but is a bigger cut: it removes the git status
  snapshot and the built-in commit workflow instructions too. Since `attribution` demonstrably
  suffices, this stays a footnote for CLIs older than 2.1.183.

### The two axes have inverted distributions

| Axis | In commit messages | In repo markdown |
|---|---|---|
| Attribution | 38 of 60 commits | 0 |
| Em dashes | 5 lines | 865 occurrences across 51 of 51 files |

Em dashes are this repository's established house style, not its defect. Both axes therefore point
at the same scope boundary: **Git/GitHub artifacts in, repository documentation out.**

### A blanket character replacement is wrong 12.7% of the time

Of the 865 em dashes, 110 sit inside code fences, inline code spans, URLs or blockquotes. A naive
`sed -i 's/—/-/g'` breaks links (`https://ex.ample/a—b` becomes `.../a - b`, a silent 404) and
markdown hard breaks. Protection zones are mandatory.

Two hard technical rules a naive implementation gets wrong:

- **Never use `\p{Pd}` as a dash detector.** The Unicode category includes the ASCII hyphen
  (`printf 'a-b' | rg -c '\p{Pd}'` matches). Under Conventional Commits nearly every message
  contains a hyphen, so this blocks everything.
- **Never put invisible characters literally into a pattern.** In one test a character intended as
  NBSP became 0x20 and the pattern matched almost every line. Use explicit codepoints.

### Mechanical ` - ` is itself a tell

Measured on this repo: after a blanket replacement, `xerus/SKILL.md`'s description contains three
` - ` on one line. That is "not more human, just differently mechanical". Resolution is two-stage:
resolve the dash by function when writing (comma pair, parentheses, colon, or a new sentence), and
keep mechanical ` - ` as a last-resort safety net with a rule of at most one per paragraph.

### German typography is a real exception

Per Duden and DIN 5008, the correct German dash is the **en dash U+2013 with spaces around it**;
the em dash is not used in German at all. A blanket ban makes German text orthographically wrong,
and blanket smart-quote replacement breaks German quote pairs into half-typographic mush (both
reproduced). Umlauts and ß are never transliterated and never covered by a range over Latin-1.

### Keyword blocking on "claude" is untenable here

11 commit bodies and 14 markdown files mention "Claude" legitimately. This repository *is* a Claude
Code marketplace; "Claude" is a product name like "Gradle". Detection must be line-precise on
trailer, URL and footer patterns.

### The stripper must separate machine from human

Verified against a message containing `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`,
`Claude-Session:` and `Co-authored-by: TheMeinerLP <x@y.z>`: only the human trailer survives. That
is the hard minimum requirement on the pattern. `Signed-off-by:`, `BREAKING CHANGE:`,
`Refs:`/`Fixes:`/`Closes:` and `Release-As:` are equally protected.

### Hook contract pitfalls

- **Exit 1 does not block.** Only exit 0 with `permissionDecision: "deny"`, or exit 2 with stderr.
- `--body-file` / `-F` is a blind spot: the file is usually written by the `Write` tool, so the Bash
  hook only sees a filename.
- `--no-verify` detection must be scoped to `git commit|merge|push|tag`, otherwise it falsely blocks
  `gh release create -n "..."` where `-n` means `--notes`.
- A plugin **cannot ship `attribution` itself**: plugin `settings.json` supports only `agent` and
  `subagentStatusLine`. This is the reason the plugin needs a `/setup` command.
- `core.hooksPath` is not carried over on clone; it lives in `.git/config` and must be set per clone.

## Decisions

| # | Question | Decision |
|---|---|---|
| a | Own plugin or a skill in `release-engineering`? | **Own plugin `git-hygiene`** with exactly one skill. Every topic in this repo is its own plugin; `release-engineering` is about config files and is deliberately hook-free; and the user wants a *standard* skill that applies in every repo, not one coupled to Release Please's installation. The subject coupling (commit message -> CHANGELOG -> release notes) becomes a cross-reference, not shared packaging. See (j) for how it still gets installed everywhere. |
| j | How does it get installed everywhere? | **As a `dependencies` entry in `framework`**, the core bundle everyone installs. Bare-string form (`"git-hygiene"`), which resolves within the same marketplace. It stays a standalone, separately installable plugin — the dependency only adds it to the bundle. |
| b | Instructions only, or instructions + settings + hook + scripts? | **Four graded layers.** (1) `.claude/settings.json` snippet as the *primary* measure, delivered via `/git-hygiene:setup`. (2) SKILL.md rules for everything no setting covers. (3) PreToolUse hook as a net — blocking only on the four deterministic attribution patterns, warning only on typography and phrasing. (4) `commit-msg` git hook and CI check as documented opt-ins. No silent rewriting of prose, ever. |
| c | Scope | **Git/GitHub artifacts only**: commit messages, branch names, PR titles and bodies, issue and review comments, release notes, tag messages. Repository documentation is explicitly out. The skill still ships an audit command that reports on the existing state without changing it. |
| d | Language | **English**, body and frontmatter. 16 of 17 existing skills have English bodies; the sole exception has a German subject. Here the subject is English commit and PR text, so the before/after examples must be English. German typography gets its own clearly labelled section in `references/typography.md`, written in English with German examples. |
| e | How strict may the em-dash rule be? | **Two-stage and context-aware.** Hard ASCII for commit messages, PR titles and branch names. For German prose (issue comments) the spaced U+2013 and German quote pairs stay untouched; only U+2014 is a tell there, and there it is a spelling error. Replacements run exclusively outside code fences, inline code, URLs, paths, CLI flags and blockquotes. |
| f | Slash command? | **Exactly one: `/git-hygiene:setup`** with `disable-model-invocation: true`. It is technically necessary, not convenience, because a plugin cannot ship the `attribution` setting itself. No `/check` — the skill triggers automatically via its description and the audit commands live in SKILL.md. |
| g | Portability | **All three manifests.** The core is pure text rules with no Claude-specific tools, so it ports. `hooks/hooks.json` and `commands/setup.md` do not — documented as "does not carry over", matching how `framework` and `framework-code-navigation` handle it. The detection list generalizes the pattern to other harness signatures instead of hardcoding Claude strings. |
| h | Third-party repositories | **Mode-dependent.** In OneLiteFeatherNET repos, strip without asking. For a PR to a repo we do not own, check `CONTRIBUTING.md`, `.github/PULL_REQUEST_TEMPLATE.md` and any AI policy for a disclosure requirement first; where one exists the disclosure stays and only tool branding is removed. `Signed-off-by:` is never removed and never forged. |
| i | Naming and framing | Plugin `git-hygiene`, skill `git-hygiene`. Framed throughout as hygiene and tooling correctness. No mention of detection avoidance anywhere in the plugin. |

## Distribution: bundled into `framework` (user decision, 2026-08-04)

`git-hygiene` should be installed everywhere by default, not opted into per repo. The mechanism is
the `dependencies` array in `plugins/framework/.claude-plugin/plugin.json`. All of the following was
verified against the official plugin-dependencies documentation:

- **Bare-string form resolves in the same marketplace.** The `name` field "resolves within the same
  marketplace as the declaring plugin", so the entry is simply `"git-hygiene"` — no `marketplace`
  key, and `allowCrossMarketplaceDependenciesOn` is not involved (that only governs the existing
  `claude-plugins-official` entries).
- **No `version` constraint.** Version ranges resolve against git tags named `{plugin}--v{version}`.
  This repository has **zero tags**, so a constraint would fail with `no-matching-tag`. Unversioned
  is both correct and consistent with the nine existing dependencies.
- **Install and enable are automatic.** "When you install a plugin that declares dependencies,
  Claude Code resolves and installs them automatically." Enabling `framework` also enables
  `git-hygiene`, and Claude Code writes an explicit `true` for it.
- **It cannot be silently dropped.** Disabling `git-hygiene` while `framework` is enabled is refused,
  with an error naming `framework` and offering a chained command. Someone who genuinely wants it off
  has to say so explicitly.
- **Precedent exists in this repo.** `ce1e797 feat(framework): bundle context-layer, benchmark-stack,
  workflow as dependencies` did exactly this.

**The rollout caveat that matters:** auto-update is off by default for non-Anthropic marketplaces.
Everyone who *already* has `framework` installed will not receive `git-hygiene` until they either
enable auto-update for the marketplace in `/plugin`, or run `claude plugin update framework`
followed by `/reload-plugins`. This has to be communicated when the plugin ships, otherwise the team
will believe it is active when it is not.

For organization-wide enforcement beyond the bundle, `framework` can be added to `enabledPlugins` in
managed settings (`/etc/claude-code/managed-settings.json`). Documented in
`references/attribution.md` as an option, not applied by this plan.

Why the dependency rather than folding the skill into `framework` directly: the one-topic-per-plugin
convention holds across all six existing plugins, `git-hygiene` needs its own hook and command that
`framework` should not own, and it must stay separately installable for repos that do not want
`framework`'s Outline MCP server.

## Resolved open questions (user decision, 2026-08-04)

| Question | Decision |
|---|---|
| Existing contamination on `main` | **Clean from now on.** No history rewrite — it would change every SHA, break open PRs and every clone of the published marketplace. Additionally: delete the four orphaned `origin/worktree-*` branches whose auto-generated names (`drifting-pondering-widget`, `iridescent-scribbling-bear`, `prancy-yawning-koala`, `rippling-sleeping-emerson`) are permanently visible in the PR history. |
| GitHub squash-merge setting | **`/setup` offers to change it.** The repo is verified to be on `squash_merge_commit_message: COMMIT_MESSAGES`, so contaminated commit bodies land on `main` permanently even when the PR body was clean. `/setup` proposes switching to "Pull request title and description" and asks before changing anything. |
| Third-party PR behaviour | **Check the policy, keep the disclosure.** As per decision (h). |
| Frontmatter descriptions in scope? | **Out of scope, audit-only.** The 54 em dashes in existing `description` fields and the ten manifest JSONs are reported by the audit command but not changed. Cleaning them up is a separate, reviewable project. |

## Non-goals

- Defeating AI detectors.
- Rewriting repository documentation, READMEs or existing skill files.
- Rewriting git history.
- Silently modifying a human author's prose.
- Removing or forging `Signed-off-by:`, or suppressing a disclosure a target repository requires.

## Verification approach

This repository has no build, no tests and no CI. Verification is structural, matching the two
existing plans: `jq empty` for JSON validity, `grep` for required frontmatter fields and
cross-file path references, `claude plugin validate` for the plugin skeleton (a skeleton of the
target layout has already been validated successfully), plus behavioural tests of the shipped
scripts against fixture messages.
