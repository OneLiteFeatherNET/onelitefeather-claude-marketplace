---
name: cloudnet
description: How to get a OneLiteFeather Minestom project running as a CloudNet service out of the box — reading CloudNet's injected bind host/port and stop signal, loading the CloudNet_Bridge through the minestom-ce-extensions ExtensionBootstrap (Minestom has no built-in extension system anymore), writing a bridge/permission extension.json that talks to CloudNet's driver/bridge APIs, and the Gradle dependency + maven-publish setup (shadowJar as the published artifact, compileOnly for everything CloudNet, the cloudnet-bom version catalog entries) so the build produces something CloudNet can actually run. Use this whenever setting up a new Minestom service/lobby/minigame project for CloudNet deployment, writing or editing an extension.json, debugging why a service won't bind or won't stop cleanly under CloudNet, or wiring CloudNet driver/bridge dependencies into build.gradle.kts — generic CloudNet or Minestom knowledge alone will miss that Minestom dropped its own extension system (this org depends on the minestom-ce-extensions fork instead) and that CloudNet jars must stay compileOnly, never bundled.
---

# CloudNet integration for Minestom projects

Getting a Minestom project to run under CloudNet touches three distinct things. Figure out which one(s) the task
actually needs before reaching for a template — most projects only need the first.

1. **The service itself** — the Minestom application jar CloudNet's wrapper starts as a plain Java process. Almost
   every project needs this.
2. **A bridge/permission extension** — only needed if the project has to reach CloudNet's driver/bridge APIs
   directly (permission resolution, server switching, player lookups across the network).
3. **A CloudNet node module** — registering a whole new service *environment* with CloudNet itself. This is
   infrastructure work, not something a plugin project does; see the closing note if you think you need it.

This skill assumes the `gradle` skill's single-module template as the starting point — read that first if the
project doesn't have a `build.gradle.kts` yet. Everything below is what CloudNet adds on top of it.

## 1. The service: reading what CloudNet hands you, reacting to shutdown

CloudNet's wrapper runs your shaded jar as a normal `java -jar` process and communicates with it two ways — get
both wrong and the service starts but the node can never actually reach or stop it:

- **Bind address**: read `-Dservice.bind.host` / `-Dservice.bind.port` system properties, falling back to
  `localhost:25565` only for standalone (non-CloudNet) runs. Never hardcode the bind address — CloudNet assigns it
  per-service.

  ```java
  String bindHost = System.getProperty("service.bind.host", "localhost");
  int bindPort = Integer.getInteger("service.bind.port", 25565);
  ```

- **Shutdown**: CloudNet stops a service by writing the literal line `stop` to its **stdin**, not by sending a
  signal. If nothing reads stdin, the node has no clean way to ask the process to exit and eventually has to kill
  it after a timeout. Start a daemon thread that reads lines from `System.in` (or `System.console()` when
  attached) and feeds non-blank lines into `CommandManager.execute(...)`, and register a `stop` command whose
  executor calls `MinecraftServer.stopCleanly()` then `System.exit(0)` **on a separate thread** — `stopCleanly()`
  tears down the very thread that's reading console input, so calling it from that thread deadlocks instead of
  exiting.

  ```java
  setDefaultExecutor((sender, context) -> Thread.ofPlatform().name("app-stop").start(() -> {
      MinecraftServer.stopCleanly();
      System.exit(0);
  }));
  ```

  Gate who can run it: any non-`Player` sender (i.e. CloudNet itself) should always be allowed; players need an
  explicit permission node.

### Loading the CloudNet bridge: Minestom has no extension system of its own anymore

