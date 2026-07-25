---
name: release-please
description: How to set up or migrate a OneLiteFeather Gradle project onto Release Please — version, changelog, and GitHub release automation driven by Conventional Commits, replacing `@semantic-release`, `release-drafter`, or manual tagging. Use this whenever setting up CI for a new OneLiteFeather repo, migrating an existing repo off legacy release tooling, or touching `release-please-config.json` / `.release-please-manifest.json` / `release-please.yml` in a OneLiteFeather Gradle project — single-module or multi-module.
---

# Release Please: version, changelog, and release automation

[Release Please](https://github.com/googleapis/release-please) reads Conventional Commits since the
last release and turns them into a changelog, a version bump, and a release PR. Merging that PR tags
the release, which in turn triggers publishing. There is no manual version bumping and no separate
changelog to remember to update — the version marker in `build.gradle.kts` is the only thing a human
(or a merge) ever changes, and only via the release PR that Release Please itself opens.

This replaces `@semantic-release`, `release-drafter`, and any manually-tagged `push: tags: [...]`
publish workflow. If you find one of those in a repo, that's a migration case — see below.

## The version-marker convention: `build.gradle.kts`, not `gradle.properties`

The version lives in the root `build.gradle.kts`, as a plain Kotlin property assignment with a
trailing marker comment:

```kotlin
version = "0.1.0" // x-release-please-version
```

Release Please's built-in `generic` extra-files updater finds this exact marker comment and rewrites
the value on the same line — it works on any text file, `.kts` included, so no ecosystem-specific
updater is needed. Point `extra-files` at `build.gradle.kts` (see `release-please-config.json` below)
and this is the *only* place the version is declared. Gradle reads `project.version` from this
assignment natively — nothing else has to parse or propagate it.

**Do not do either of the following, even though both show up in older OneLiteFeather workflows:**

```bash
# ANTI-PATTERN — do not parse gradle.properties by hand in a workflow step:
VERSION="$(grep -E '^version' gradle.properties | head -n1 | cut -d= -f2 | cut -d'#' -f1 | xargs)"
```

```kotlin
// ANTI-PATTERN — do not write a custom Gradle task that rewrites version strings across files:
tasks.register("syncVersion") {
    doLast {
        val other = file("some/other/file.txt")
        other.writeText(other.readText().replace(oldVersion, newVersion))
    }
}
```

Both exist to work around the version living in the wrong file, or living in more than one file.
With the marker directly in `build.gradle.kts` and `extra-files` pointing at only that one file,
neither is needed: Release Please updates the single source of truth, and Gradle reads it directly.
If a repo has a `gradle.properties`-based version *and* a script like the one above, migrating it
(see below) means deleting the script, not porting it.

## How the pieces fit together

Three files, plus one workflow:

- **`release-please-config.json`** — what to release and how. `release-type: "simple"` (not
  `"java"`): `"java"` assumes a Maven-shaped project with a `pom.xml`-like canonical version file,
  which Gradle projects don't have. `"simple"` makes no such assumption — combined with an explicit
  `extra-files` entry, you get full control over exactly one file being bumped, which is what a
  Gradle project actually needs.
- **`.release-please-manifest.json`** — the current version per package. Release Please reads and
  writes this; you only ever set the initial value by hand.
- **`.github/workflows/release-please.yml`** — runs `googleapis/release-please-action@v5` on every
  push to the default branch, and chains a publish job that only runs when a release was actually
  created.
- **`CHANGELOG.md`** — created empty, filled in automatically from then on. Never hand-edit it.

## Setup — new repo

For a brand-new, empty single-module Gradle repo:

**1. `release-please-config.json`** (repo root):

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "simple",
  "include-component-in-tag": false,
  "include-v-in-tag": true,
  "bootstrap-sha": "HEAD",
  "pull-request-header": "",
  "packages": {
    ".": {
      "package-name": "my-library",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        { "type": "generic", "path": "build.gradle.kts" }
      ]
    }
  }
}
```

Replace `my-library` with the repo's own lowercase name. `bootstrap-sha: "HEAD"` is fine for a
brand-new repo — Release Please only looks at commits after this SHA.

**2. `.release-please-manifest.json`** (repo root):

```json
{ ".": "0.1.0" }
```

**3. In `build.gradle.kts`, mark the version line:**

```kotlin
version = "0.1.0" // x-release-please-version
```

Must match the manifest exactly at bootstrap time.

**4. `CHANGELOG.md`** — create it empty. Release Please fills it in.

**5. `.github/workflows/release-please.yml`:**

```yaml
name: release-please

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

