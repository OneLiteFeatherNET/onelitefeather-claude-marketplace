# Enforcement contracts

This file documents the exact contracts that `hooks/hooks.json` + `scripts/guard.sh` (the
`PreToolUse` safety net), `scripts/commit-msg` (the opt-in git hook) and a CI job implement. It is
the single source of truth for the exit-code and JSON shapes — a script author reading only this
file must get the contract right without re-deriving it from the Claude Code docs.

## 1. The `PreToolUse` exit-code contract

**Exit 1 does not block the tool call.** This is the single most consequential fact in this file,
and the one most likely to be gotten wrong by anyone reasoning from ordinary Unix convention
("non-zero exit means failure means stop").

The only two ways a `PreToolUse` hook can actually prevent the tool call from running:

1. **Exit `0`** and print, on stdout, JSON of this exact shape:

   ```json
   {
     "hookSpecificOutput": {
       "hookEventName": "PreToolUse",
       "permissionDecision": "deny",
       "permissionDecisionReason": "Commit message contains an AI tool attribution trailer (Co-Authored-By: Claude ...). Remove it before committing."
     }
   }
   ```

   `permissionDecision` may also be `"allow"` (explicitly permit, skipping further permission
   checks) or `"ask"` (prompt the user). Only `"deny"` blocks.

2. **Exit `2`** and print a message on stderr. This blocks the tool call and surfaces the stderr
   text to Claude as the reason, without needing any JSON on stdout.

Everything else is non-blocking:

- **Exit `0` with no JSON on stdout** (or stdout that isn't the shape above): the tool call proceeds
  normally. Any stdout is shown in the transcript, nothing more.
- **Exit `1`** (or any exit code other than `0` and `2`): treated as a non-blocking hook error. The
  message is surfaced to the user for debugging, but **the tool call still runs**. A guard script
  that exits `1` on a detected violation has silently done nothing — the commit or push it meant to
  stop goes through anyway.

Consequence for `guard.sh`: every code path that is supposed to stop a commit must end in exit `0` +
the JSON above, or exit `2` + stderr. Never `exit 1` as a stand-in for "block this."

## 2. The `if` pre-filter and what `matcher` does and does not match

`matcher` selects on **tool name only** — `"Bash"`, `"Write"`, `"Edit"`, and so on. It has no
knowledge of the command or file content being passed to that tool. A hook with `"matcher": "Bash"`
and no `if` fires on *every* Bash invocation in the session, including ones that have nothing to do
with git or GitHub — `ls`, `npm test`, `curl`, all of it.

`if` is a second, optional filter evaluated after the matcher, written against the same
tool-name-plus-pattern syntax used in `permissions.allow`/`deny`. This is also the full,
concrete shape `hooks/hooks.json` (Task 8) must match byte-for-byte in structure — `matcher` and
`if` as sibling string keys on the entry, `hooks` as an array of `{"type": "command", "command":
...}` objects:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "if": "Bash(git commit:*) || Bash(git merge:*) || Bash(git push:*) || Bash(git tag:*) || Bash(gh pr create:*) || Bash(gh pr edit:*) || Bash(gh pr comment:*) || Bash(gh pr review:*) || Bash(gh issue create:*) || Bash(gh issue comment:*) || Bash(gh release create:*) || Bash(gh release edit:*)",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}\"/scripts/guard.sh"
          }
        ]
      }
    ]
  }
}
```

Only Bash invocations whose command line matches one of the `if` prefixes actually invoke
`guard.sh`. This is not just an optimization: without it, every unrelated Bash call pays the cost of
spawning the guard script, and the guard's own command-parsing logic has to defensively ignore
input it was never meant to see. `${CLAUDE_PLUGIN_ROOT}` is the plugin's own installed root,
substituted by Claude Code at hook-invocation time — it must be quoted, since the root path can
contain spaces.

## 3. Hook merging across user, project and plugin scope

Hooks are not exclusive to one scope. User settings (`~/.claude/settings.json`), project settings
(`.claude/settings.json`, `.claude/settings.local.json`) and every installed plugin's
`hooks/hooks.json` are all **merged**, not overridden — the highest-precedence scope does not hide
hooks registered in a lower one. For a given event (`PreToolUse` on `Bash`, here), every matching
hook from every scope runs.

They run **in parallel**, not in a fixed order. The practical rule that falls out of this: **the
first `deny` result to arrive wins immediately.** If this plugin's `guard.sh` and some other
project-level hook are both evaluating the same `git commit` call, whichever one returns `deny`
first blocks the call — the outcome does not wait for every hook to finish, and no hook can
"un-deny" a decision another hook already made. A hook that only warns (allow + message) never
overrides a sibling hook's deny.

## 4. The `--body-file` / `-F` blind spot

`git commit -F <file>` (and equivalently `--body-file` / `-F` on `gh pr create`, `gh pr edit`,
`gh release create`) passes a **filename** on the command line, not the message text. A Bash-matcher
guard that only inspects `tool_input.command` sees the path string and nothing else — the actual
attribution trailer, em dash, or ritual opener that needs catching lives inside a file the guard
never reads.

That file is almost always written moments earlier by the `Write` tool (Claude drafts the commit
body or PR body to a temp file, then shells out with `-F` to submit it). Two things close this gap,
both required:

- **The extraction loop.** When `guard.sh` matches a command containing `-F`, `-f`, `--body-file` or
  `--file` followed by a path argument, it must resolve that path and read the file's contents
  before running the detection patterns from `references/attribution.md` — not just scan the command
  string.
- **A second hook matcher on `Write`.** Register a `PreToolUse` hook with `"matcher": "Write"`,
  gated by an `if` (or in-script) heuristic on the target path — names or extensions that look like a
  commit message, PR body or release notes draft (`COMMIT_EDITMSG`, `*commit-msg*`, `*pr-body*`,
  `*release-notes*`, and similar temp-file conventions). This inspects the content at the moment it
  is written, independent of whether it is later consumed via `-F`, piped, or read some other way. A
  `Bash`-only guard is not a complete guard.

## 5. The `--no-verify` scoping bug

`--no-verify` (and its short form `-n`) suppresses git's own `pre-commit`/`commit-msg` hooks on
`git commit`, `git merge`, `git push` and `git tag`. It is tempting to detect it with a single
generic pattern matching `-n` or `--no-verify` anywhere in a git/gh command line. **Do not do this.**

`-n` is not a stable flag across commands:

- On `git commit`, `git merge`, `git push`, `git tag`: `-n` means `--no-verify` (or, for `push`,
  `--dry-run` depending on subcommand — the point stands that it is not a single universal meaning).
- On `gh release create`: `-n` is the short form of `--notes`. `gh release create v1.0.0 -n "Release
  notes"` is an entirely ordinary, non-suspicious invocation that happens to contain the substring
  `-n` immediately followed by a string — and a naive detector flags it as a hook bypass attempt.

