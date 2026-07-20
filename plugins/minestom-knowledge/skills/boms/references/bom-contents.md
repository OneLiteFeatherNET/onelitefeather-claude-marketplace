# Full contents of each BOM

SKILL.md covers the hierarchy and when to use which BOM. This file lists exactly what each one pins as of the
version researched — re-check the live `build.gradle.kts` of the relevant BOM repo before assuming this list is
still current, since BOMs are actively maintained by Renovate (versions) and manual PRs (entries).

## `mycelium-bom` (base tier)

Imports `platform(libs.junit.bom)` itself, then pins via `constraints { api(...) }`:

- `net.minestom:minestom`
- `net.kyori:adventure-text-minimessage`
- `net.onelitefeather:cyano`
- `org.mockito:mockito-core`
- `org.mockito:mockito-junit-jupiter`

## `aonyx-bom` (minigame tier — builds on `mycelium-bom`)

Imports `platform(libs.mycelium.bom)`, adds:

- `net.onelitefeather:guira`
- `net.theevilreaper:aves`
- `net.theevilreaper:xerus`

## `manis-bom` (ManisGame-specific tier — builds on `aonyx-bom`)

Imports `platform(libs.aonyx.bom)`, `platform(libs.hibernate.bom)` (Hibernate ORM's own platform), and
`platform(libs.cloudnet.bom)` (CloudNet's own platform), adds:

- `org.postgresql:postgresql`
- `com.h2database:h2`
- `com.google.auto.service:auto-service`
- `com.rabbitmq:amqp-client`
- `commons-io:commons-io`
- `org.zeroturnaround:zt-zip`
- `com.github.ben-manes.caffeine:caffeine`
- `net.worldseed.multipart:WorldSeedEntityEngine`
- Bundle `geometry.full` — all four `org.apache.commons:commons-geometry-*` artifacts (core, euclidean, spherical,
  parent)
- Bundle `geometry.game` — the smaller `core`+`euclidean` subset (what the actual game module uses; `geometry.full`
  is broader than most consumers need)
- Bundle `jaxb` — `org.glassfish.jaxb:jaxb-runtime` + `com.sun.xml.bind:jaxb-impl`

`manis-bom` is a `java-platform` project like the other two, published the same way (see the `gradle` skill), plus
a CycloneDX plugin (`alias(libs.plugins.cyclonedx)`) that generates an actual SBOM artifact on build — `aonyx-bom`
does not have this plugin, only `mycelium-bom` and `manis-bom` do.

## Not covered by any of the three

Dependencies specific to one project only — e.g. `ManisGame` also declares `shadow` (the Gradle plugin, not a
library), `commons-geometry-parent`, `world.seed.engine` exclusion tweaks — live in that project's own version
catalog, not in any shared BOM. That's expected: see SKILL.md's "When not to touch a BOM" section.
