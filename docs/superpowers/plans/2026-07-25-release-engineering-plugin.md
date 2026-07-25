# Release-Engineering Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new `release-engineering` plugin to this Claude Code plugin marketplace, containing three skills (`release-please`, `renovate`, `workflows`) that teach OneLiteFeather's CI/CD standard, per `docs/superpowers/specs/2026-07-25-release-engineering-plugin-design.md`.

**Architecture:** Pure skill-knowledge plugin (no MCP servers, no hooks) — one directory per skill under `plugins/release-engineering/skills/`, each with a `SKILL.md` entry point and (where the topic is large enough) a `references/` subfolder for deep-dive content, mirroring the existing `plugins/minestom-knowledge` plugin's structure exactly.

**Tech Stack:** Markdown with YAML frontmatter (`SKILL.md` files), JSON (plugin manifests, `marketplace.json`). No build step, no test framework in this repo — "tests" in this plan are structural/content verification via `jq` (JSON validity) and `grep` (required frontmatter fields and key content markers), matching the fact that this repo has no `package.json`, no CI, and no linter configured.

## Global Constraints

- Plugin name: `release-engineering`. Skill names: `release-please`, `renovate`, `workflows` (all lowercase, kebab-case, matching the `minestom-knowledge` skill-naming convention).
- Every `SKILL.md` needs YAML frontmatter with exactly `name` and `description` fields (no other frontmatter keys — verified against all 8 existing `minestom-knowledge` skills).
- Release Please version-marker standard: a comment directly in the root `build.gradle.kts` — `version = "1.2.3" // x-release-please-version` — never `gradle.properties`, never a custom Kotlin `replace` task or shell-based parsing (`grep`/`cut` on `gradle.properties`). This rule appears in `release-please/SKILL.md` as an explicit anti-pattern callout.
- Content is generic/example-driven with placeholder names (`my-library`, `module-a`, etc.) — no content is copy-pasted verbatim from one specific real OneLiteFeather repo's config as "the" example, though real repos may be named as brief "see it live in X" pointers.
- No community-health-file templates, no org-wide migration tracking lists, no SBOM integration — explicitly out of scope per the spec.
- Every new/modified plugin manifest and `marketplace.json` must remain valid JSON (`jq empty <file>` exits 0).

---

### Task 1: Plugin scaffold — manifests

**Files:**
- Create: `plugins/release-engineering/.claude-plugin/plugin.json`
- Create: `plugins/release-engineering/.codex-plugin/plugin.json`
- Create: `plugins/release-engineering/.antigravity-plugin/plugin.json`

**Interfaces:**
- Produces: the plugin directory `plugins/release-engineering/` that Tasks 3–11 populate with `skills/`. No code interfaces — these are static JSON manifests, structurally identical in shape to `plugins/minestom-knowledge`'s three manifests.

- [ ] **Step 1: Write a failing structural check**

Run this before creating any files — it must fail because the directory doesn't exist yet:

```bash
test -f plugins/release-engineering/.claude-plugin/plugin.json && echo "UNEXPECTED: already exists" || echo "OK: missing as expected"
```

Expected output: `OK: missing as expected`

- [ ] **Step 2: Create `plugins/release-engineering/.claude-plugin/plugin.json`**

```json
{
  "name": "release-engineering",
  "displayName": "Release Engineering",
  "version": "0.1.0",
  "description": "OneLiteFeather's CI/CD standard: Release Please (version/changelog/release automation from Conventional Commits), the central Renovate preset and general Renovate config help, and the org's reusable GitHub Actions workflows (build, publish, Docker, with Gradle-specific guidance).",
  "author": { "name": "OneLiteFeather", "url": "https://github.com/OneLiteFeatherNET" },
  "license": "MIT",
  "keywords": ["release-please", "renovate", "github-actions", "reusable-workflows", "gradle", "docker", "ci-cd", "conventional-commits"]
}
```

- [ ] **Step 3: Create `plugins/release-engineering/.codex-plugin/plugin.json`**

```json
{
  "name": "release-engineering",
  "version": "0.1.0",
  "description": "OneLiteFeather's CI/CD standard: Release Please (version/changelog/release automation from Conventional Commits), the central Renovate preset and general Renovate config help, and the org's reusable GitHub Actions workflows (build, publish, Docker, with Gradle-specific guidance).",
  "author": { "name": "OneLiteFeather", "url": "https://github.com/OneLiteFeatherNET" },
  "license": "MIT",
  "keywords": ["release-please", "renovate", "github-actions", "reusable-workflows", "gradle", "docker", "ci-cd", "conventional-commits"],
  "skills": "./skills/",
  "hooks": {}
}
```

- [ ] **Step 4: Create `plugins/release-engineering/.antigravity-plugin/plugin.json`**

```json
{
  "name": "release-engineering",
  "version": "0.1.0",
  "description": "OneLiteFeather's CI/CD standard: Release Please (version/changelog/release automation from Conventional Commits), the central Renovate preset and general Renovate config help, and the org's reusable GitHub Actions workflows (build, publish, Docker, with Gradle-specific guidance).",
  "author": { "name": "OneLiteFeather", "url": "https://github.com/OneLiteFeatherNET" },
  "license": "MIT",
  "keywords": ["release-please", "renovate", "github-actions", "reusable-workflows", "gradle", "docker", "ci-cd", "conventional-commits"],
  "skills": "./skills/"
}
```

- [ ] **Step 5: Verify all three are valid JSON with matching `name`**

```bash
for f in plugins/release-engineering/.claude-plugin/plugin.json \
         plugins/release-engineering/.codex-plugin/plugin.json \
         plugins/release-engineering/.antigravity-plugin/plugin.json; do
  jq -e '.name == "release-engineering"' "$f" >/dev/null && echo "OK: $f" || echo "FAIL: $f"
done
```

Expected: three `OK:` lines, no `FAIL:` lines.

- [ ] **Step 6: Commit**

```bash
git add plugins/release-engineering/.claude-plugin/plugin.json \
        plugins/release-engineering/.codex-plugin/plugin.json \
        plugins/release-engineering/.antigravity-plugin/plugin.json
git commit -m "feat: scaffold release-engineering plugin manifests"
```

---

### Task 2: Register the plugin in `marketplace.json` and `README.md`

**Files:**
- Modify: `.claude-plugin/marketplace.json`
- Modify: `README.md`

**Interfaces:**
- Consumes: `plugins/release-engineering` directory existing (Task 1).
- Produces: nothing consumed by later tasks — this is a leaf registration step, but doing it early means every subsequent task can be checked out independently without the plugin being "invisible" to the marketplace tooling in the meantime.

- [ ] **Step 1: Write a failing check**

```bash
jq -e '.plugins[] | select(.name == "release-engineering")' .claude-plugin/marketplace.json >/dev/null \
  && echo "UNEXPECTED: already registered" || echo "OK: not registered yet"
```

Expected: `OK: not registered yet`

- [ ] **Step 2: Add the plugin entry to `.claude-plugin/marketplace.json`**

Open `.claude-plugin/marketplace.json`. Find the `"plugins"` array's last entry (currently `minestom-knowledge`, ending with its closing `}` followed by `]`). Add a new object after the `minestom-knowledge` entry's closing `}` (add a `,` after that `}` if not already followed by one):

```json
    {
      "name": "release-engineering",
      "displayName": "Release Engineering",
      "source": "./plugins/release-engineering",
      "description": "OneLiteFeather's CI/CD standard: Release Please, the central Renovate preset plus general Renovate config help, and the reusable GitHub Actions workflows (build, publish, Docker, Gradle specifics).",
      "category": "productivity",
      "keywords": ["release-please", "renovate", "github-actions", "reusable-workflows", "gradle", "docker", "ci-cd"]
    }
```

The full `"plugins"` array must end up with four entries: `framework`, `framework-code-navigation`, `minestom-knowledge`, `release-engineering`, in that order.