**Detection must be scoped to the subcommand.** Only treat `-n` / `--no-verify` as a bypass signal
when the command is `git commit|merge|push|tag ...`. Never key off the bare flag text alone, and
never extend the check to `gh` subcommands where `-n` has a different, legitimate meaning. This is
the same class of mistake as `typography.md`'s warning against `\p{Pd}` as a dash detector: a pattern
that looks precise but ignores context produces confident false positives.

## 6. The `set -euo pipefail` trap

Scripts in this plugin are expected to use `set -euo pipefail` for the usual reasons (undefined
variables and pipeline failures should not pass silently). This has one sharp edge that matters here
specifically: **`grep` exits `1` when it finds no match.** Under `set -e`, an unguarded

```bash
grep -qiE "$PATTERN" <<<"$message"
```

that finds nothing aborts the entire script immediately at that line — the script never reaches the
code that would print a JSON `allow` result or fall through to the next check. Combined with §1
(exit `1` does not block), this failure mode is doubly dangerous: it does not just crash noisily, it
crashes into **the one exit code that Claude Code treats as non-blocking**. A guard that dies this
way fails open — the tool call it should have evaluated goes through anyway, and there is no visible
"denied" signal to explain why nothing was caught.

Guard against it explicitly, either form:

```bash
if grep -qiE "$PATTERN" <<<"$message"; then
  # match branch
fi
# reaching here after a no-match "if" is safe: the if statement itself
# consumes grep's exit code and does not trigger set -e
```

or

```bash
grep -qiE "$PATTERN" <<<"$message" || true
rc=$?
```

Never leave a bare `grep` (or any command whose "nothing found" outcome is expected and valid) as a
statement on its own line under `set -e`.

