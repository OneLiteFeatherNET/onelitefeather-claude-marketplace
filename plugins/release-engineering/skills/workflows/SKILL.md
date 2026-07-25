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