- [ ] **Step 3: Verify JSON validity and the new entry**

```bash
jq empty .claude-plugin/marketplace.json && echo "OK: valid JSON"
jq -e '.plugins[] | select(.name == "release-engineering") | .source == "./plugins/release-engineering"' .claude-plugin/marketplace.json >/dev/null \
  && echo "OK: entry present" || echo "FAIL: entry missing or wrong source"
jq '.plugins | length' .claude-plugin/marketplace.json
```

Expected: `OK: valid JSON`, `OK: entry present`, and `4` as the length.

- [ ] **Step 4: Add a row to the plugin table in `README.md`**

In `README.md`, find the `## The plugins` table (three rows: `framework`, `framework-code-navigation`, `minestom-knowledge`). Add a fourth row directly after the `minestom-knowledge` row:

```markdown
| **release-engineering** | OneLiteFeather's CI/CD standard: Release Please, the central Renovate preset plus general Renovate config help, and the reusable GitHub Actions workflows (build, publish, Docker, Gradle specifics). No MCP servers, pure skill content. |
```

- [ ] **Step 5: Add an install line to the `## Install` → `### Claude Code` section**

In the same `README.md`, in the `### Claude Code` fenced bash block, after the line `/plugin install minestom-knowledge@onelitefeather-claude-marketplace`, add:

```bash

# CI/CD standard: Release Please, Renovate, reusable workflows
/plugin install release-engineering@onelitefeather-claude-marketplace
```

- [ ] **Step 6: Verify the README changes landed**

```bash
grep -c "release-engineering" README.md
```

Expected: `2` (the table row's `**release-engineering**` cell, and the `/plugin install
release-engineering@onelitefeather-claude-marketplace` line — the comment line above it intentionally
doesn't repeat the plugin name). Confirm both lines are present via
`grep -n "release-engineering" README.md`.

- [ ] **Step 7: Commit**

```bash
git add .claude-plugin/marketplace.json README.md
git commit -m "feat: register release-engineering in marketplace and README"
```

---

### Task 3: `release-please/SKILL.md`

**Files:**
- Create: `plugins/release-engineering/skills/release-please/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks (self-contained content file).
- Produces: the `## Single-module vs. multi-module` section ends with a pointer to `references/multi-module.md`, which Task 4 creates — the exact relative path `references/multi-module.md` must match.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/release-engineering/skills/release-please/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
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
```

- [ ] **Step 3: Verify frontmatter and required content markers**

```bash
f=plugins/release-engineering/skills/release-please/SKILL.md
head -1 "$f" | grep -qx -- '---' && echo "OK: starts with frontmatter fence"
grep -q '^name: release-please$' "$f" && echo "OK: name field"
grep -q '^description: ' "$f" && echo "OK: description field"
grep -q 'x-release-please-version' "$f" && echo "OK: version marker documented"
grep -q '## Setup' "$f" && echo "OK: Setup section"
grep -q '## Migration' "$f" && echo "OK: Migration section"
grep -q 'references/multi-module.md' "$f" && echo "OK: points to multi-module reference"
grep -qi 'ANTI-PATTERN' "$f" && echo "OK: anti-pattern callout present"
```

Expected: eight `OK:` lines, no errors.

- [ ] **Step 4: Commit**

```bash
git add plugins/release-engineering/skills/release-please/SKILL.md
git commit -m "feat: add release-please skill"
```

---

### Task 4: `release-please/references/multi-module.md`

**Files:**
- Create: `plugins/release-engineering/skills/release-please/references/multi-module.md`

**Interfaces:**
- Consumes: `plugins/release-engineering/skills/release-please/SKILL.md` (Task 3) links here — no code dependency, just needs the path to exist.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/release-engineering/skills/release-please/references/multi-module.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
# Multi-module Release Please setup

SKILL.md covers single-module (one `packages["."]` entry). A Gradle multi-module project where
subprojects should release and version **independently** uses the same mechanism with one `packages`
entry per subproject path instead of a single `"."` entry.

## Layout

```
my-project/
├── settings.gradle.kts
├── build.gradle.kts          # root — only versioned too if it's itself published, see below
├── module-a/
│   └── build.gradle.kts
└── module-b/
    └── build.gradle.kts
```

## `release-please-config.json`

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "simple",
  "include-component-in-tag": true,
  "include-v-in-tag": true,
  "separate-pull-requests": true,
  "bootstrap-sha": "HEAD",
  "pull-request-header": "",
  "packages": {
    "module-a": {
      "package-name": "module-a",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        { "type": "generic", "path": "module-a/build.gradle.kts" }
      ]
    },
    "module-b": {
      "package-name": "module-b",
      "changelog-path": "CHANGELOG.md",
      "extra-files": [
        { "type": "generic", "path": "module-b/build.gradle.kts" }
      ]
    }
  }
}
```

Two differences from single-module worth calling out:

- **`include-component-in-tag: true`** (single-module uses `false`). With more than one package,
  tags must say *which* package they belong to — `module-a-v1.2.0` vs. `module-b-v0.4.1` — otherwise
  two modules releasing the same version number would collide on one Git tag.
- **`separate-pull-requests: true`** — each module gets its own release PR instead of one PR bundling
  every pending module bump. Set it to `false` only if the modules are meant to always release
  together; independent versioning almost always means independent PRs too.

## `.release-please-manifest.json`

One entry per package path, each tracking its own version:

```json
{
  "module-a": "1.2.0",
  "module-b": "0.4.1"
}
```

## Per-module version marker

Each subproject's own `build.gradle.kts` gets its own marker line, exactly like single-module:

```kotlin
// module-a/build.gradle.kts
version = "1.2.0" // x-release-please-version
```

```kotlin
// module-b/build.gradle.kts
version = "0.4.1" // x-release-please-version
```

## How Release Please decides which module a commit bumps

Release Please looks at which files a commit touched relative to each package's path key. A commit
that only touches files under `module-a/` bumps only `module-a`'s version and only appears in
`module-a`'s changelog/release PR. A commit touching files outside every declared package path (e.g.
a root-level `README.md` or `settings.gradle.kts` change) doesn't map to any package unless you also
add a `"."` entry for the root — add one, in the same shape as the single-module config, if the root
project itself is published too (e.g. an aggregator artifact).

## Chaining publish per module

With multiple packages, `release-please-action@v5`'s outputs are prefixed per package as
`<package-path>--<output-name>` (double dash). This is the single biggest gotcha moving from
single-module to multi-module — the plain `release_created`/`version` outputs from the single-module
example no longer exist once more than one package is declared:

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
      module-a-released: ${{ steps.release.outputs['module-a--release_created'] }}
      module-b-released: ${{ steps.release.outputs['module-b--release_created'] }}
    steps:
      - id: release
        uses: googleapis/release-please-action@v5
        with:
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json

  publish-module-a:
    needs: release-please
    if: needs.release-please.outputs.module-a-released == 'true'
    uses: OneLiteFeatherNET/workflows/.github/workflows/gradle-publish.yml@v2.4.0
    with:
      java-version: "25"
      build-task: ":module-a:build"
      publish-task: ":module-a:publish"
    secrets: inherit

  publish-module-b:
    needs: release-please
    if: needs.release-please.outputs.module-b-released == 'true'
    uses: OneLiteFeatherNET/workflows/.github/workflows/gradle-publish.yml@v2.4.0
    with:
      java-version: "25"
      build-task: ":module-b:build"
      publish-task: ":module-b:publish"
    secrets: inherit
```

Each module publishes independently, gated on its own `--release_created` output, using Gradle's
project-qualified task syntax (`:module-a:build`, `:module-a:publish`) so one module's publish never
rebuilds or republishes its siblings.
```

- [ ] **Step 3: Verify content markers**