## 7. The `commit-msg` git hook and the `core.hooksPath` bootstrap

`scripts/commit-msg` is a standard git `commit-msg` hook (message file path as `$1`). Two properties
of git itself make this an opt-in, per-clone mechanism rather than something the plugin can install
automatically:

- **`.git/hooks/` is not versioned.** It lives inside `.git`, which is never cloned — a hook file
  dropped straight into `.git/hooks/commit-msg` in one working copy has no way to reach anyone else's
  clone. The plugin ships the hook script under a tracked path
  (`plugins/git-hygiene/scripts/commit-msg`, or copied by `/git-hygiene:setup` into `.githooks/` in
  the target repo) and points git at it with:

  ```bash
  git config core.hooksPath .githooks
  ```

- **Verified caveat: `core.hooksPath` does not travel on clone.** This setting lives in
  `.git/config` — the same untracked, per-clone location as every other local git config value.
  There is no repository file that can pre-seed it; a committed `.githooks/` directory makes the
  *hook script* available in every clone, but `core.hooksPath` itself must still be set by running
  the command above **in every fresh clone**, by every teammate, every time. `/git-hygiene:setup`
  runs this on request; nothing in the plugin makes it automatic, because nothing in git makes it
  automatic.

- **`git commit --no-verify` bypasses `commit-msg` entirely**, by git's own design — this is not a
  gap in this plugin's implementation, it is how git hooks work everywhere. Anyone who wants to
  commit contaminated text past this hook can simply pass the flag (see §5 for why detecting that
  flag is itself narrower than it looks).

Together these are why the git hook is documented as an **opt-in courtesy check for cooperative
authors**, installed only through `/git-hygiene:setup` on explicit confirmation, and never treated
as a substitute for the CI job in §8, which is the one layer that cannot be locally bypassed.

## 8. CI job sketch

The only enforcement point that runs outside the author's own clone, and therefore the only one
`--no-verify` cannot touch, is a CI check over the fully-formed PR:

```bash
# Requires: gh CLI authenticated, GH_TOKEN or equivalent in the job environment.
title=$(gh pr view "$PR_NUMBER" --json title --jq '.title')
body=$(gh pr view "$PR_NUMBER" --json body --jq '.body')
commit_bodies=$(gh pr view "$PR_NUMBER" --json commits --jq '.commits[].messageBody')

status=0
printf '%s\n' "$title" "$body" "$commit_bodies" \
  | "${CLAUDE_PLUGIN_ROOT}"/scripts/strip-attribution.sh --check || status=1

printf '%s\n' "$title" "$body" \
  | perl "${CLAUDE_PLUGIN_ROOT}"/scripts/detypo.pl --check || status=1

exit "$status"
```

Check `title`, `body` and every commit's message body separately (or concatenated, as above) —
`gh pr view --json commits` returns the PR's full commit list independent of what `gh pr create
--fill` may have copied into the PR body, so this also catches the leak path documented in
`references/attribution.md` (`--fill` copying a contaminated commit body into an otherwise clean PR
description). A non-zero exit fails the job.

## 9. Audit and remediation — read-only

These commands report on the current state without changing anything. None of them accepts a
`-i`/in-place flag or writes to the repository; all are safe to run at any time, including inside
CI, without a confirmation step.

**Is the guard hook currently registered for this session?**

```bash
claude plugin list | grep -i git-hygiene
```

**Is the opt-in `commit-msg` hook installed in this clone?**

```bash
git config --get core.hooksPath
```

Empty output, or a path other than the one `/git-hygiene:setup` configures, means the git hook is
not active in this clone — expected for every fresh clone per §7, not a fault.

**How many existing commits on the current branch carry attribution?**

```bash
git log --format='%H%n%B' | "${CLAUDE_PLUGIN_ROOT}"/scripts/strip-attribution.sh --check \
  || echo "found: see stderr for matched commits"
```

**How many em dashes and other flagged codepoints exist outside protected zones?**

```bash
perl "${CLAUDE_PLUGIN_ROOT}"/scripts/detypo.pl --check $(git ls-files)
```

None of the three audits above modifies history, working-tree files, or git config. Remediation —
rewriting a message before it is committed, or fixing typography in a file you are actively
authoring — is always a manual, reviewed edit; this plugin does not silently rewrite anyone's prose
(see the skill's "Never touch these" section and the design decision against silent rewriting).
