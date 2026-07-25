# Design principles — and how to extend the system consistently

SKILL.md documents *what* the current defaults are. This file explains *why*, so a new mechanic (a
new workflow, a new input, a CI step for an ecosystem none of these cover yet) can be designed to fit
rather than bolted on inconsistently.

## Why reusable workflows at all

Maintaining a copy of the same CI YAML in every repo drifts — a bugfix or a version bump has to be
applied N times, and inevitably some repos are missed. A central `workflow_call` source fixes this:
one tag bump reaches every consumer, JDK/Gradle/Action versions stay consistent org-wide, and
onboarding a new repo takes minutes instead of hours of copying and adapting a YAML file from another
project.

**Applies to new mechanics:** if something is going to be needed by more than one repo, it belongs in
the shared `workflows` repo as a new `workflow_call` workflow — not copy-pasted into each consumer
"just this once."

## Why Java 25 as the default

OneLiteFeather projects target current JDK LTS releases. Repos with a genuine reason to differ (e.g.
a dependency that caps at an older JDK) override `java-version` explicitly rather than the default
changing per-project.

**Applies to new mechanics:** pick one sensible org-wide default and let outliers override it via an
input — don't make every consumer specify something that's true for 95% of them.

## Why a matrix on PRs but single-OS on publish

PRs need to catch platform-specific bugs (path separators, line endings, filesystem case
sensitivity) early — that's what the 3-OS matrix is for. Publish only needs to produce one
reproducible artifact; running it three times would just triple publish time for no benefit.

**Applies to new mechanics:** ask whether a new job is validating (matrix, catch differences) or
producing (single, reproducible) before deciding whether it needs multiple runners.

## Why path filters

Building a Markdown-only PR on the full 3-OS matrix wastes CI minutes for zero signal.
`dorny/paths-filter` checks in under 5 seconds whether any Gradle-relevant file actually changed; if
not, the PR stays green without ever starting a runner. The trade-off: an unusual repo layout can
make the default filter miss real changes — that's what a custom `paths-filters` input or
`force-build: true` is for.

**Applies to new mechanics:** a new build-triggering workflow should default to path-filtered, with
an escape hatch to force it, rather than always running unconditionally.

## Why no `clean` in any default task

`clean` deletes build outputs and defeats incremental compilation — with Gradle's cache (via
`setup-gradle`), a plain `build test` run is typically 3–10× faster than `clean build test`. Anyone
who genuinely needs a from-scratch build reaches for `force-build: true` plus an empty cache, not a
default that punishes everyone else's cache hit rate.

**Applies to new mechanics:** never prepend `clean` (or an equivalent "wipe and start over" step) to
a default task chain.

## Why `cancel-in-progress: true` on PRs but `false` on publish

Two pushes to the same PR branch in quick succession would otherwise run two full matrices in
parallel — the second push makes the first's result obsolete anyway, so cancelling it saves runner
minutes. Publish is the opposite: cancelling mid-upload can leave an inconsistent artifact behind, so
publish runs always finish once started.

**Applies to new mechanics:** anything that produces a durable side effect (a publish, a deploy, a
signed artifact) should not be cancellable mid-run; anything that's purely validation and gets
superseded by a newer run should be.

## Why cache is read-only on non-default branches

`setup-gradle` writes to the shared cache on every run by default. With many concurrent PRs, that
blows past cache storage limits fast. Writing only from the default branch and reading everywhere
else keeps the cache both useful and bounded.

**Applies to new mechanics:** any new workflow that uses a shared cache should default to
write-from-default-branch-only, the same way.

## Why release-please instead of `@semantic-release` or manual tagging

Conventional Commits → automatic changelog → automatic tag → automatic publish, with no manual
version bumping and no changelog anyone has to remember to update. See the `release-please` skill for
the mechanics; this principle is why it was adopted org-wide rather than left per-repo.

**Applies to new mechanics:** any new release-triggering mechanism should derive from a single automated signal (a commit convention, a merge event) rather than a human remembering to bump a version or write a changelog entry by hand.

## Why Renovate instead of Dependabot for the pipeline pins

Dependabot bumps individual GitHub Actions references but can't group reusable-workflow-ref updates
into one PR or auto-merge them the same way Renovate can. See the `renovate` skill for the mechanics.

**Applies to new mechanics:** when a new mechanic introduces its own set of versioned references to keep current, prefer whichever update tool can group and auto-merge them safely, rather than defaulting to whatever's built into the platform.

## How to add a new reusable workflow to the `workflows` repo

1. **Confirm it's actually reusable** — more than one repo needs it, or will soon. A one-off stays in
   the consuming repo (see SKILL.md's "Introducing a new mechanic?" decision tree).
2. **Shape the `workflow_call` schema like the existing ones**: every input gets a `description`,
   an explicit `type`, and a sensible `default` unless it's genuinely required (image name, version,
   a context path — things with no reasonable org-wide default). Secrets follow the same
   required/optional split as `gradle-publish.yml` (both required, since publish can't succeed
   without credentials) vs. `gradle-docker-context.yml` (both optional, since not every Gradle build
   needs the private Maven repo).
3. **Add a concurrency group** if the workflow has a durable side effect or could reasonably be
   triggered twice in quick succession — `cancel-in-progress` follows the PR-vs-publish principle
   above.
4. **Document required permissions** in a comment above any step that needs them (e.g.
   `id-token: write` for keyless signing) — a caller shouldn't have to read the workflow's internals
   to know what to grant.
5. **`secrets: inherit`-friendly**: never require a caller to explicitly re-declare every secret by
   name in a `with:`/`secrets:` block if `secrets: inherit` already covers it — that's exactly the
   pattern `gradle-publish.yml`, `gradle-docker-context.yml`, and `docker-publish.yml` all follow.
6. **Conventional Commit PR** against the `workflows` repo's own default branch — it's release-please
   managed too (see the `release-please` skill), so a `feat:`/`fix:` commit becomes a real version
   bump automatically.
7. **Tag and let consumers pick it up** — the new workflow ships as part of the next `workflows`
   release. Consumers should pin to it using a full SemVer tag (e.g. `@v2.5.0`), never `@main` or a
   bare major alias — that's what lets their existing Renovate-managed pin bump (see the `renovate`
   skill) pick up the new tag automatically, no separate announcement needed for the mechanism to
   reach them (though a heads-up for anything behavior-changing is still good practice).
