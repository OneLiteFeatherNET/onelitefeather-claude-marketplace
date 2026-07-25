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
the preset already did. Keep only `packageRules` that encode something genuinely repo-specific — see
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
