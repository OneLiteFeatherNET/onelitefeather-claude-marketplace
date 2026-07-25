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
