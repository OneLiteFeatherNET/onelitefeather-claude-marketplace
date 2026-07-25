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
