# Plugin `release-engineering` — Design

## Purpose

A new Claude Code plugin that teaches OneLiteFeather's CI/CD standard: Release Please, Renovate, and
the reusable GitHub Actions workflows (including Docker publishing and Gradle specifics). Like
`minestom-knowledge`, it is pure skill knowledge — no MCP servers, no external dependencies.

Sources: the Outline docs ("Engineering Standards — Start Here" plus the Diátaxis set "Reusable GitHub
Actions Workflows"), the actual code in `workflows` and `renovate` (OneLiteFeatherNET), gold-master
repos (**Cygnus** without Docker, **Otis** with Docker, **Guira** as a fresh migration pilot PR #70),
and current upstream Renovate documentation (docs.renovatebot.com, cross-checked against terminology
changes such as `regexManagers` → `customManagers`, `fileMatch` → `managerFilePatterns`).

## Scope decisions (made during brainstorming)

- Only the four requested topic areas: Release Please, Renovate, reusable workflows (with/without
  Docker), Gradle specifics. No community-health-files template (README/CONTRIBUTING/CODEOWNERS) —
  deliberately out of scope.
- No org-wide migration tracking lists (`RELEASE-PLEASE-TRACKING.md` etc.) in the skill — that's
  transient state from an ongoing migration, not reusable skill knowledge.
- Three standalone skills instead of one, so a pure Renovate question, for example, doesn't pull in
  all the Release Please knowledge (each `SKILL.md` has its own `description` frontmatter for trigger
  matching).
- **Release Please:** the version-marker standard is exclusively a comment directly in the root
  `build.gradle.kts` (`version = "1.2.3" // x-release-please-version`), read via release-please's
  built-in `generic` extra-files updater. Explicitly **no** shell-script parsing of
  `gradle.properties` (as is currently found in some publish workflows, e.g.
  `grep '^version' gradle.properties | cut -d= -f2`) and **no** homegrown Kotlin `replace` task /
  `Copy` + `ReplaceTokens` for version synchronization. The skill covers both Setup (new repo) and
  Migration (existing repo moving away from `@semantic-release`/`release-drafter`/tag-triggered
  publish) as complete, separate sections, each for single-module and multi-module Gradle projects
  (multi-module: an independent version per subproject via multiple `packages` entries in
  `release-please-config.json`).
- **Renovate:** not just "adopt the central preset," but general help with Renovate configs — a
  broad, generic reference of Renovate config options (not limited to patterns currently used at
  OLF), plus manager-specific sections for **all** ecosystems that actually occur in the org
  (Gradle, Docker, GitHub Actions, npm/Node, Ansible, Python, Dart/pub) — not just the
  Gradle/Docker/Actions core stack.

## Structure

```
plugins/release-engineering/
├── .claude-plugin/plugin.json
├── .codex-plugin/plugin.json
├── .antigravity-plugin/plugin.json
└── skills/
    ├── release-please/
    │   ├── SKILL.md
    │   └── references/
    │       └── multi-module.md
    ├── renovate/
    │   ├── SKILL.md
    │   └── references/
    │       ├── cookbook.md
    │       └── managers.md
    └── workflows/
        ├── SKILL.md
        └── references/
            ├── inputs-reference.md
            ├── docker.md
            └── design-principles.md
```

Additionally: an entry for `release-engineering` in `.claude-plugin/marketplace.json` (format
analogous to the three existing plugin entries) and a row in the plugin table in the root `README.md`.

## Skill: `release-please`

**SKILL.md** (main content, generic with placeholders instead of real repo names):

- Short overview: Conventional Commits → automatic changelog → tag → release → chained publish.
  Replaces `@semantic-release` and manual tagging.
- **Version-marker convention** as its own, prominent section: `build.gradle.kts` instead of
  `gradle.properties`, with rationale (no parse/replace code needed, Gradle reads `project.version`
  natively). Anti-pattern callout: no `grep`/`cut` parsing, no Kotlin `replace` task.
- `## Setup` — new, empty repo: `release-please-config.json` (`release-type: simple`,
  `extra-files: [{"type": "generic", "path": "build.gradle.kts"}]`), `.release-please-manifest.json`,
  `.github/workflows/release-please.yml` (`googleapis/release-please-action@v5`, chained with
  `gradle-publish.yml` via `needs.release-please.outputs.release_created`).
- `## Migration` — existing repo: recognizing legacy tooling (`.releaserc*`, `release-drafter.yml`,
  tag-triggered `publish.yaml`), removing it including any parse/replace scripts, determining
  `bootstrap-sha` from history, moving the version marker from `gradle.properties` (if present) to
  `build.gradle.kts`, setting the manifest to the current version.
- Both sections explicitly cover single-module; multi-module is briefly introduced and linked to the
  reference.

**references/multi-module.md**: a generic multi-module Gradle example (placeholder module names) —
multiple entries in the `packages` object (one path per subproject), each with its own version marker
in that subproject's `build.gradle.kts`, each with its own entry in `.release-please-manifest.json`.
Explains that a commit touching only files under one module's path bumps only that module's version.

## Skill: `renovate`

**SKILL.md**:

- What Renovate does for OLF, brief contrast with Dependabot (from the Explanation doc: better
  grouping/automerge for reusable-workflow refs).
- Org-standard setup: central preset
  `github>OneLiteFeatherNET/renovate:default(OneLiteFeatherNET/<team>-maintainers)`, the team
  argument is mandatory (sets the reviewer), flavors `:paper` / `:minestom` as a second `extends`
  entry.
- What the default preset brings (patch automerge, Europe/Berlin office-hours schedule, semantic
  commits, `renovate` label, vulnerability alerts).
- Migration away from non-canonical legacy configs (lowercase preset without `:default`,
  `config:base` directly, `config:recommended` directly without the org preset).
- Separate section: Renovate for the pipeline pins themselves (the `github-actions` manager bumps
  `OneLiteFeatherNET/workflows/...@vX.Y.Z` automatically).
- Pointer to the two references for anything beyond the org standard.

**references/cookbook.md** (broad generic reference, not limited to current OLF usage):

- Scheduling (`schedule`, `automergeSchedule`, `prHourlyLimit`/`prConcurrentLimit`).
- `packageRules` matching (`matchManagers`, `matchPackageNames`, `matchUpdateTypes`,
  `matchDatasources`), `ignoreDeps`/`ignorePaths`.
- Grouping (`groupName`, `groupSlug`, `minimumGroupSize`).
- Automerge (`automerge`, `automergeType`, `platformAutomerge`) including differentiating by update
  type (automerge minor/patch/digest, never major).
- `customManagers` (current name, formerly `regexManagers`) with `customType: "regex"`,
  `managerFilePatterns` (formerly `fileMatch`), `matchStrings` — for files no native manager covers.
- `lockFileMaintenance`, dependency dashboard, `vulnerabilityAlerts`/`osvVulnerabilityAlerts`.
- `config:recommended` vs. `config:best-practices` (what the latter adds on top: digest pinning,
  abandonment handling, weekly lockfile maintenance) as a deliberate extension option.
- Callout box "outdated syntax from blog posts/older examples": `regexManagers` → `customManagers`,
  `fileMatch` → `managerFilePatterns`, `baseBranches` → `baseBranchPatterns`.
- Config validation: `npx --package renovate -- renovate-config-validator`.

**references/managers.md** (per ecosystem, all stacks that occur in the org):

- Gradle (`gradle`, `gradle-wrapper`) — what's auto-detected, interplay with the `:paper`/`:minestom`
  versioning flavors from the `renovate` repo.
- Docker (`dockerfile`, `docker-compose`).
- GitHub Actions (`github-actions`) — pin format `uses: .../foo.yml@vX.Y.Z`, interplay with the pin
  strategy from the `workflows` skill.
- npm/Node (`npm`).
- Ansible (`ansible`, `ansible-galaxy`) — relevant for `infra-ansible-roles`, `infra-dns`,
  `Kubernetes-FLUX`.
- Python (`pip_requirements`, `poetry`, `pep621`, ...) — relevant for `Dungeon-Python`, `ProtoScript`.
- Dart/pub (`pub`, `fvm`) — relevant for `stelaris`, `vulpes-*-dart`.
- When to fall back to `customManagers`/regex (a file/format no native manager knows).

## Skill: `workflows`

**SKILL.md**:

- Catalog of all reusable workflows (`gradle-build-pr`, `gradle-publish`, `gradle-docker-context`,
  `docker-publish`, `release-please`, `close-invalid-prs`, `markdown-lint`) with a one-line purpose
  per workflow.
- Pin strategy: full SemVer tag (`@v2.4.0`), deliberately no `@v2` major alias — Renovate keeps the
  pin current (pointer to the `renovate` skill, "Pipeline Pins" section).
- Docker decision as its own section: plain `Dockerfile` in the repo → `docker-publish.yml` directly
  with `context`/`dockerfile`; Gradle/Micronaut-generated context (`optimizedDockerfile`) →
  `gradle-docker-context.yml` first (produces an artifact), then `docker-publish.yml` consumes it via
  the same `artifact-name`. Short version here, details in `references/docker.md`.
- Gradle specifics: Java 25 (Temurin) as the default, 3-OS matrix on PRs vs. single-OS on publish,
  path-filter key `code`, `run-tests: false` for BOM/test-less projects (drops the default task to
  `build`), no `clean` in the default task (cache killer), cache is read-only on non-default
  branches.
- **New section "Introducing a new mechanic?":** a short decision tree for cases the existing catalog
  doesn't directly cover — extend an existing workflow via an additional input vs. add a new reusable
  workflow to the `workflows` repo vs. leave a custom job in the caller repo (e.g. one-off,
  repo-specific logic that doesn't generalize). Points to `references/design-principles.md` for the
  detailed guidance and the "why."

**references/inputs-reference.md**: complete input/default/secret tables per workflow (mirrored from
the actual `workflow_call` schema in the `workflows` repo, not just taken from the Outline docs — both
were cross-checked).

**references/docker.md**: the Otis pattern in detail (`gradle-docker-context.yml` →
`docker-publish.yml` handoff, snapshot vs. release build as two parallel job pairs,
`workflow_dispatch` with a `docker_version` input for manual re-publishing), the plain-Dockerfile
pattern without Gradle coupling, the chunked-upload rationale (Harbor behind Cloudflare, 100 MB proxy
limit, `regctl --blob-chunk`), and keyless Cosign signing (`id-token: write`, no signing secret).

**references/design-principles.md** (new): the "why" behind the existing defaults, taken from the
Outline page "Explanation: Design Decisions" and verified against the actual workflow code — matrix
on PRs vs. single-OS on publish, `cancel-in-progress: true` on PRs vs. `false` on publish, the reason
for the path filter, no `clean` in the default task, cache read-only on non-default branches, the
Java 25 choice, why release-please instead of `@semantic-release`, why Renovate instead of Dependabot
for the pipeline pins. These principles are framed as a transferable set of rules so a new mechanic
(new ecosystem type, new deployment target, new artifact type) can be designed consistently with
them — plus concrete guidance on how to submit a new reusable workflow to the `workflows` repo
(`workflow_call` schema conventions, `secrets: inherit`, conventional-commit PR, the `workflows`
repo's own versioning via release-please, full SemVer pin for consumers instead of `@main`/a major
alias).

## Out of scope

- Community-health-files template (README/CONTRIBUTING/CODEOWNERS) — a separate, later topic.
- Org-wide migration tracking lists — transient state, doesn't belong in a skill.
- SBOM integration (`cyclonedxBom` + DependencyTrack upload, as seen in Cygnus) — a separate topic,
  not part of this request.
