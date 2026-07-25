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
