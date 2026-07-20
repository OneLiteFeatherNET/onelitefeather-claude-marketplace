---
name: gradle
description: OneLiteFeather's Gradle (Kotlin DSL) conventions for Minestom projects — how build.gradle.kts and settings.gradle.kts should look, single-module libraries vs multi-module applications, the private Maven repo, and Java toolchain settings. Use this whenever creating or editing a build.gradle.kts, settings.gradle.kts, or buildSrc convention plugin in a OneLiteFeather/Minestom project — generic Gradle knowledge alone will miss team-specific details (inline version catalog instead of libs.versions.toml, the private repo credential split, the -Dminestom.inside-test=true test flag) and produce a build file that looks plausible but doesn't match the rest of the team's projects.
---

# Gradle conventions for Minestom projects

OneLiteFeather's Minestom projects come in two shapes, and the right template depends on which one you're in:

- **Single-module library** (e.g. Cyano, Aves, Xerus, Guira) — one `build.gradle.kts`, everything inline.
- **Multi-module application** (e.g. ManisGame) — a `buildSrc` with shared convention plugins, and each
  module's `build.gradle.kts` stays thin by applying one of those.

Skim both sections below once to recognize which shape you're in, then use the matching template.

## Single-module library

**`settings.gradle.kts`:**

```kotlin
rootProject.name = "aves"

dependencyResolutionManagement {
    repositories {
        mavenCentral()
        maven {
            name = "OneLiteFeatherRepository"
            url = uri("https://repo.onelitefeather.dev/onelitefeather")
            if (System.getenv("CI") != null) {
                credentials {
                    username = System.getenv("ONELITEFEATHER_MAVEN_USERNAME")
                    password = System.getenv("ONELITEFEATHER_MAVEN_PASSWORD")
                }
            } else {
                credentials(PasswordCredentials::class)
                authentication {
                    create<BasicAuthentication>("basic")
                }
            }
        }
    }
    versionCatalogs {
        create("libs") {
            version("minestom", "2026.07.12-26.2")
            library("minestom", "net.minestom", "minestom").versionRef("minestom")
            // ...
        }
    }
}
```

Two things that surprise people coming from other Gradle projects:

- The version catalog is defined **inline in `settings.gradle.kts`**, not in a separate `gradle/libs.versions.toml`
  file. Add new dependencies here, not in a TOML file that doesn't exist in these projects.
- The private repo credential block is deliberately split: CI reads `ONELITEFEATHER_MAVEN_USERNAME` /
  `ONELITEFEATHER_MAVEN_PASSWORD` env vars directly, local dev goes through Gradle's standard
  `credentials(PasswordCredentials::class)` (backed by `~/.gradle/gradle.properties`). Keep both branches when
  copying this block — dropping the CI branch breaks the release pipeline, dropping the local branch breaks it for
  every other developer.

**`build.gradle.kts`:**

```kotlin
plugins {
    jacoco
    `java-library`
    `maven-publish`
}

group = "net.onelitefeather" // or "net.theevilreaper" — see note below
version = "1.0.0"

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(25))
    }
    withJavadocJar()
    withSourcesJar()
}

dependencies {
    implementation(platform(libs.mycelium.bom)) // see "BOMs" below
    compileOnly(libs.minestom)
    compileOnly(libs.adventure)

    testImplementation(libs.minestom)
    testImplementation(libs.cyano)
    testImplementation(libs.junit.jupiter)
    testImplementation(libs.junit.platform.launcher)
    testRuntimeOnly(libs.junit.jupiter.engine)
}

tasks {
    compileJava {
        options.encoding = "UTF-8"
        options.release.set(25)
    }

    jacocoTestReport {
        dependsOn(rootProject.tasks.test)
        reports {
            xml.required.set(true)
        }
    }

    test {
        finalizedBy(jacocoTestReport)
        useJUnitPlatform()
        jvmArgs("-Dminestom.inside-test=true")
        testLogging {
            events("passed", "skipped", "failed")
        }
    }
}

publishing {
    publications.create<MavenPublication>("maven") {
        from(components["java"])
    }

    repositories {
        maven {
            authentication {
                credentials(PasswordCredentials::class) {
                    username = System.getenv("ONELITEFEATHER_MAVEN_USERNAME")
                    password = System.getenv("ONELITEFEATHER_MAVEN_PASSWORD")
                }
            }
            name = "OneLiteFeatherRepository"
            url = if (project.version.toString().contains("SNAPSHOT")) {
                uri("https://repo.onelitefeather.dev/onelitefeather-snapshots")
            } else {
                uri("https://repo.onelitefeather.dev/onelitefeather-releases")
            }
        }
    }
}
```

