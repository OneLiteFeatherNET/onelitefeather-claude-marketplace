# Attribution

How to turn off Claude Code's tool-attribution text (the `Co-Authored-By:` trailer, the
`Claude-Session:` URL, and the PR footer) at its source, how to prove it actually worked, which
settings look plausible but do not work, and the paths by which old or third-party contamination
still reaches a repository even when `attribution` is configured correctly. `SKILL.md` links here
under "Further reference"; `commands/setup.md` implements the settings-file part of this document;
`scripts/guard.sh` implements the detection patterns defined below.

## The settings block

```json
{
  "attribution": {
    "commit": "",
    "pr": "",
    "sessionUrl": false
  }
}
```

All three keys are independent and must be set together:

- `commit` — the text appended to a commit message as a `Co-Authored-By:` trailer. An empty string
  suppresses it.
- `pr` — the `🤖 Generated with [...]` footer appended to a PR body via `gh pr create`. An empty
  string suppresses it.
- `sessionUrl` — whether the `Claude-Session: https://claude.ai/code/session_...` trailer is
  appended. This is a boolean, not a string, and defaults to `true`.

Setting only `commit` and `pr` to empty strings and leaving `sessionUrl` untouched is a common
half-fix: it removes the co-author trailer and the PR footer, but `sessionUrl` still defaults to
`true`, so the session-ID trailer keeps getting appended to every commit. All three keys have to be
set in the same block for a commit and PR to come out clean.

## Settings precedence

Highest wins, in this order:

1. Managed settings — `/etc/claude-code/managed-settings.json` (organization-enforced; nothing
   below can override it).
2. CLI flags passed at invocation.
3. `.claude/settings.local.json` (per-user, per-project; typically not committed).
4. `.claude/settings.json` (committed, shared project settings).
5. User settings (`~/.claude/settings.json`).

