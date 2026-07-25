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
