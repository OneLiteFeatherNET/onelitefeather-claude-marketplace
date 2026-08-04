---
name: setup
description: Guides you step by step through git-hygiene setup — the attribution settings block, an audit of existing history, the GitHub squash-merge setting, the optional commit-msg hook, and orphaned worktree-branch cleanup — pausing for your explicit confirmation before any step that changes repository state or GitHub configuration.
disable-model-invocation: true
---

Walk the user through git-hygiene setup live, one step at a time — a guided
walkthrough, not a script that silently runs everything and dumps a report at
the end. Announce what you are about to check before checking it, report each
step's result as soon as you have it, and move to the next step only once the
current one is resolved. Steps 1 and 3 are read-only and never need
confirmation. **Steps 2, 4, 5 and 6 each change something outside this
conversation — a committed settings file, GitHub repository configuration, a
git hook wired into `core.hooksPath`, or a remote branch. For every one of
these four steps: show exactly what you intend to do, then stop and wait for
the user's explicit confirmation before doing it. Nothing in this command
writes a file, calls the GitHub API, or deletes a branch until the user has
said yes to that specific change.** A "no" or no answer at any of these four
steps means: change nothing, report that the step was skipped, and continue
to the next step.

**Step 1 — Claude Code version.** Run `claude --version` via Bash. Compare it
against **2.1.183**, the minimum version at which `attribution.sessionUrl`
takes effect (see
`skills/git-hygiene/references/attribution.md`). Report the installed
version and whether it meets the minimum. If it does not, say so plainly and
mention the fallback: `includeGitInstructions: false` removes the same
attribution instructions on older CLIs, at the cost of also dropping the
git-status snapshot and the built-in commit-workflow guidance. This step is
informational only — below the minimum or not, continue to Step 2 regardless;
do not abort the walkthrough over it.

**Step 2 — the `attribution` settings block.** Read `.claude/settings.json`
at the repository root (treat a missing file as `{}`, not an error). You are
about to propose merging this block in:

```json
{
  "attribution": {
    "commit": "",
    "pr": "",
    "sessionUrl": false
  }
}
```

- If `attribution` is already present with exactly these three keys and
  values, say so and move straight to Step 3 — nothing to change.
- Otherwise, show the user the exact diff: the file as it is now, and the
  file as it would be after the merge, with every other top-level key
  preserved untouched. Never overwrite or drop a key that is not
  `attribution` — this is a merge into the existing object, not a
  replacement of the file. **Then stop and ask for confirmation.** Only
  after the user explicitly confirms, write the merged file. If the user
  declines, say the settings file was left unchanged and move on.

**Step 3 — audit existing history.** Say you are checking how much of the
current branch's history already carries an attribution artifact — this
changes nothing, it only counts. Run, via Bash:

```bash
count=0
total=0
for sha in $(git log --format='%H'); do
  total=$((total + 1))
  if ! git log -1 --format='%B' "$sha" \
      | "${CLAUDE_PLUGIN_ROOT}/scripts/strip-attribution.sh" --check >/dev/null 2>&1; then
    count=$((count + 1))
  fi
done
echo "$count of $total commits carry an attribution artifact"
```

