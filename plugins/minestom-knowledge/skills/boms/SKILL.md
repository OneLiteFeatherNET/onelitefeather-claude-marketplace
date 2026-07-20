---
name: boms
description: OneLiteFeather's tiered Bill-of-Materials (BOM) hierarchy for dependency version management — mycelium-bom, aonyx-bom, and manis-bom, which one a project should import as its dependency platform, and how to add a new managed dependency to one. Use this whenever a Minestom/OneLiteFeather project needs a new dependency added, when choosing which BOM to import in a new project's build.gradle.kts, or when a dependency version needs bumping across the org rather than in one project. Complements the `gradle` skill, which covers how a BOM plugs into a build file in general — this one covers which BOM to use and what's actually inside each.
---

# BOMs: dependency version management

OneLiteFeather manages dependency versions centrally through three Bills of Materials, each a Gradle
`java-platform` project published to `repo.onelitefeather.dev`. They form a strict tier, each building on the one
below it via `api(platform(...))`:

```
mycelium-bom   (base: general Minestom dev dependencies)
    ↑
aonyx-bom      (+ Aves, Xerus, Guira — for minigames)
    ↑
manis-bom      (+ Hibernate, CloudNet, DB drivers, geometry — ManisGame-specific)
```

Each tier only *adds* to the one below — it never removes or overrides what the lower tier pins. This is why picking
the right BOM as your project's platform import matters: importing a higher tier gives you everything below it too,
not just its own additions.

## Which BOM to import

Pick the **lowest** tier that already covers what the project needs — don't reach for `manis-bom` just because it has
everything, since that also pulls in ManisGame-specific dependencies (Hibernate, CloudNet, PostgreSQL, geometry
libraries) that a project unrelated to ManisGame has no use for.

- **`mycelium-bom`** — any Minestom project that just needs the basics: Minestom itself, Adventure
  (`adventure-text-minimessage`), Cyano for testing, Mockito. This is what libraries like Aves, Xerus, and Guira
  themselves import. Start here by default.
- **`aonyx-bom`** — a minigame project that uses (or will use) Aves, Xerus, and/or Guira. Importing this instead of
  `mycelium-bom` directly gets you Minestom/Adventure/Cyano too, since `aonyx-bom` builds on `mycelium-bom`.
- **`manis-bom`** — specific to the ManisGame project itself. Don't import this from a new, unrelated project even if
  it happens to need one of the extra dependencies `manis-bom` pins (Hibernate, CloudNet, etc.) — add that dependency
  to `aonyx-bom` or the new project's own BOM instead if it's going to be reused, or just declare it directly with an
  explicit version if it's a one-off.

In a `build.gradle.kts`, the chosen BOM is imported once as a platform, and everything it covers is then declared
without a version (see the `gradle` skill for the full dependency block pattern):

```kotlin
dependencies {
    implementation(platform(libs.mycelium.bom)) // or aonyx.bom, or manis.bom
    implementation(libs.minestom) // no version — comes from the BOM
}
```

## Adding a new managed dependency to a BOM

Each BOM's `build.gradle.kts` pins dependencies in a `constraints` block:

```kotlin
plugins {
    `maven-publish`
    `java-platform`
    alias(libs.plugins.cyclonedx) // generates an actual SBOM artifact — present on mycelium-bom and manis-bom
}

group = "net.onelitefeather"
version = "1.8.0"

javaPlatform {
    allowDependencies() // required so this platform can itself depend on another platform (the tier below)
}

dependencies {
    api(platform(libs.junit.bom)) // or the tier below, e.g. api(platform(libs.mycelium.bom)) in aonyx-bom
    constraints {
        api(libs.minestom)
        api(libs.adventure.minimessage)
        api(libs.cyano)
        // add new pinned dependencies here
    }
}
```

To add a dependency:

1. Add it to the BOM repo's own version catalog (in `settings.gradle.kts`, same inline-catalog convention as any
   other project — see the `gradle` skill) with an explicit version.
2. Add a corresponding `api(libs.<name>)` line inside the `constraints { }` block.
3. Bump the BOM's own `version` and publish, so consuming projects can pick up the new entry.

**Renovate only updates existing version numbers in a BOM — it never adds or removes a dependency entry.** Adding a
genuinely new dependency to a BOM, or removing one that's no longer needed, has to be done by hand in a PR; don't
expect an automated tool to have already done it or to pick up a manual addition on its own version-wise afterward.

## When *not* to touch a BOM

If a dependency is only needed by one project and isn't likely to be reused, don't add it to a shared BOM just for
convenience — declare it directly in that project's own version catalog with an explicit version instead. BOMs are
for dependencies genuinely shared across multiple OneLiteFeather projects; adding one-off dependencies to them just
makes every consumer of that BOM carry a constraint they don't need.

## Further reference

`references/bom-contents.md` lists everything each of the three BOMs actually pins, as of the version researched —
useful to check whether something's already managed before adding a duplicate constraint.