**Verified fact:** a committed `.claude/settings.json` carrying `attribution` is honored even in an
**untrusted workspace** — i.e. immediately after a fresh clone, before anyone has clicked through
the workspace-trust prompt. This was confirmed directly: in the same probe session,
`permissions.allow` entries from that same file were explicitly discarded ("Ignoring 4
permissions.allow entries ... this workspace has not been trusted"), while the attribution
instruction was still gone from the system prompt. `attribution` is therefore effective as a
team-wide default delivered purely by committing it — every clone gets it, with no trust dialog to
click through — which `permissions.allow` in the same file does not guarantee.

## Minimum versions

- `attribution.sessionUrl` requires Claude Code **>= 2.1.183**.
- `includeGitInstructions` (the fallback described below) needs **>= 2.1.78** for the bugfix that
  makes it behave correctly.
- Check the installed version with:
  ```bash
  claude --version
  ```
  Below the minimum, `attribution.sessionUrl` may not take effect at all — treat the version check
  as a precondition before trusting the settings block, not as an afterthought.

## The self-test: proving the instruction is gone, not merely filtered

A clean-looking commit is not proof that attribution is off. The trailers are injected into the
model's system prompt as an instruction rather than appended deterministically by the CLI, which is
exactly why contamination is inconsistent from commit to commit. The only reliable test is to ask
the model to reveal the instruction itself, before and after applying the setting:

1. In a session where `attribution` is **not** set, ask the model directly what its instructions
   say about commit authorship. It quotes (or closely paraphrases) the trailer instruction — proof
   the instruction is present in the system prompt.
2. Apply `{"attribution": {"commit": "", "pr": "", "sessionUrl": false}}` in the settings file in
   scope, start a **fresh** session (the setting is read at session start), and ask the identical
   question. A probe run against the locally installed CLI (2.1.221) returned **"NO SUCH
   INSTRUCTION"** — the instruction itself is gone from the prompt, not just its output.

Step 2's result is the only thing worth trusting. It shows `attribution` removes the instruction at
its source rather than filtering the model's output after generation — a distinction that matters
because a source-level removal has no bypass path once configured, while an output filter could in
principle be worked around by any code path that skips it.

## Anti-pattern: settings that must NOT be used

- **`includeCoAuthoredBy`** — **deprecated**. It only ever covered the `Co-Authored-By:` commit
  trailer. It does not touch the PR footer and does not touch the `Claude-Session:` trailer. It
  appears in the official settings documentation exactly once, inside its own deprecation note. Do
  not reach for it as a primary control — at best it silences roughly a third of the surface that
  `attribution` covers in one block.
- **`gitAttribution`** — **does not exist**. Zero hits across the full settings documentation.
  It shows up only in unofficial SEO blog posts written as though it were real. Setting it produces
  a silently ignored, unrecognized key — worse than configuring nothing, because it creates false
  confidence that attribution has been turned off when nothing was actually changed.

## Detection patterns (canonical — implemented by `scripts/guard.sh`, do not redefine elsewhere)

These are the four deterministic attribution artifacts the `PreToolUse` guard hook denies on. They
have effectively zero false-positive risk, which is why the hook can hard-block on them instead of
merely warning. Every pattern matches on structural markers (a trailer label, a known bot email
domain, a footer phrase, a URL shape) — never on a model name — so the same rule works for whichever
model wrote the text and does not need updating when a new model ships.

1. **Co-authored-by trailer with a known harness bot address** — a `Co-authored-by:` (any case)
   trailer whose email address belongs to a known harness bot domain, currently
   `noreply@anthropic.com` for Claude Code. The match is on the trailer label plus the bot domain,
   never on the display name in front of the address, so it does not care whether that name reads
   "Claude", "Claude Sonnet 5", "Claude Opus 4.8" or anything else.
   Illustrative example only (not itself the pattern to encode):
   `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`
2. **Session trailer** — a line matching `^Claude-Session:\s*https?://\S+` (case-insensitive on the
   label). Other harnesses that inject an equivalent session-identifying trailer are added to this
   rule by label, not by rewriting it per harness.
3. **Generated-with footer** — a line carrying the robot emoji together with the phrase "Generated
   with" (case-insensitive), typically rendered as a markdown link, e.g.
   `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
4. **Bare session URL on its own line** — a line containing nothing but a URL matching the harness's
   session-URL shape (e.g. `https://claude.ai/code/session_...`) with no `Claude-Session:` label in
   front of it. This catches the case where the label was stripped, or never applied, but the raw
   link survived.

## Leak paths: how contamination still reaches the repository

`attribution` and the guard hook stop Claude Code from writing this text into a message in the
first place. Neither one retroactively cleans history that already carries it, and neither one
governs what a different actor writes. Four paths carry contamination past a correctly configured
`attribution` setting.

1. **`gh pr create --fill` / `--fill-verbose` / `--fill-first`**
   These flags assemble the PR title and body from the branch's own commit log, independent of any
   Claude Code setting. `attribution.pr` only governs the footer Claude Code appends when it calls
   `gh pr create` itself — it has no effect on `--fill` reading contaminated commit bodies off the
   branch, whether that contamination predates the `attribution` setting, arrived via a rebase, or
   came from a contributor's own tooling.
   **Mitigation:** never run `--fill`/`--fill-verbose`/`--fill-first` on a branch with unaudited
   history. Write the PR title and body directly, or run the attribution audit over the branch's
   commits and clean any hits with `scripts/strip-attribution.sh` before filling.

2. **Squash merge with `squash_merge_commit_message: COMMIT_MESSAGES`**
   GitHub's squash-merge behavior is governed by a repository setting that controls what text
   becomes the squash commit's body. When it is `COMMIT_MESSAGES`, GitHub concatenates every commit
   message on the branch — trailers included — into the squash commit body and writes that onto the
   default branch permanently, even when the PR's own title and body were clean.
   Read the current value:
   ```bash
   gh api repos/{owner}/{repo} --jq '.squash_merge_commit_message'
   ```
   Change it to build the squash body from the PR instead of the commit log:
   ```bash
   gh api repos/{owner}/{repo} -X PATCH -f squash_merge_commit_message=PR_BODY
   ```
   **Mitigation:** switch the setting to `PR_BODY`. `/git-hygiene:setup` offers this change on
   explicit confirmation, since it alters merge behavior for everyone on the repository.

3. **CI committers and GitHub App bot accounts**
   A commit or comment written by a CI job or a GitHub App bot was not produced by a locally
   configured Claude Code session, so a local `attribution` setting has no effect on it. If the
   bot's own template embeds tool branding — its own, or a chained AI tool's — it lands on the
   repository regardless of any developer's local configuration.
   **Mitigation:** audit the author/committer list for bot accounts
   (`git log --format='%an <%ae>'`) and check what template each one writes before trusting it with
   commits or comments on the default branch.

4. **Release notes and `CHANGELOG.md` generated from commit messages**
   Any tool that synthesizes release notes or a changelog from commit messages inherits whatever
   those commit messages contain, as a general mechanism: a contaminated commit body becomes a
   contaminated changelog line with no further opportunity to intercept it. Keeping commit messages
   clean at the source is what makes these generated artifacts clean automatically.
   **Unverified:** whether Release Please's own commit-message handling passes a `Co-Authored-By:`
   or `Claude-Session:` trailer through into a generated `CHANGELOG.md` entry was not confirmed by
   this research — no agent had a Release Please run against contaminated history available to
   inspect, and no local OLF repository with an existing generated `CHANGELOG.md` was available
   either. Treat the mechanism above as established and this specific claim about Release Please's
   behavior as open until someone verifies it against a real run.

## Footnote: `includeGitInstructions: false`

For Claude Code versions older than 2.1.183 — too old for `attribution.sessionUrl` to exist —
setting `includeGitInstructions: false` removes the same attribution instructions as a side effect,
because it drops the entire block of git-related guidance from the system prompt. It works, but it
is a much bigger cut than `attribution`: it also removes the automatic git-status snapshot Claude
Code normally includes, and the built-in commit-workflow guidance (how to stage, structure and
describe a commit). Use it only as a fallback on CLIs that predate `attribution`, not as a
general-purpose substitute for it.