Report the count as-is. Do not offer to rewrite history in this step or any
other — this plugin never rewrites git history (see the design's non-goals);
the count is informational, feeding into whether the user wants the
squash-merge change in Step 4 and the commit-msg hook in Step 5.

**Step 4 — GitHub squash-merge setting.** Explain briefly what this step is
about before running anything: when a repository's
`squash_merge_commit_message` setting is `COMMIT_MESSAGES`, GitHub
concatenates every commit message on a branch — trailers included — into the
squash commit body and writes that onto the default branch permanently, even
when the PR's own title and body were clean. Read the current value:

```bash
gh api repos/{owner}/{repo} --jq '.squash_merge_commit_message'
```

- If it is already `PR_BODY` (or anything other than `COMMIT_MESSAGES`), say
  the repository is already configured safely and move to Step 5.
- If it is `COMMIT_MESSAGES`, state plainly that switching it changes merge
  behaviour for **everyone** on the repository, not just this session, and
  that this is a real API write, not a local file. **Then stop and ask for
  confirmation.** Only on the user's explicit "yes", run:

  ```bash
  gh api repos/{owner}/{repo} -X PATCH -f squash_merge_commit_message=PR_BODY
  ```

  If the user declines, say the setting was left as `COMMIT_MESSAGES` and
  move on — do not run the `PATCH` call speculatively or "to be safe."

**Step 5 — the optional `commit-msg` hook.** Explain what it does: a
git `commit-msg` hook that strips attribution trailers automatically and
fails the commit outright on a typography finding, rather than silently
rewriting the author's message. **Before asking for confirmation**, state
the caveat that matters for the user's decision: this hook is installed by
setting `core.hooksPath` in the local, untracked `.git/config` — it is
**per-clone** and does **not** travel with the repository. A committed
`.githooks/` directory makes the hook script available to every clone, but
each teammate still has to run this step (or the
`git config core.hooksPath .githooks` command by hand) in their own clone
for it to take effect — installing it here protects only this clone, not the
team. Also mention that `git commit --no-verify` bypasses this hook
entirely, by git's own design — it is a courtesy check for cooperative
authors, not an enforcement boundary. Also mention that the hook needs two
sibling scripts, `strip-attribution.sh` and `detypo.pl`, to run at all — they
are copied into `.githooks/` alongside it so the hook can find them next to
itself even outside a Claude Code session, where `$CLAUDE_PLUGIN_ROOT` is
unset. Only once the user has this information, ask whether they want it
installed in this clone. **Only on explicit confirmation**, run:

```bash
mkdir -p .githooks
cp "${CLAUDE_PLUGIN_ROOT}/scripts/commit-msg" .githooks/commit-msg
cp "${CLAUDE_PLUGIN_ROOT}/scripts/strip-attribution.sh" .githooks/strip-attribution.sh
cp "${CLAUDE_PLUGIN_ROOT}/scripts/detypo.pl" .githooks/detypo.pl
chmod +x .githooks/commit-msg .githooks/strip-attribution.sh
git config core.hooksPath .githooks
```

If the user declines, say the hook was not installed and move on.

**Step 6 — orphaned `worktree-*` branches on origin.** List the candidates
first, before proposing to delete anything:

```bash
git ls-remote --heads origin 'worktree-*'
git fetch origin
for b in $(git ls-remote --heads origin 'worktree-*' | awk '{print $2}' | sed 's|refs/heads/||'); do
  echo "== $b: $(git rev-list --count origin/main..origin/$b 2>/dev/null) commits ahead of main"
done
```

The branch *names* above come from the live `git ls-remote` and are always
current, but the ahead-count for each one reads local remote-tracking refs
(`origin/$b`) — the `git fetch origin` before the loop is required so those
refs actually exist for any branch created since the last fetch. Without it,
a newly created branch's `origin/$b` ref may be missing locally, the
`2>/dev/null` on the count silently swallows that, and the reported count
comes out blank or misleading rather than a real number.

Cross-check for open PRs before treating anything as safe to remove:

```bash
gh pr list --state open --json headRefName --jq '.[].headRefName' | grep '^worktree-' || echo "none open"
```

- If no `worktree-*` branches exist on origin, say so and stop here — nothing
  to offer.
- Otherwise, present the full list with each branch's ahead-count, and flag
  separately any branch that has an open PR — treat those as not orphaned and
  exclude them from the deletion offer regardless of ahead-count. **Then stop
  and ask for confirmation** on the remaining candidates, showing exactly
  which branch names would be deleted. Do not batch-delete without having
  shown the list first. Only after the user confirms, delete each confirmed
  branch:

  ```bash
  git push origin --delete <branch>
  ```

  If the user declines, or confirms only some of the listed branches, delete
  only what was confirmed and report which branches were left alone.

**Wrap-up.** Give a short final summary: what was already fine, what changed
in this run (settings file, squash-merge setting, commit-msg hook,
deleted branches), and what the user declined or is still deciding on. This
command is safe to re-run any time — re-running it after a "no" simply offers
the same change again with the same up-front confirmation gate.