```bash
f=plugins/release-engineering/skills/release-please/references/multi-module.md
grep -q 'include-component-in-tag' "$f" && echo "OK: tag-collision explanation present"
grep -q 'separate-pull-requests' "$f" && echo "OK: separate-pull-requests explained"
grep -q -- '--release_created' "$f" && echo "OK: per-package output naming documented"
grep -c 'x-release-please-version' "$f" | grep -qx 2 && echo "OK: two per-module markers"
```

Expected: four `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/release-engineering/skills/release-please/references/multi-module.md
git commit -m "feat: add release-please multi-module reference"
```

---

### Task 5: `renovate/SKILL.md`

**Files:**
- Create: `plugins/release-engineering/skills/renovate/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: links to `references/cookbook.md` (Task 6) and `references/managers.md` (Task 7) — exact relative paths must match what those tasks create.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/release-engineering/skills/renovate/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
---
name: renovate
description: OneLiteFeather's central Renovate preset for dependency updates, plus general help writing and troubleshooting any Renovate config — packageRules, grouping, automerge, scheduling, custom managers, and manager-specific behavior across Gradle, Docker, GitHub Actions, npm, Ansible, Python, and Dart projects. Use this whenever setting up or migrating a repo's renovate.json, adding the central OneLiteFeather preset, or writing/debugging any Renovate config option — including ones OneLiteFeather doesn't currently use.
---

# Renovate: dependency updates

[Renovate](https://docs.renovatebot.com/) opens PRs that bump dependency versions, on a schedule,
grouped and auto-merged according to config. OneLiteFeather runs it as a GitHub App, configured per
repo via `renovate.json`. This skill covers both the org's standard setup and general Renovate
config help — the two references below go well beyond what OneLiteFeather currently uses, since the
goal is to actually answer "how do I configure X in Renovate," not just "how do I adopt the preset."

Renovate instead of Dependabot for the pipeline pins specifically (see below) because it groups
reusable-workflow-ref updates into one PR and can auto-merge minor/patch/digest bumps — Dependabot
bumps each Action reference individually and can't group or auto-merge them the same way.

## Org standard: the central preset

Every OneLiteFeather repo's `renovate.json` should extend the central preset instead of rolling its
own config:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "github>OneLiteFeatherNET/renovate:default(OneLiteFeatherNET/<team>-maintainers)"
  ]
}
```

Replace `<team>-maintainers` with the actual GitHub team responsible for the repo (e.g.
`titan-maintainers`). This argument is **not optional** — the preset uses it to set that team as the
reviewer on every Renovate PR; leaving the placeholder in means PRs get no reviewer assigned.

Add a platform flavor as a second `extends` entry when it applies:

```json
{
  "extends": [
    "github>OneLiteFeatherNET/renovate:default(OneLiteFeatherNET/<team>-maintainers)",
    "github>OneLiteFeatherNET/renovate:minestom"
  ]
}
```

- `:minestom` — correct versioning for `net.minestom:minestom`'s date-based scheme
  (`YYYY.MM.DD[suffix]-build`), which default SemVer parsing gets wrong.
- `:paper` — correct versioning for `io.papermc.paper:paper-api`'s `X.Y.Z-<mc-version>` scheme.

## What the default preset brings

`config:recommended` as its base, plus: automerge for patch updates, reviewer set to the team from
the argument, `Europe/Berlin` timezone, an office-hours schedule (`schedule:officeHours` +
`schedule:automergeOfficeHours`), semantic commit messages, a `renovate` label on every PR, and
vulnerability alerts enabled. Don't re-declare any of these in a repo's own `renovate.json` — that's
what migrating off a non-canonical config (below) is meant to clean up.

## Migrating off a non-canonical config

Signs a repo's `renovate.json` predates the org standard and should be migrated:

- `"extends": ["github>onelitefeathernet/renovate"]` — **lowercase** org name, no `:default(...)`
  team argument. Works today because GitHub org lookups are case-insensitive, but carries no reviewer
  assignment and none of the office-hours/automerge tuning the canonical `:default(...)` form adds.
- `"extends": ["config:base"]` or `"extends": ["config:recommended"]` directly, with no reference to
  the org preset at all — usually accompanied by hand-rolled `packageRules` re-implementing things
  the preset already provides (patch automerge, semantic commits, a label).

Migrate by replacing the entire `extends` array with the canonical `:default(<team>-maintainers)`
form (plus a platform flavor if needed), and deleting any `packageRules` that only duplicated what
the preset already does. Keep only `packageRules` that encode something genuinely repo-specific — see
`references/cookbook.md` for what's worth keeping vs. what's redundant with the preset.

## Renovate for the pipeline pins themselves

Separately from a repo's own dependencies, Renovate also keeps a repo's `uses:
OneLiteFeatherNET/workflows/.github/workflows/*.yml@vX.Y.Z` pins current — this is why the pin
strategy in the `workflows` skill can insist on a full SemVer tag instead of a `@main`/major-alias
reference: Renovate's `github-actions` manager detects that pin format automatically and opens a PR
whenever a new tag is published, no extra config needed beyond the standard preset already being
active. See `references/managers.md` for the manager's exact detection rules and
`references/cookbook.md` for grouping GitHub Actions updates into a single weekly PR instead of one
PR per reusable workflow.

## Beyond the org standard

- `references/cookbook.md` — a broad reference of Renovate config options (scheduling, grouping,
  automerge, ignoring dependencies, custom regex managers, lockfile maintenance, vulnerability
  alerts), not limited to what OneLiteFeather currently has configured.
- `references/managers.md` — manager-specific notes per ecosystem actually present across
  OneLiteFeather repos: Gradle, Docker, GitHub Actions, npm/Node, Ansible, Python, Dart/pub.