CloudNet's Minestom integration (`CloudNet_Bridge`) is delivered as a **Minestom extension** — a separate jar in
the service's `extensions/` folder with its own classloader — not a library you depend on directly. But upstream
Minestom removed its built-in extension system, so loading extensions at all requires
[`minestom-ce-extensions`](https://github.com/hollowcube/minestom-ce-extensions) (now archived) or its actively
maintained OneLiteFeather fork,
[`net.onelitefeather:minestom-extensions`](https://github.com/OneLiteFeatherNET/minestom-extensions) — **CloudNet's
current RC depends on this extension system existing, so skipping it means the bridge simply never loads.** Prefer
the OneLiteFeather fork for new projects; only reach for the upstream `dev.hollowcube` coordinates if you have a
specific reason to match an existing sibling project that hasn't migrated yet.

In `main()`, bootstrap extensions **before** you bind, so the bridge and any other extensions finish initializing
before players can connect:

```java
ExtensionBootstrap bootstrap = ExtensionBootstrap.bootstrap(); // loads everything under extensions/

// ... your own server init (instances, listeners, commands) ...

String bindHost = System.getProperty("service.bind.host", "localhost");
int bindPort = Integer.getInteger("service.bind.port", 25565);
bootstrap.start(bindHost, bindPort); // binds and starts accepting connections
```

`minestom-ce-extensions` pulls in `com.github.Minestom:DependencyGetter` from JitPack transitively — add a JitPack
mirror to `settings.gradle.kts`'s `dependencyResolutionManagement.repositories` (OneLiteFeather proxies it) or the
build fails resolving that one transitive dependency, not anything obviously related to CloudNet:

```kotlin
maven {
    name = "reposiliteRepositoryOnelitefeatherProxy"
    url = uri("https://repo.onelitefeather.dev/onelitefeather-proxy")
}
```

**The application module itself never depends on any `cloudnet-*` artifact.** The bridge extension lives in its
own classloader; your app talks to it only through your own small "common" contract interfaces exchanging plain
JDK types (a `PermissionResolver`, a `ServerConnector`, etc. — see part 2). Reaching for a CloudNet dependency
inside the application module is a sign the logic belongs in a bridge extension instead.

## 2. A bridge/permission extension

Only build one of these if the project needs to *call into* CloudNet — resolving permissions through your own
perms backend, switching a player to another service/task, reading `ServiceInfoSnapshot`s. It's a second,
independent Gradle module packaged as its own extension jar, dropped into the service's `extensions/` folder next
to `CloudNet_Bridge`.

**`extension.json`** (in `src/main/resources/`):

```json
{
  "name": "MyProjectCloudNetPermissions",
  "version": "@version@",
  "entrypoint": "net.onelitefeather.myproject.bridge.MyProjectBridgeExtension",
  "authors": ["OneLiteFeather"],
  "dependencies": ["CloudNet_Bridge"]
}
```

- **`dependencies: ["CloudNet_Bridge"]` is what makes this work at all** — it forces your extension to load *after*
  the bridge and share its classloader hierarchy, which is the only way to reference bridge-internal types like
  `eu.cloudnetservice.modules.bridge.player.PlayerManager` directly. Without it, class loading fails or you get the
  wrong instance.
- The `@version@` placeholder gets stamped by a `processResources` filter (see Gradle section) instead of being
  hand-edited on every release.

**Entry point** — extend `net.minestom.server.extensions.Extension` (from `minestom-ce-extensions`), do CloudNet
wiring in `initialize()`:

```java
public final class MyProjectBridgeExtension extends Extension {
    @Override
    public void initialize() {
        ServiceRegistry.registry().registerProvider(
            MinestomPermissionChecker.class, "myproject-perms",
            (player, permission) -> MyPermissionBridge.hasPermission(player.getUuid(), permission)
        ).markAsDefaultService();
    }

    @Override
    public void terminate() {
    }
}
```

Keep the boundary narrow: expose a small holder class in a shared `common` module (JDK types only —
`UUID`/`String`/`boolean`, no CloudNet or bridge types) that both the application and this extension can see, and
route everything through it. The application sets the resolver; the extension calls it. That's the only thing that
should cross the classloader boundary between the two.

## Gradle dependency wiring

Add a `cloudnet` entry to the inline version catalog (see the `boms` skill first — if the project already imports
`manis-bom`, CloudNet is pinned there already and you don't need your own version; anywhere else, declare it
yourself like this):

```kotlin
versionCatalogs {
    create("libs") {
        version("cloudnet", "4.0.0-RC17-SNAPSHOT") // check the org's current pinned RC before copying this

        library("cloudnet-bom", "eu.cloudnetservice.cloudnet", "bom").versionRef("cloudnet")
        library("cloudnet-bridge", "eu.cloudnetservice.cloudnet", "bridge-api").withoutVersion()
        library("cloudnet-bridge-impl", "eu.cloudnetservice.cloudnet", "bridge-impl").withoutVersion()
        library("cloudnet-driver-api", "eu.cloudnetservice.cloudnet", "driver-api").withoutVersion()
        library("cloudnet-driver-impl", "eu.cloudnetservice.cloudnet", "driver-impl").withoutVersion()
        library("cloudnet-platform-inject", "eu.cloudnetservice.cloudnet", "platform-inject-api").withoutVersion()
        library("cloudnet-jvm-wrapper", "eu.cloudnetservice.cloudnet", "wrapper-jvm-api").withoutVersion()
    }
}
```

A CloudNet RC (as opposed to a stable release) may only exist as a snapshot — if resolution fails on the
`cloudnet-bom` version, add the snapshot repos alongside `mavenCentral()`:

```kotlin
maven("https://central.sonatype.com/repository/maven-snapshots/")
maven("https://repository.derklaro.dev/snapshots/")
maven("https://repository.derklaro.dev/releases/")
```

**Everything CloudNet-related is `compileOnly`, in the bridge/extension module only — never `implementation`, and
never in the application module at all.** CloudNet's driver and bridge classes are provided at runtime by the
wrapper and the `CloudNet_Bridge` extension; bundling them into your own jar produces duplicate classes across
classloaders instead of a working service.

```kotlin
dependencies {
    compileOnly(platform(libs.minestom.bom)) // or whichever BOM covers Minestom
    compileOnly(libs.minestom)
    compileOnly(project(":common"))

    compileOnly(platform(libs.cloudnet.bom))
    compileOnly(libs.cloudnet.driver.api)
    compileOnly(libs.cloudnet.bridge)
    compileOnly(libs.cloudnet.bridge.impl)
}
```

Stamp the version into `extension.json` instead of hand-editing it per release:

```kotlin
import org.apache.tools.ant.filters.ReplaceTokens

tasks.processResources {
    val tokens = mapOf("version" to project.version.toString())
    inputs.properties(tokens)
    filesMatching("extension.json") {
        filter<ReplaceTokens>("tokens" to tokens)
    }
}
```

## Maven publish: what actually needs to ship

Both modules use the standard `maven-publish` block from the `gradle` skill (POM name/description/url/licenses/
developers/scm, snapshot-vs-release URL split on `version.toString().contains("SNAPSHOT")`, the
`ONELITEFEATHER_MAVEN_USERNAME`/`PASSWORD` credential split) — the only thing that differs per module is **which
artifact gets published**, because the two modules run in fundamentally different ways:

- **Application module** — publish the **shaded/shadow jar**, not the plain `jar` task. The shaded jar *is* the
  deployable — it's what gets dropped into a CloudNet template or service directory and run directly, so that has
  to be the artifact consumers actually get:

  ```kotlin
  plugins {
      java
      application
      id("com.gradleup.shadow") version "9.4.2"
      `maven-publish`
  }

  tasks {
      jar { archiveClassifier.set("unshaded") }
      build { dependsOn(shadowJar) }
      shadowJar {
          archiveClassifier.set("")
          mergeServiceFiles()
          // Shaded deps often ship signed and multi-release jars, which break a
          // relocation-free fat jar at runtime — strip signatures and module-info.
          exclude("META-INF/*.SF", "META-INF/*.DSA", "META-INF/*.RSA")
          exclude("module-info.class", "META-INF/versions/**/module-info.class")
          duplicatesStrategy = DuplicatesStrategy.EXCLUDE
      }
  }

  publishing {
      publications.create<MavenPublication>("maven") {
          artifact(tasks.named("shadowJar"))
          artifactId = "myproject-app" // explicit — don't fall back to rootProject.name once there's more than one module
          // ... version/groupId/pom as in the gradle skill ...
      }
  }
  ```

- **Bridge/extension module** — publish the plain **`jar`** task. Nothing is bundled (everything CloudNet- and
  Minestom-related is `compileOnly`), so the thin jar is the correct, complete artifact:

  ```kotlin
  publishing {
      publications.create<MavenPublication>("maven") {
          artifact(tasks.named("jar"))
          artifactId = "myproject-bridge"
          // ...
      }
  }
  ```

Give every module an **explicit `artifactId`** once there's more than one publication in the build — relying on
`rootProject.name` works for a single-module library but silently collides once `app` and `bridge` both try to
publish under the same coordinates.

### CI

Don't hand-write a publish workflow — use the `workflows` skill (`release-engineering` plugin)'s `gradle-publish.yml`
reusable workflow, triggered on version tags:

```yaml
name: Publish JAR
on:
  push:
    tags:
      - "[0-9]+.[0-9]+.[0-9]+"
      - "v[0-9]+.[0-9]+.[0-9]+" # legacy tags some repos still use

jobs:
  publish:
    uses: OneLiteFeatherNET/workflows/.github/workflows/gradle-publish.yml@v2.1.0
    secrets: inherit
```

Only override `java-version`/`java-distribution` if there's a concrete reason to pin an exact build (e.g. an
AOT-cache artifact tied to a specific HotSpot build) — otherwise the workflow's default (Java 25 Temurin) is
correct.

## A node module is a different thing entirely

If the actual ask is "make CloudNet aware that Minestom is a service environment at all" rather than "make my
Minestom project run as a service" — that's a CloudNet **node module**, built with the `eu.cloudnetservice.juppiter`
Gradle plugin's `moduleJson { }` DSL and a `PlatformPluginManagerProvider` SPI implementation, installed on the
node itself rather than shipped inside any one project. OneLiteFeather's own example is
[`CustomMinestomCloudNetSupport`](https://github.com/OneLiteFeatherNET/CustomMinestomCloudNetSupport). This is
infra-level work maintained separately from application/game projects — don't reach for it just to get a game
project running; everything above this section is what that actually requires.

## Further reference

`references/new-service-checklist.md` has a condensed, ordered checklist for taking a project from "builds and
runs standalone" to "CloudNet can deploy and manage it out of the box."
