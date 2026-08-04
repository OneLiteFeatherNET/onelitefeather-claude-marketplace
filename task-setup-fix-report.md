# Fix: copy sibling scripts alongside commit-msg hook in setup command

## Bug

`plugins/git-hygiene/commands/setup.md` Step 5 installed the opt-in
`commit-msg` hook by copying only `${CLAUDE_PLUGIN_ROOT}/scripts/commit-msg`
into the target repo's `.githooks/` directory.

`plugins/git-hygiene/scripts/commit-msg` resolves its two sibling scripts,
`strip-attribution.sh` and `detypo.pl`, by looking first in its own
directory, then falling back to `$CLAUDE_PLUGIN_ROOT/scripts`. Once
installed via `.githooks/commit-msg` and invoked by git in an ordinary
terminal (outside a Claude Code session), `$CLAUDE_PLUGIN_ROOT` is unset, so
the fallback fails — and since only `commit-msg` was copied, the
same-directory lookup fails too. Every commit in the installing clone then
aborted with a loud "cannot find strip-attribution.sh" error. This was safe
(no silent bypass of enforcement) but made the hook unusable until someone
noticed and manually copied the missing scripts.

## Fix

Edited `plugins/git-hygiene/commands/setup.md` Step 5:

- The install command block now copies all three scripts —
  `commit-msg`, `strip-attribution.sh`, `detypo.pl` — into `.githooks/`,
  and marks `commit-msg` and `strip-attribution.sh` executable (matching
  their permissions in `plugins/git-hygiene/scripts/`; `detypo.pl` is
  invoked via `perl "$detypo"` and doesn't need the exec bit, but the
  source file happens to carry `+x` too — copies inherit whatever mode
  `cp` preserves, no extra command needed for that one).
- Added one sentence to the explanatory text before the confirmation gate,
  telling the user why the extra two scripts are copied alongside the hook
  (so it can find them next to itself even outside a Claude Code session,
  where `$CLAUDE_PLUGIN_ROOT` is unset).
- No other part of Step 5 (or the rest of the file) was touched — same
  announce/explain/confirm/run/report cadence as before.

## Verification

Read the edited section back; confirmed `commit-msg`, `strip-attribution.sh`,
and `detypo.pl` all appear in the `cp` commands.

Independently tested in a scratch repo
(`/tmp/claude-1000/.../scratchpad/hook-test-repo`), running exactly what the
new Step 5 instructs:

1. `mkdir -p .githooks`, copied all three scripts, `chmod +x` on
   `commit-msg` and `strip-attribution.sh`, `git config core.hooksPath
   .githooks`.
2. Unset `CLAUDE_PLUGIN_ROOT` (simulating an ordinary terminal outside
   Claude Code) and ran `git commit -m "feat: test commit message for hook
   verification"`.
   - Result: commit succeeded, exit code 0, no "cannot find" error.
3. Second commit with an attribution trailer
   (`Co-Authored-By: Claude <noreply@anthropic.com>`) via `git commit -F`.
   - Result: commit succeeded; `git log -1 --format='%B'` showed the
     trailer was stripped, message reduced to `fix: something`.
4. Negative control in a separate scratch repo: installed only
   `commit-msg` (the old, buggy behavior) with `CLAUDE_PLUGIN_ROOT` unset.
   - Result: commit failed as expected, with the hook's own error message:
     `git-hygiene commit-msg hook: cannot find strip-attribution.sh
     (looked next to this hook and under $CLAUDE_PLUGIN_ROOT/scripts).
     Commit aborted rather than skipping enforcement silently.`

This confirms the fix resolves the bug (all-three-scripts install works
standalone) while reproducing the original failure mode as a negative
control (commit-msg-only install still fails loud, matching the described
bug).

All scratch test repos were created under the session scratchpad or `/tmp`
and were not committed; they were cleaned up after verification and do not
appear in this repository's git history.