```

- [ ] **Step 3: Verify frontmatter and content markers**

```bash
f=plugins/release-engineering/skills/renovate/SKILL.md
head -1 "$f" | grep -qx -- '---' && echo "OK: frontmatter fence"
grep -q '^name: renovate$' "$f" && echo "OK: name field"
grep -q ':default(OneLiteFeatherNET/<team>-maintainers)' "$f" && echo "OK: canonical preset shown"
grep -q ':minestom' "$f" && grep -q ':paper' "$f" && echo "OK: both flavors documented"
grep -q 'references/cookbook.md' "$f" && grep -q 'references/managers.md' "$f" && echo "OK: both references linked"
```

Expected: five `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/release-engineering/skills/renovate/SKILL.md
git commit -m "feat: add renovate skill"
```

---

### Task 6: `renovate/references/cookbook.md`

**Files:**
- Create: `plugins/release-engineering/skills/renovate/references/cookbook.md`

**Interfaces:**
- Consumes: `plugins/release-engineering/skills/renovate/SKILL.md` (Task 5) links here.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/release-engineering/skills/renovate/references/cookbook.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
# Renovate config cookbook

General-purpose Renovate config reference — not limited to what OneLiteFeather currently has
configured. SKILL.md covers the org-standard preset; this file is for "how do I configure X"
questions the preset alone doesn't answer.

## Outdated syntax to watch for

Renovate renames config keys periodically. Blog posts and older examples online commonly use names
that no longer work:

| Old name (don't use) | Current name |
|---|---|
| `regexManagers` | `customManagers` (with `customType: "regex"` per entry) |
| `fileMatch` (inside a custom manager) | `managerFilePatterns` |
| `baseBranches` | `baseBranchPatterns` |

If a config snippet from an older tutorial doesn't validate, check this table before assuming the
snippet's intent was wrong — often only the key name changed.

## Scheduling

- `schedule` — an array of time-window strings (e.g. `["before 06:00 on monday"]`,
  `"schedule:officeHours"` preset) controlling when new branches/PRs are created.
- `automergeSchedule` — a separate window for when automerges are allowed to happen, independent of
  `schedule`.
- `timezone` — an IANA zone (e.g. `"Europe/Berlin"`) that `schedule`/`automergeSchedule` are
  evaluated against.
- `prHourlyLimit` / `prConcurrentLimit` — rate-limit PR creation, useful right after onboarding a
  repo with many outdated dependencies so Renovate doesn't open dozens of PRs at once.

## Matching: `packageRules`, `ignoreDeps`, `ignorePaths`

`packageRules` is an array of `{ match..., <settings to apply> }` objects, evaluated top-to-bottom,
later matches override earlier ones for the same setting:

```json
{
  "packageRules": [
    {
      "matchManagers": ["github-actions"],
      "matchUpdateTypes": ["minor", "patch", "digest"],
      "automerge": true
    },
    {
      "matchManagers": ["github-actions"],
      "matchUpdateTypes": ["major"],
      "automerge": false,
      "addLabels": ["breaking"]
    }
  ]
}
```

Common match fields: `matchManagers`, `matchPackageNames`, `matchDatasources`, `matchUpdateTypes`
(`major`/`minor`/`patch`/`digest`/`pin`/`lockFileMaintenance`).

To skip a dependency entirely rather than conditionally configure it: `ignoreDeps: ["some-package"]`
(exact names) or a `packageRules` entry with `"enabled": false` and a `matchPackageNames` filter (use
the latter when you need a pattern, not just an exact name). `ignorePaths` excludes whole file paths
from being scanned by any manager — useful for vendored/generated files that happen to look like
dependency manifests.

## Grouping

```json
{
  "packageRules": [
    {
      "matchManagers": ["github-actions"],
      "groupName": "GitHub Actions",
      "groupSlug": "github-actions"
    }
  ]
}
```

`groupName` bundles every matching update into a single PR instead of one PR per dependency.
`groupSlug` controls the branch name Renovate uses for the group (defaults to a slugified
`groupName` if omitted). `minimumGroupSize` (on some group presets) sets how many pending updates are
needed before Renovate bothers grouping instead of opening them individually.

## Automerge

- `automerge: true` — enable automerging for matched updates.
- `automergeType` — `"pr"` (default: merge the PR once checks pass), `"branch"` (push straight to
  the branch, no PR), or `"pr-comment"` (legacy comment-trigger flow).
- `platformAutomerge: true` — use GitHub's own auto-merge feature instead of Renovate merging
  directly; needed for repos with required status checks that must report through GitHub's merge
  queue.

The common pattern is automerging minor/patch/digest but never major (shown in the `packageRules`
example above) — majors usually need a human to actually read the changelog.

## Custom managers (`customManagers`, formerly `regexManagers`)

For a dependency version embedded in a file no built-in manager understands — a Kubernetes manifest,
an Ansible variable file, an arbitrary YAML/text config:

```json
{
  "customManagers": [
    {
      "customType": "regex",
      "managerFilePatterns": ["/^Dockerfile$/"],
      "matchStrings": [
        "# renovate: datasource=(?<datasource>[a-z-]+?) depName=(?<depName>.+?)\\s+ENV \\w+_VERSION=(?<currentValue>.+)\\s"
      ]
    }
  ]
}
```

`managerFilePatterns` (regex or glob) selects which files to scan. `matchStrings` is a regex with
named capture groups — `depName`, `currentValue`, and `datasource` are the ones Renovate needs at
minimum; a hardcoded `datasourceTemplate`/`versioningTemplate` can replace the `datasource` capture
group when every match in a file uses the same datasource. Reach for this only when no built-in
manager already covers the file — check `references/managers.md` first.

## Lockfile maintenance

```json
{
  "lockFileMaintenance": {
    "enabled": true,
    "schedule": ["before 06:00 on monday"]
  }
}
```

Runs a separate, periodic "refresh the lockfile even if nothing in the manifest changed" update,
independent of per-dependency PRs — picks up transitive-dependency movement that no direct version
bump would otherwise trigger.

## Dependency dashboard

`"dependencyDashboard": true` opens (and keeps updated) a single pinned issue listing every pending,
rate-limited, or errored update across the repo — the one place to see "what is Renovate currently
not doing and why" without digging through closed/open PRs.

## Vulnerability alerts

```json
{
  "vulnerabilityAlerts": {
    "labels": ["security"],
    "automerge": true
  },
  "osvVulnerabilityAlerts": true
}
```

`vulnerabilityAlerts` configures how Renovate reacts to GitHub's own vulnerability data;
`osvVulnerabilityAlerts` additionally sources advisories from [OSV.dev](https://osv.dev), useful for
ecosystems GitHub's own advisory database covers less completely.

## `config:recommended` vs. `config:best-practices`

The org preset extends `config:recommended` — the sensible baseline (dependency dashboard, semantic
commits, monorepo-aware grouping, merge-confidence badges). `config:best-practices` builds on top of
it and is *not* currently part of the org preset; consider extending a repo's own config with it on
top of the org preset when you specifically want: Docker/GitHub-Actions digest pinning, dev-dependency
pinning, treating packages with no release in over a year as abandoned, and weekly lockfile
maintenance. It's an opt-in addition, not a replacement for the org preset.

## Validating a config before opening a PR

```bash
npx --package renovate -- renovate-config-validator
```

Run from the repo root with `renovate.json` present. Catches JSON syntax errors, unknown keys (like
the renamed ones in the table above), and type mismatches before Renovate's own bot has to fail
silently or ignore the file.
```

- [ ] **Step 3: Verify content markers**

```bash
f=plugins/release-engineering/skills/renovate/references/cookbook.md
grep -q 'regexManagers' "$f" && grep -q 'customManagers' "$f" && echo "OK: rename table present"
grep -q 'managerFilePatterns' "$f" && echo "OK: custom manager key documented"
grep -q 'lockFileMaintenance' "$f" && echo "OK: lockfile maintenance section"
grep -q 'config:best-practices' "$f" && echo "OK: best-practices preset covered"
grep -q 'renovate-config-validator' "$f" && echo "OK: validation command present"
```

Expected: five `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/release-engineering/skills/renovate/references/cookbook.md
git commit -m "feat: add renovate cookbook reference"
```

---

### Task 7: `renovate/references/managers.md`

**Files:**
- Create: `plugins/release-engineering/skills/renovate/references/managers.md`

**Interfaces:**
- Consumes: `plugins/release-engineering/skills/renovate/SKILL.md` (Task 5) links here.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/release-engineering/skills/renovate/references/managers.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
# Renovate managers by ecosystem

Every OneLiteFeather repo's dependency stack falls into one (or more) of these. Renovate auto-detects
all of them from the standard preset — nothing extra to enable unless noted otherwise.

## Gradle (`gradle`, `gradle-wrapper`)

Scans `build.gradle`/`build.gradle.kts`, the inline version catalog in `settings.gradle.kts`, and
`gradle/wrapper/gradle-wrapper.properties` for the wrapper version itself. Version bumps land as
direct edits to whichever file declares the dependency — including an inline `versionCatalogs` block,
which is how OneLiteFeather projects declare dependencies (see the `gradle` skill in
`minestom-knowledge` for that convention).