Things to get right:

- **`-Dminestom.inside-test=true`** on the `test` task is not optional decoration — Minestom's own code branches on
  this flag during tests. Leaving it out produces test failures that look unrelated to what you're actually testing.
- **`group`**: the org publishes under two namespaces, `net.onelitefeather` and `net.theevilreaper` — which one a
  given project uses isn't a technical choice, it's about which of the two names that project already belongs to.
  When unsure, check what an existing sibling project (or the project's own `settings.gradle.kts` `rootProject.name`
  history) already uses rather than guessing.
- **`compileOnly` vs `implementation`**: Minestom and Adventure are provided by the runtime the library is loaded
  into, so they're `compileOnly` (and `testImplementation` for actually running tests) — never `implementation`,
  or you'll bundle a second copy of the server framework into consumers of your library.
- **Publishing target**: the snapshot/release split is based on whether `project.version` contains the literal
  string `"SNAPSHOT"` — keep that convention when bumping versions, don't hardcode one URL.

## Multi-module application

Larger projects (games, servers with several extensions) factor shared build logic into **convention plugins** in
`buildSrc` instead of repeating it per module:

```
buildSrc/
└── src/main/kotlin/
    ├── manis.application-conventions.gradle.kts
    ├── manis.java-conventions.gradle.kts
    └── manis.library-conventions.gradle.kts
```

Each module's `build.gradle.kts` then stays small — it applies the matching convention plugin and lists only what's
specific to that module:

```kotlin
plugins {
    id("manis.application-conventions")
    alias(libs.plugins.shadow)
}

dependencies {
    implementation(platform(libs.manis.bom))
    implementation(project(":shared:api"))
    implementation(libs.aves)
    implementation(libs.xerus)
    implementation(libs.minestom)

    testImplementation(libs.cyano)
    testImplementation(libs.minestom)
}

application {
    mainClass.set("net.theevilreaper.manis.ManisServer")
}

tasks {
    jar { archiveClassifier.set("unshaded") }
    build { dependsOn(shadowJar) }
    shadowJar { archiveClassifier.set("") }
}
```

The root `settings.gradle.kts` grows a matching version catalog (still inline, same rules as above) plus
`include("shared:api")`, `include("extensions:game")`, etc. for every module, and can group related libraries with
`bundle("name", listOf(...))` when several modules pull the same set together (e.g. a geometry or database bundle).

If you're adding a new module to an existing multi-module project, look at an existing sibling module's
`build.gradle.kts` first and match its shape — don't build a fresh single-module-style file from scratch inside a
multi-module project, since that skips the shared conventions the rest of the project relies on.

## BOMs (brief — see the dedicated `boms` skill for depth)

Dependency versions are managed centrally through the org's own BOMs (`mycelium-bom`, `aonyx-bom`, `manis-bom`),
imported with `implementation(platform(libs.<name>.bom))`. Libraries pulled from a BOM are usually declared with
`.withoutVersion()` in the version catalog rather than `.versionRef(...)`, since the BOM is what pins the version.
Which BOM applies to which project, and how to add a new managed dependency to one, is covered in the `boms` skill —
this one just covers that the pattern exists and how it plugs into the build file.

## Further reference

`references/new-library-checklist.md` has a condensed, ordered checklist for scaffolding a brand new single-module
library repo from scratch.
