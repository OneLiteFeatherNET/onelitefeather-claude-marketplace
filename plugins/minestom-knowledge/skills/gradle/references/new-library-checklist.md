# Checklist: starting a new single-module OneLiteFeather library

SKILL.md has the full `build.gradle.kts`/`settings.gradle.kts` templates. This is the condensed checklist for
scaffolding a brand new library repo from scratch (Cyano/Aves/Xerus/Guira shape), in order.

1. **`settings.gradle.kts`** — `rootProject.name`, the `dependencyResolutionManagement` block (mavenCentral +
   the private `OneLiteFeatherRepository` with the CI/local credential split), and an inline `versionCatalogs`
   block with at least a `minestom` version entry.
2. **`build.gradle.kts`** — `jacoco` + `` `java-library` `` + `` `maven-publish` `` plugins, `group` (confirm which
   namespace — `net.onelitefeather` or `net.theevilreaper` — matches this project's family, don't guess), Java 25
   toolchain with `withJavadocJar()`/`withSourcesJar()`, the `compileJava` UTF-8/release-25 task config, the
   `jacocoTestReport` wiring, the `test` task with `useJUnitPlatform()` and
   `jvmArgs("-Dminestom.inside-test=true")`, and the `publishing` block with the snapshot/release URL split.
3. **Which BOM to import as `implementation(platform(libs.<name>.bom))`** — see the `boms` skill; default to
   `mycelium-bom` unless the project clearly needs Aves/Xerus/Guira (→ `aonyx-bom`) from day one.
4. **Test dependencies** — `testImplementation(libs.minestom)`, `testImplementation(libs.cyano)`, plus JUnit5
   (`junit-jupiter` or the split `junit.api`/`junit.params` entries, matching whichever style the chosen BOM's
   sibling libraries use), `testRuntimeOnly` for the JUnit engine, `testImplementation` for
   `junit-platform-launcher`.
5. **`gradlew`/`gradlew.bat`/`gradle/` wrapper** — copy from an existing sibling library rather than regenerating,
   to keep the wrapper version consistent across the org's repos.
6. **CI** — check an existing sibling library's `.github/workflows/` for the publish workflow shape (it reads
   `ONELITEFEATHER_MAVEN_USERNAME`/`ONELITEFEATHER_MAVEN_PASSWORD` from repo secrets, matching the credential block
   in `settings.gradle.kts`/`build.gradle.kts`) rather than writing a new CI pipeline from scratch.

If the new project is a multi-module application instead (a game/server, not a standalone library), use the
`buildSrc` convention-plugin shape from SKILL.md's "Multi-module application" section instead of this checklist.