jobs:
  release-please:
    runs-on: ubuntu-latest
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
    steps:
      - id: release
        uses: googleapis/release-please-action@v5
        with:
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json

  publish:
    needs: release-please
    if: needs.release-please.outputs.release_created == 'true'
    uses: OneLiteFeatherNET/workflows/.github/workflows/gradle-publish.yml@v2.4.0
    with:
      java-version: "25"
      java-distribution: "temurin"
    secrets: inherit
```

Do **not** also add an `on: push: tags: [...]` publish workflow — Release Please tags using the
default `GITHUB_TOKEN`, which does not re-trigger tag-push workflows in the same repo. The `publish`
job above is what actually runs, chained via `needs`/`if`, not a separate tag trigger. Two publish
paths means either a dead workflow that never fires, or (worse) two workflows racing on the same tag.

**6.** Open a PR with these files, merge it. From then on, every merge that contains a `feat:`/`fix:`
commit produces (or updates) a release PR titled `chore(main): release X.Y.Z`. Merging *that* PR is
what tags, releases, and publishes.

For which workflow to chain into `publish` when Docker is involved instead of (or in addition to)
Maven publishing, see the `workflows` skill.

## Migration — existing repo

Signs a repo needs migrating rather than fresh setup:

- A `.releaserc*` file or a `release.config.*` (semantic-release).
- A `.github/workflows/release-drafter.yml` or similar.
- A publish workflow triggered by `on: push: tags: ["v*"]` with no Release Please involved.
- A version-sync script in a workflow (the `grep`/`cut` anti-pattern above) or a custom Kotlin
  `replace`-style Gradle task.

Steps:

1. **Determine the current version.** Check the latest Git tag (`git describe --tags --abbrev=0`) or
   the current `version` in `build.gradle.kts`/`gradle.properties`, whichever is authoritative today.
2. **Determine `bootstrap-sha`.** This must be the SHA of the commit the *current* version already
   reflects — i.e. the last commit before Release Please starts managing releases. Usually
   `git rev-parse HEAD` on the default branch right before merging the migration PR. Getting this
   wrong makes Release Please either miss commits (too new a SHA) or re-include already-released
   commits in the first changelog (too old a SHA).
3. **Add the three files** as in Setup above, but:
   - `bootstrap-sha` is the SHA from step 2, not `"HEAD"`.
   - `.release-please-manifest.json` gets the current version from step 1, not `0.1.0`.
   - If the version currently lives in `gradle.properties`, move the marker comment to
     `build.gradle.kts` instead of leaving it in both places — `extra-files` should point at
     `build.gradle.kts` only.
4. **Remove the old tooling:** delete `.releaserc*`/`release.config.*`, delete
   `release-drafter.yml` and its `.github/release-drafter.yml` config, delete any tag-triggered
   publish workflow that duplicates what the new chained `publish` job does, and delete any
   version-parsing script or Kotlin `replace` task (see the anti-pattern section above) — don't port
   it forward, it no longer has a job to do.
5. **Open the migration PR**, title it as a `chore:` commit (e.g. `chore: migrate to release-please`)
   so it doesn't itself trigger an unwanted version bump. Merge it.
6. **Verify** the next `feat:`/`fix:` merge produces a release PR at the *next* logical version above
   what `.release-please-manifest.json` currently holds — not a reset back to `0.1.0`.

## Single-module vs. multi-module

Everything above is single-module: one `packages["."]` entry, one version, one `build.gradle.kts`.
A multi-module Gradle project (several subprojects that should version independently) uses the same
mechanism with multiple `packages` entries instead — see `references/multi-module.md`.

## Further reference

`references/multi-module.md` — a generic multi-module example: independent versions per subproject,
each with its own marker and its own manifest entry.
