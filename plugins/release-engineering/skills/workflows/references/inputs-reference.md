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