For `net.minestom:minestom` and `io.papermc.paper:paper-api` specifically, plain SemVer parsing gets
the version ordering wrong (dates and `-mc-version` suffixes aren't SemVer) — that's exactly what the
`:minestom` and `:paper` preset flavors fix (see SKILL.md). Without the flavor, Renovate may still
open PRs for these, just with an unreliable idea of what counts as newer.

## Docker (`dockerfile`, `docker-compose`)

Scans `FROM` lines in Dockerfiles and image references in `docker-compose.yml`/`compose.yaml`. Bumps
the tag, and — when `config:best-practices` is in effect (see SKILL.md) — also pins to a digest
(`image:tag@sha256:...`) for reproducibility. Multi-stage Dockerfiles are scanned stage-by-stage; a
base image referenced in more than one `FROM` line is only bumped once per unique reference.

## GitHub Actions (`github-actions`)

Scans `uses:` lines in `.github/workflows/*.yml`, both for third-party actions
(`actions/checkout@v6`) and for OneLiteFeather's own reusable workflows
(`OneLiteFeatherNET/workflows/.github/workflows/gradle-build-pr.yml@v2.4.0`). Requires the pin to be
an actual tag (`@v2.4.0`) — a `@main` reference or an unpinned branch name isn't something Renovate
can "bump," since there's no version to compare against. This is the mechanical reason the
`workflows` skill's pin strategy insists on a full SemVer tag rather than a floating major alias like
`@v2`: Renovate can only keep a pin current if the pin is a concrete, comparable version in the first
place.

## npm/Node (`npm`)

Scans `package.json` and lockfiles (`package-lock.json`, or `yarn.lock`/`pnpm-lock.yaml` for those
package managers). Regular dependency bumps update `package.json`'s version range and the lockfile
together in one commit; `lockFileMaintenance` (see cookbook) handles lockfile-only drift separately.

## Ansible (`ansible`, `ansible-galaxy`)

`ansible` scans container image references inside Ansible task files (`image:` keys, same idea as the
Docker manager but embedded in YAML task definitions). `ansible-galaxy` scans
`requirements.yml`/`galaxy.yml` for role and collection version pins. Both are relevant for
infrastructure repos (Ansible roles, DNS/Kubernetes bootstrap playbooks) rather than Minestom/Gradle
projects.

## Python (`pip_requirements`, `pip-compile`, `poetry`, `pipenv`, `pep621`, `pep723`)

Which one applies depends on how the project declares dependencies: plain `requirements*.txt` files
use `pip_requirements` (or `pip-compile` if they're compiled from a `.in` source); `pyproject.toml`
using Poetry's own `[tool.poetry.dependencies]` table uses `poetry`; a `Pipfile` uses `pipenv`; a
`pyproject.toml` using the standard `[project.dependencies]` table (PEP 621) uses `pep621`; a
single-file script with inline metadata (PEP 723) uses `pep723`. More than one can be active in the
same repo if it genuinely mixes styles (uncommon, but not an error).

## Dart/pub (`pub`, `fvm`)

`pub` scans `pubspec.yaml` for package dependencies. `fvm` scans `.fvmrc`/`.fvm/fvm_config.json` for
the pinned Flutter SDK version when a project uses [FVM](https://fvm.app/) to manage it.

## When none of these apply

If a version lives somewhere none of the above managers scan — a custom config format, a version
baked into a shell script, an env var default in a Kubernetes manifest — that's exactly the case the
`customManagers` regex manager exists for (see `references/cookbook.md`). Reach for it only after
confirming no built-in manager already covers the file; check the
[full manager list](https://docs.renovatebot.com/modules/manager/) if the ecosystem here doesn't
obviously match what the repo actually uses.
```

- [ ] **Step 3: Verify content markers**

```bash
f=plugins/release-engineering/skills/renovate/references/managers.md
for kw in gradle-wrapper dockerfile github-actions ansible-galaxy pip_requirements poetry pep621 "pub" fvm customManagers; do
  grep -q "$kw" "$f" && echo "OK: $kw present" || echo "FAIL: $kw missing"
done
```

Expected: ten `OK:` lines, no `FAIL:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/release-engineering/skills/renovate/references/managers.md
git commit -m "feat: add renovate managers reference"
```

---

### Task 8: `workflows/SKILL.md`

**Files:**
- Create: `plugins/release-engineering/skills/workflows/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: links to `references/inputs-reference.md` (Task 9), `references/docker.md` (Task 10), and
  `references/design-principles.md` (Task 11) — exact relative paths must match.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/release-engineering/skills/workflows/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
---
name: workflows
description: OneLiteFeather's reusable GitHub Actions workflows (OneLiteFeatherNET/workflows) — build/test on PRs, publish to Maven, Docker publishing with or without a Gradle-generated context, and Gradle-specific defaults (Java version, path filters, test handling). Use this whenever adding or editing `.github/workflows/*.yml` in a OneLiteFeather repo, deciding how to wire up Docker publishing, hitting a Gradle-CI quirk (BOM-only project, path filter, cache behavior), or figuring out how to add a CI mechanic the existing catalog doesn't cover yet.
---

# Reusable GitHub Actions workflows

OneLiteFeather centralizes CI in [`OneLiteFeatherNET/workflows`](https://github.com/OneLiteFeatherNET/workflows) —
`workflow_call` workflows that consumer repos reference instead of maintaining their own copy. A
bugfix or a defaults change in that one repo, tagged, reaches every consumer with a version-pin bump
(via Renovate — see the `renovate` skill's "pipeline pins" section).

## Catalog

| Workflow | Purpose |
|---|---|
| `gradle-build-pr.yml` | Build & test a Gradle project on pull requests, across an OS matrix. |
| `gradle-publish.yml` | Build & publish a Gradle project to the OneLiteFeather Maven repository. |
| `gradle-docker-context.yml` | Run a Gradle command that produces a Docker build context, upload it as an artifact for a downstream `docker-publish.yml` job. |
| `docker-publish.yml` | Build a container image and push it to the OneLiteFeather Harbor registry (chunked upload, optional keyless signing). Toolchain-agnostic — takes a `context`/Dockerfile, doesn't know or care whether Gradle produced it. |
| `release-please.yml` | Run `googleapis/release-please-action@v5` for a repo (see the `release-please` skill). |
| `close-invalid-prs.yml` | Close PRs opened from a fork's default branch, with a configurable comment. |
| `markdown-lint.yml` | Lint Markdown with `markdownlint-cli2` and check links with `lychee`. |

Full input/default/secret tables for each: `references/inputs-reference.md`.

## Pin strategy

Consumers pin to a full SemVer tag — `@v2.4.0` — never `@main` and never a bare major alias like
`@v2`. The major alias is **deliberately not maintained**. Renovate's `github-actions` manager keeps
the pin current automatically (see the `renovate` skill); a `@main` reference defeats reproducible
builds, and an unpinned major alias defeats Renovate's ability to detect what "current" even means.

## Docker: with or without a Gradle-generated context

Two shapes, depending on where the Docker build context comes from:

**Plain `Dockerfile` checked into the repo** — call `docker-publish.yml` directly:

```yaml
jobs:
  docker:
    uses: OneLiteFeatherNET/workflows/.github/workflows/docker-publish.yml@v2.4.0
    with:
      image-name: "myteam/myapp"
      version: "1.2.3"
      context: "."
    secrets: inherit
```

**Gradle/Micronaut-generated context** (e.g. a Micronaut AOT `optimizedDockerfile` task) — run
`gradle-docker-context.yml` first to produce the context as an artifact, then have `docker-publish.yml`
consume it via a matching `artifact-name`:

```yaml
jobs:
  build-context:
    uses: OneLiteFeatherNET/workflows/.github/workflows/gradle-docker-context.yml@v2.4.0
    with:
      version: ${{ needs.release-please.outputs.version }}
      gradle-command: "./gradlew jar optimizedBuildLayers optimizedDockerfile -Pversion=$VERSION"
      context-path: "build/docker/optimized"
      artifact-name: "docker-context"
    secrets: inherit

  docker:
    needs: build-context
    permissions:
      contents: read
      id-token: write   # keyless cosign signing
    uses: OneLiteFeatherNET/workflows/.github/workflows/docker-publish.yml@v2.4.0
    with:
      image-name: "myteam/myapp"
      version: ${{ needs.release-please.outputs.version }}
      context: "build/docker/optimized"
      artifact-name: "docker-context"
    secrets: inherit
```

The `artifact-name` value must be identical in both jobs — it's how the second job finds what the
first one uploaded. Full detail, including snapshot builds and manual re-publishing, in
`references/docker.md`.

## Gradle specifics

- **Java 25 (Temurin)** is the default across every Gradle-touching workflow. Override with
  `java-version`/`java-distribution` only when a project genuinely needs something else.
- **3-OS matrix on PRs** (`ubuntu-latest`, `windows-latest`, `macos-latest`), **single-OS on
  publish** — PRs need to catch platform-specific bugs early; publish only needs one reproducible
  artifact.
- **Path-filter key is `code`** — `gradle-build-pr.yml`'s `paths-filters` input must define a
  top-level `code:` key; the build only runs when that filter matches. A markdown-only PR is skipped
  automatically under the default filter.
- **`run-tests: false`** for BOM-only or otherwise test-less projects — drops the default Gradle task
  from `build test` to `build` and skips the JUnit upload/aggregation steps entirely (no misleading
  "no tests found" PR comment).
- **No `clean`** in any default task — `clean` defeats Gradle's incremental compilation and the
  `setup-gradle` cache. Don't prepend it when overriding `gradle-task`/`build-task`.
- **Cache is read-only on non-default branches** — the build cache is only written on the repo's
  default branch; feature-branch/PR builds read from it but never populate it, which keeps many
  concurrent PRs from blowing past cache storage limits.

## Introducing a new mechanic?

If a repo needs something the catalog above doesn't cover — a new artifact type, a new deployment
target, a build step for an ecosystem none of these workflows know about — work through it in this
order:

1. **Can an existing workflow's input cover it?** Check `references/inputs-reference.md` first; a
   surprising number of "we need something different" cases are already an input away (a different
   `gradle-task`, a custom `paths-filters`, `run-tests: false`, a different `publish-task`).
2. **Is this reusable across more than one repo?** If yes, it belongs as a new `workflow_call`
   workflow in the `workflows` repo itself, not duplicated per consumer. `references/design-principles.md`
   has the conventions a new reusable workflow needs to follow (input/secret shape, concurrency
   groups, `secrets: inherit`, versioning) plus the "why" behind the existing defaults, so a new
   workflow reads as if it always belonged there.
3. **Is this genuinely one-off?** A step that only makes sense for a single repo's own quirks doesn't
   need to become a reusable workflow — a plain custom job in that repo's own `.github/workflows/`
   file is the right call. Forcing something repo-specific into the shared `workflows` repo just
   grows its input surface for a case nobody else will ever use.
```

- [ ] **Step 3: Verify frontmatter and content markers**

```bash
f=plugins/release-engineering/skills/workflows/SKILL.md
head -1 "$f" | grep -qx -- '---' && echo "OK: frontmatter fence"
grep -q '^name: workflows$' "$f" && echo "OK: name field"
grep -q 'gradle-docker-context.yml' "$f" && echo "OK: docker-with-gradle path covered"
grep -q 'context: "."' "$f" && echo "OK: docker-without-gradle path covered"
grep -q 'references/inputs-reference.md' "$f" && echo "OK: links inputs-reference"
grep -q 'references/docker.md' "$f" && echo "OK: links docker.md"
grep -q 'references/design-principles.md' "$f" && echo "OK: links design-principles.md"
grep -q '## Introducing a new mechanic' "$f" && echo "OK: new-mechanic section present"
```

Expected: eight `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/release-engineering/skills/workflows/SKILL.md
git commit -m "feat: add workflows skill"
```

---

### Task 9: `workflows/references/inputs-reference.md`

**Files:**
- Create: `plugins/release-engineering/skills/workflows/references/inputs-reference.md`

**Interfaces:**
- Consumes: `plugins/release-engineering/skills/workflows/SKILL.md` (Task 8) links here.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/release-engineering/skills/workflows/references/inputs-reference.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
# Workflow inputs & defaults reference

Complete `workflow_call` input/default/secret tables per workflow, mirrored from the actual schema in
`OneLiteFeatherNET/workflows/.github/workflows/*.yml`. Re-check the live workflow source if a pinned
version is older than what's described here — this reflects the shape as of `v2.4.0`.

## `gradle-build-pr.yml`

| Input | Type | Required | Default |
|---|---|---|---|
| `java-version` | string | no | `"25"` |
| `java-distribution` | string | no | `"temurin"` |
| `gradle-task` | string | no | `""` (resolves to `"build test"` if `run-tests`, else `"build"`) |
| `run-tests` | boolean | no | `true` |
| `runs-on` | string (JSON array) | no | `'["ubuntu-latest", "windows-latest", "macos-latest"]'` |
| `repository-owner` | string | no | `"OneLiteFeatherNET"` |
| `validate-wrapper` | boolean | no | `true` |
| `paths-filters` | string (YAML) | no | Gradle/JVM file patterns under a `code:` key |
| `force-build` | boolean | no | `false` |

Secrets (both optional, forwarded via `secrets: inherit`): `ONELITEFEATHER_MAVEN_USERNAME`,
`ONELITEFEATHER_MAVEN_PASSWORD`.

`repository-owner` skips the entire workflow (including the path-filter job) when
`github.repository_owner` doesn't match — set to `""` to disable the check on forks that should run
their own builds. `paths-filters` **must** define a top-level `code:` key; its resolved boolean
drives whether the build matrix runs at all, unless `force-build: true` bypasses it.

## `gradle-publish.yml`

| Input | Type | Required | Default |
|---|---|---|---|
| `java-version` | string | no | `"25"` |
| `java-distribution` | string | no | `"temurin"` |
| `runs-on` | string | no | `"ubuntu-latest"` |
| `build-task` | string | no | `"build"` |
| `publish-task` | string | no | `"publish"` |
| `validate-wrapper` | boolean | no | `true` |

Secrets (both **required**): `ONELITEFEATHER_MAVEN_USERNAME`, `ONELITEFEATHER_MAVEN_PASSWORD`.

`runs-on` is a single string, not an array — publish is intentionally single-OS (see SKILL.md). For
a targeted publish instead of every configured publication, set `publish-task` to the exact Gradle
task name, e.g. `"publishMavenJavaPublicationToOneLiteFeatherRepository"`.

## `gradle-docker-context.yml`

| Input | Type | Required | Default |
|---|---|---|---|
| `gradle-command` | string | **yes** | — |
| `version` | string | **yes** | — |
| `context-path` | string | **yes** | — |
| `artifact-name` | string | no | `"docker-context"` |
| `java-version` | string | no | `"25"` |
| `java-distribution` | string | no | `"temurin"` |
| `validate-wrapper` | boolean | no | `true` |
| `retention-days` | number | no | `1` |
| `runs-on` | string | no | `"ubuntu-latest"` |

Secrets (both optional — only needed if the Gradle build resolves private artifacts):
`ONELITEFEATHER_MAVEN_USERNAME`, `ONELITEFEATHER_MAVEN_PASSWORD`.

Output: `artifact-name` (echoes the input, so a downstream job can reference it without repeating the
literal string). `$VERSION` is exported into the environment before `gradle-command` runs, from the
`version` input — reference it in the command as `$VERSION` (e.g.
`./gradlew jar optimizedDockerfile -Pversion=$VERSION`).

## `docker-publish.yml`

| Input | Type | Required | Default |
|---|---|---|---|
| `image-name` | string | **yes** | — |
| `version` | string | **yes** | — |
| `context` | string | no | `"."` |
| `dockerfile` | string | no | `""` (resolves to `<context>/Dockerfile`) |
| `artifact-name` | string | no | `""` (build straight from the checkout when empty) |
| `extra-tags` | string | no | `""` |
| `blob-chunk` | string | no | `"52428800"` (50 MiB) |
| `req-concurrent` | string | no | `"3"` |
| `sign` | boolean | no | `true` |
| `regctl-version` | string | no | `"v0.11.5"` |
| `runs-on` | string | no | `"ubuntu-latest"` |

Secrets (all **required**): `HARBOR_REGISTRY`, `HARBOR_USERNAME`, `HARBOR_PASSWORD`.

Outputs: `image` (fully-qualified `registry/image-name`), `digest` (pushed manifest digest).
`sign: true` requires the calling job to grant `permissions: id-token: write` — omit both if signing
isn't needed. Full rationale for `blob-chunk`/`req-concurrent` in `references/docker.md`.

## `release-please.yml`

| Input | Type | Required | Default |
|---|---|---|---|
| `config-file` | string | no | `"release-please-config.json"` |
| `manifest-file` | string | no | `".release-please-manifest.json"` |
| `target-branch` | string | no | *(caller's branch)* |
| `runs-on` | string | no | `"ubuntu-latest"` |

No secrets input — it uses the default `GITHUB_TOKEN`. The caller workflow must itself declare:

```yaml
permissions:
  contents: write
  pull-requests: write
```

`target-branch` is almost never set explicitly — leave it empty so Release Please operates on
whatever branch triggered the caller workflow.

## `close-invalid-prs.yml`

| Input | Type | Required | Default |
|---|---|---|---|
| `protected-branch` | string | no | `"main"` |
| `comment` | string | no | `"Please do not open pull requests from the default branch, create a feature branch instead."` |

Trigger in the caller is typically `pull_request_target: types: [opened]`. Set `protected-branch` to
`"master"` for older repos still on that default branch name.

## `markdown-lint.yml`

| Input | Type | Required | Default |
|---|---|---|---|
| `glob` | string | no | `"**/*.md"` |
| `config-file` | string | no | `".markdownlint.json"` |
| `check-links` | boolean | no | `true` |
| `lychee-args` | string | no | `"--max-redirects 5 --accept 200..=204,429 --no-progress"` |
| `runs-on` | string | no | `"ubuntu-latest"` |
| `paths-filters` | string (YAML) | no | Defaults covering `**/*.md`, the lint config, `.lycheeignore` |
| `force-lint` | boolean | no | `false` |
| `repository-owner` | string | no | `"OneLiteFeatherNET"` |

`check-links: false` skips the `lychee` job entirely — useful for repos with many internal/private
links `lychee` can't reach; alternatively list them in `.lycheeignore` (one regex per line) and leave
link-checking on for everything else.
```

- [ ] **Step 3: Verify all seven workflows are documented**

```bash
f=plugins/release-engineering/skills/workflows/references/inputs-reference.md
for wf in gradle-build-pr.yml gradle-publish.yml gradle-docker-context.yml docker-publish.yml release-please.yml close-invalid-prs.yml markdown-lint.yml; do
  grep -q "## \`$wf\`" "$f" && echo "OK: $wf documented" || echo "FAIL: $wf missing"
done
```

Expected: seven `OK:` lines, no `FAIL:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/release-engineering/skills/workflows/references/inputs-reference.md
git commit -m "feat: add workflows inputs reference"
```

---

### Task 10: `workflows/references/docker.md`

**Files:**
- Create: `plugins/release-engineering/skills/workflows/references/docker.md`

**Interfaces:**
- Consumes: `plugins/release-engineering/skills/workflows/SKILL.md` (Task 8) links here.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/release-engineering/skills/workflows/references/docker.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
# Docker publishing in detail

SKILL.md covers the two-shape decision (plain Dockerfile vs. Gradle-generated context) at a glance.
This is the full pattern, including release vs. snapshot builds and manual re-publishing.

## Plain Dockerfile, no Gradle coupling

`docker-publish.yml` is deliberately toolchain-agnostic — it only turns a `context`/`Dockerfile` into
a pushed image, nothing language-specific. Any project (Node, Go, Flutter, a hand-written multi-stage
Dockerfile) can call it directly:

```yaml
jobs:
  docker:
    uses: OneLiteFeatherNET/workflows/.github/workflows/docker-publish.yml@v2.4.0
    with:
      image-name: "myteam/myapp"
      version: "1.2.3"
      context: "."
      sign: false          # skip signing → no id-token permission needed
    secrets: inherit
```

`sign: false` is worth calling out: signing is the default, and it needs
`permissions: id-token: write` on the calling job. Projects that don't need signed images can drop
both the permission and the input together.

## Gradle/Micronaut-generated context (the Otis pattern)

When the Docker context itself is a Gradle build output (e.g. Micronaut AOT's
`optimizedBuildLayers`/`optimizedDockerfile` tasks), `gradle-docker-context.yml` runs the Gradle
command and hands the result to `docker-publish.yml` as an artifact — this keeps `docker-publish.yml`
itself free of any JDK/Gradle setup:

```yaml
jobs:
  release-please:
    # ... as in the release-please skill ...
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
      version: ${{ steps.release.outputs.version }}

  build-context:
    needs: release-please
    if: needs.release-please.outputs.release_created == 'true'
    uses: OneLiteFeatherNET/workflows/.github/workflows/gradle-docker-context.yml@v2.4.0
    with:
      version: ${{ needs.release-please.outputs.version }}
      gradle-command: "./gradlew jar optimizedBuildLayers optimizedDockerfile -Pversion=$VERSION"
      context-path: "build/docker/optimized"
      artifact-name: "docker-context-release"
    secrets: inherit

  docker:
    needs: [release-please, build-context]
    permissions:
      contents: read
      id-token: write
    if: needs.release-please.outputs.release_created == 'true'
    uses: OneLiteFeatherNET/workflows/.github/workflows/docker-publish.yml@v2.4.0
    with:
      image-name: "myteam/myapp"
      version: ${{ needs.release-please.outputs.version }}
      context: "build/docker/optimized"
      artifact-name: "docker-context-release"
    secrets: inherit
```

`artifact-name` (`"docker-context-release"` here) must be identical between the two jobs — it's the
only link between them; `docker-publish.yml` downloads whatever `gradle-docker-context.yml` uploaded
under that exact name.

## Snapshot builds alongside release builds

A repo can publish a Docker image on *every* non-release push to the default branch too (a rolling
"latest development build" image), by resolving the current version from the build file when
Release Please didn't create a release, and running a second, parallel pair of
`gradle-docker-context.yml`/`docker-publish.yml` jobs gated on that instead:

```yaml
  version:
    needs: release-please
    if: needs.release-please.outputs.release_created != 'true'
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.read.outputs.version }}
      is_snapshot: ${{ steps.read.outputs.is_snapshot }}
    steps:
      - uses: actions/checkout@v6
      - id: read
        shell: bash
        run: |
          VERSION="$(grep -m1 'x-release-please-version' build.gradle.kts | sed -E 's/.*version = "([^"]+)".*/\1/')"
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"
          case "$VERSION" in
            *SNAPSHOT*) echo "is_snapshot=true" >> "$GITHUB_OUTPUT" ;;
            *)          echo "is_snapshot=false" >> "$GITHUB_OUTPUT" ;;
          esac

  build-context-snapshot:
    needs: [release-please, version]
    if: needs.version.outputs.is_snapshot == 'true'
    uses: OneLiteFeatherNET/workflows/.github/workflows/gradle-docker-context.yml@v2.4.0
    with:
      version: ${{ needs.version.outputs.version }}
      gradle-command: "./gradlew jar optimizedBuildLayers optimizedDockerfile -Pversion=$VERSION"
      context-path: "build/docker/optimized"
      artifact-name: "docker-context-snapshot"
    secrets: inherit

  docker-snapshot:
    needs: [version, build-context-snapshot]
    permissions:
      contents: read
      id-token: write
    if: needs.version.outputs.is_snapshot == 'true'
    uses: OneLiteFeatherNET/workflows/.github/workflows/docker-publish.yml@v2.4.0
    with:
      image-name: "myteam/myapp"
      version: ${{ needs.version.outputs.version }}
      context: "build/docker/optimized"
      artifact-name: "docker-context-snapshot"
    secrets: inherit
```

This one-liner reads the version straight from the `build.gradle.kts` marker (see the
`release-please` skill) with a targeted `sed`, purely to know *what to tag the snapshot image with* —
this is a read-only, single-purpose lookup at workflow time, not the "parse `gradle.properties` on
every publish" anti-pattern the `release-please` skill warns against, which was about avoiding a
*second* source of truth for the version. `docker-context-release` and `docker-context-snapshot` use
different `artifact-name`s so the two job pairs never collide within the same workflow run.

## Manual re-publish via `workflow_dispatch`

To rebuild and re-push a specific version's image on demand (e.g. after a registry incident), add a
`workflow_dispatch` trigger with a version input, and let both the release and snapshot job pairs
also fire on manual dispatch:

```yaml
on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      docker_version:
        description: "Version to (re)build & push the Docker image for, e.g. 1.13.2. Runs only the docker job."
        required: true
        type: string
```

Then reference `inputs.docker_version` in the `docker`/`docker-snapshot` jobs' `version` input in
place of the computed value whenever `github.event_name == 'workflow_dispatch'`, gating the
`release-please`/`version` jobs themselves to `github.event_name == 'push'` so a manual dispatch
doesn't also try to run a release.

## Why chunked uploads and keyless signing

**Chunked uploads (`regctl`, not plain `docker push`):** the OneLiteFeather Harbor registry sits
behind a proxy with a 100 MB request-body limit. A single large image layer pushed as one request
fails with `413 Request Entity Too Large` or a `504 Gateway Timeout`. `docker-publish.yml` builds the
image to an OCI archive locally, then pushes it with [`regctl`](https://regclient.org/)
(`--blob-chunk`/`--blob-max`), which splits any blob above `blob-chunk` (default 50 MiB, comfortably
under the 100 MB proxy cap) into multiple smaller `PATCH` requests instead of one monolithic `PUT`.
Raise `blob-chunk` for a registry proxy with a higher limit, or lower `req-concurrent` if the
registry's storage backend starts returning `5xx` under concurrent load.

**Keyless signing (Cosign + GitHub OIDC):** `sign: true` (the default) signs the pushed image using
the calling job's GitHub Actions OIDC identity — no signing key or password to generate, store, or
rotate. The only requirement is `permissions: id-token: write` on the calling job. Verification uses
the workflow's identity, not a static public key
(`--certificate-identity-regexp` + `--certificate-oidc-issuer https://token.actions.githubusercontent.com`
when checking a signature with `cosign verify`).
```

- [ ] **Step 3: Verify content markers**

```bash
f=plugins/release-engineering/skills/workflows/references/docker.md
grep -q 'is_snapshot' "$f" && echo "OK: snapshot pattern present"
grep -q 'workflow_dispatch' "$f" && grep -q 'docker_version' "$f" && echo "OK: manual re-publish covered"
grep -q 'blob-chunk' "$f" && grep -q '413' "$f" && echo "OK: chunked-upload rationale present"
grep -q 'id-token: write' "$f" && grep -q 'Cosign' "$f" && echo "OK: keyless signing covered"
```

Expected: four `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/release-engineering/skills/workflows/references/docker.md
git commit -m "feat: add workflows docker reference"
```

---

### Task 11: `workflows/references/design-principles.md`

**Files:**
- Create: `plugins/release-engineering/skills/workflows/references/design-principles.md`

**Interfaces:**
- Consumes: `plugins/release-engineering/skills/workflows/SKILL.md` (Task 8) links here, from the
  "Introducing a new mechanic?" section.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/release-engineering/skills/workflows/references/design-principles.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
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

## Why Renovate instead of Dependabot for the pipeline pins

Dependabot bumps individual GitHub Actions references but can't group reusable-workflow-ref updates
into one PR or auto-merge them the same way Renovate can. See the `renovate` skill for the mechanics.

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
   release; consumers get it via their existing Renovate-managed pin bump, no separate announcement
   needed for the mechanism to reach them (though a heads-up for anything behavior-changing is still
   good practice).
```

- [ ] **Step 3: Verify content markers**

```bash
f=plugins/release-engineering/skills/workflows/references/design-principles.md
for section in "matrix on PRs" "no \`clean\`" "cancel-in-progress" "cache is read-only" "How to add a new reusable workflow"; do
  grep -qi "$section" "$f" && echo "OK: '$section' covered" || echo "FAIL: '$section' missing"
done
```

Expected: five `OK:` lines, no `FAIL:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/release-engineering/skills/workflows/references/design-principles.md
git commit -m "feat: add workflows design-principles reference"
```

---

### Task 12: Final plugin-wide verification

**Files:** none created or modified — this task only runs checks across everything Tasks 1–11 produced.

**Interfaces:**
- Consumes: every file from Tasks 1–11.
- Produces: nothing — this is the plan's closing gate.

- [ ] **Step 1: Verify the full directory structure matches the spec**

```bash
find plugins/release-engineering -type f | sort
```

Expected output (12 lines, exact set):

```
plugins/release-engineering/.antigravity-plugin/plugin.json
plugins/release-engineering/.claude-plugin/plugin.json
plugins/release-engineering/.codex-plugin/plugin.json
plugins/release-engineering/skills/release-please/SKILL.md
plugins/release-engineering/skills/release-please/references/multi-module.md
plugins/release-engineering/skills/renovate/SKILL.md
plugins/release-engineering/skills/renovate/references/cookbook.md
plugins/release-engineering/skills/renovate/references/managers.md
plugins/release-engineering/skills/workflows/SKILL.md
plugins/release-engineering/skills/workflows/references/docker.md
plugins/release-engineering/skills/workflows/references/design-principles.md
plugins/release-engineering/skills/workflows/references/inputs-reference.md
```

- [ ] **Step 2: Every SKILL.md has exactly `name` + `description` frontmatter, no more, no less**

```bash
for f in plugins/release-engineering/skills/*/SKILL.md; do
  fields=$(sed -n '2,/^---$/p' "$f" | sed '$d' | grep -c '^[a-z]*:')
  echo "$f: $fields top-level frontmatter field(s)"
done
```

Expected: `2 top-level frontmatter field(s)` for all three files (`name` and `description`).

- [ ] **Step 3: No placeholder markers anywhere in the new content**

```bash
grep -rniE 'TBD|TODO|FIXME|fill in|placeholder for' plugins/release-engineering/ && echo "FAIL: placeholder found" || echo "OK: no placeholders"
```

Expected: `OK: no placeholders`. (This checks for literal leftover-placeholder markers — the
intentional example placeholder names like `my-library`/`module-a`/`<team>-maintainers` used
throughout the content are not matched by this pattern and are expected to remain.)

- [ ] **Step 4: All three plugin manifests and `marketplace.json` are valid JSON**

```bash
for f in plugins/release-engineering/.claude-plugin/plugin.json \
         plugins/release-engineering/.codex-plugin/plugin.json \
         plugins/release-engineering/.antigravity-plugin/plugin.json \
         .claude-plugin/marketplace.json; do
  jq empty "$f" && echo "OK: $f valid" || echo "FAIL: $f invalid"
done
```

Expected: four `OK: ... valid` lines.

- [ ] **Step 5: Every cross-reference link inside the new skills resolves to a real file**

```bash
test -f plugins/release-engineering/skills/release-please/references/multi-module.md && echo "OK: release-please -> multi-module.md"
test -f plugins/release-engineering/skills/renovate/references/cookbook.md && echo "OK: renovate -> cookbook.md"
test -f plugins/release-engineering/skills/renovate/references/managers.md && echo "OK: renovate -> managers.md"
test -f plugins/release-engineering/skills/workflows/references/inputs-reference.md && echo "OK: workflows -> inputs-reference.md"
test -f plugins/release-engineering/skills/workflows/references/docker.md && echo "OK: workflows -> docker.md"
test -f plugins/release-engineering/skills/workflows/references/design-principles.md && echo "OK: workflows -> design-principles.md"
```

Expected: six `OK:` lines, one per cross-reference.

- [ ] **Step 6: `git status` is clean — every file from Tasks 1–11 was committed**

```bash
git status --short plugins/release-engineering/ .claude-plugin/marketplace.json README.md
```

Expected: empty output.

- [ ] **Step 7: Final commit if Step 6 showed anything uncommitted**

Only run this if Step 6's output was non-empty:

```bash
git add plugins/release-engineering/ .claude-plugin/marketplace.json README.md
git commit -m "chore: finalize release-engineering plugin"
```

