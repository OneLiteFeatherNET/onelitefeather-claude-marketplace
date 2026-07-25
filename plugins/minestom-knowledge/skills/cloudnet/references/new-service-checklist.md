# Checklist: getting a new Minestom project running under CloudNet

SKILL.md has the full explanation and code for each item. This is the condensed, ordered checklist for taking a
project from "builds and runs standalone" to "CloudNet can deploy and manage it out of the box" (Titan's `app` +
`bridge` shape).

1. **Bind address from system properties** — `service.bind.host` / `service.bind.port`, with `localhost`/`25565`
   fallback for standalone runs only. Hardcoding either means the node starts the service but can never route
   traffic to it.
2. **Stdin-driven shutdown** — a daemon thread reading `System.in` and feeding non-blank lines to
   `CommandManager.execute(...)`, plus a `stop` command whose executor runs `MinecraftServer.stopCleanly()` +
   `System.exit(0)` on a *separate* thread. Without this, CloudNet has no clean way to stop the service and kills
   it after a timeout instead.
3. **`minestom-ce-extensions` (or the `net.onelitefeather` fork) on the app's dependencies** — Minestom has no
   built-in extension system anymore; without this, `CloudNet_Bridge` (and any bridge extension you write) simply
   never loads. Bootstrap it and call `.start(bindHost, bindPort)` *after* your own server init.
4. **JitPack proxy repo in `settings.gradle.kts`** — `minestom-ce-extensions` pulls `DependencyGetter` from JitPack
   transitively; add `reposiliteRepositoryOnelitefeatherProxy` (`https://repo.onelitefeather.dev/onelitefeather-proxy`)
   or resolution fails on an unrelated-looking transitive dependency.
5. **If (and only if) the project needs to call CloudNet's driver/bridge APIs directly** (permissions, server
   switching, `ServiceInfoSnapshot` lookups) — a second Gradle module, packaged as its own extension:
   - `extension.json` with `"dependencies": ["CloudNet_Bridge"]` (required to share the bridge's classloader).
   - Extends `net.minestom.server.extensions.Extension`.
   - `compileOnly` for every `cloudnet-*` and Minestom dependency — nothing bundled.
   - A shared `common` module exposing only JDK-typed holder interfaces across the app ↔ extension classloader
     boundary — no CloudNet or bridge types crossing it.
   - `processResources` + `ReplaceTokens` stamping `project.version` into extension.json's `@version@` placeholder.
6. **`cloudnet` version catalog entries** — `cloudnet-bom`, `cloudnet-bridge`(-impl), `cloudnet-driver-api`(-impl),
   `cloudnet-platform-inject`, `cloudnet-jvm-wrapper`. Check the `boms` skill first — `manis-bom` already pins
   CloudNet; only declare your own version if the project isn't importing that BOM. A CloudNet RC may need the
   snapshot repos (`central.sonatype.com/.../maven-snapshots`, `repository.derklaro.dev/{snapshots,releases}`)
   added alongside `mavenCentral()`.
7. **Publish the right artifact per module** — the application module publishes its **shaded/shadow jar**
   (`shadowJar`, `archiveClassifier.set("")`, `mergeServiceFiles()`, signature/`module-info.class` stripped,
   `duplicatesStrategy = DuplicatesStrategy.EXCLUDE`) since that's the literal deployable; a bridge/extension
   module publishes the plain **`jar`** since nothing's bundled. Give every module an explicit `artifactId` once
   there's more than one publication in the build.
8. **CI publish workflow** — `OneLiteFeatherNET/workflows/.github/workflows/gradle-publish.yml`, triggered on
   numeric version tags, `secrets: inherit`. Don't hand-write a publish job; see the `workflows` skill
   (`release-engineering` plugin) for the full catalog and pin strategy.

If the task is actually "teach CloudNet that Minestom is a supported service environment" rather than "get my
project running as a CloudNet service" — that's a CloudNet **node module** (`eu.cloudnetservice.juppiter` Gradle
plugin, `moduleJson { }`), a different and much rarer kind of project. See SKILL.md's closing section before
building one of these by mistake.
