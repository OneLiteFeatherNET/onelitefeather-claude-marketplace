---
name: dependency-management
description: OneLiteFeather's Gradle/Micronaut dependency-management conventions for REST API backends — the Micronaut Application and AOT plugins, reading the Micronaut version from gradle.properties instead of hardcoding it, the mn.* platform catalog, the private OneLiteFeather Maven repo, and the optional CycloneDX SBOM plugin. Use this whenever setting up or editing a Micronaut backend's build.gradle.kts/settings.gradle.kts. For the general OneLiteFeather Gradle/BOM mechanics that apply beyond Micronaut (private repo credential split, Java toolchain pattern), see minestom-knowledge:gradle/boms instead. For observability, database-migration, Testcontainers, and logging dependencies specifically, see the observability, liquibase, testcontainers, and logging skills — this skill only lists that those dependencies exist and where to look, not their coordinates.
---

# Micronaut dependency management

A Micronaut REST API backend at OneLiteFeather is a single-module Gradle project (unless
`entity-design`'s optional separate-model-module pattern applies) built with the Micronaut Application
plugin and its AOT companion. This skill covers the plugins, version handling, and the private-repo
catalog specific to Micronaut — general OneLiteFeather Gradle mechanics (private repo credentials, Java
toolchain) are covered by `minestom-knowledge:gradle`/`boms` and are not repeated here.

## Plugins

`settings.gradle.kts` applies the Micronaut Platform Catalog plugin, which generates the `mn.*` version
catalog (Micronaut's own dependency BOM, exposed as Gradle catalog entries) without needing a hand-written
`libs.versions.toml`:

```kotlin
pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }
}

plugins {
    id("io.micronaut.platform.catalog") version "5.0.2"
}

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
                authentication { create<BasicAuthentication>("basic") }
            }
        }
    }
}
```

`build.gradle.kts` applies the two Micronaut plugins on top:

```kotlin
plugins {
    alias(mn.plugins.micronaut.application)
    alias(mn.plugins.micronaut.aot)
}

micronaut {
    runtime("netty")
    testRuntime("junit5")
    aot {
        precomputeOperations = true
        cacheEnvironment = true
        optimizeNetty = true
        // Keep logback.xml parsed at runtime so the env-driven JSON/plain switch
        // and ${...} substitutions still work in the AOT-optimized (Docker/prod) jar.
        replaceLogbackXml = false
    }
}
```

The commented `replaceLogbackXml = false` line is deliberate style, not filler — every non-obvious
build-file trade-off (an AOT flag, an inert dependency kept for a specific environment) gets a one-line
comment explaining why. Carry this convention into every build file this skill touches.

## Reading the Micronaut version

Never hardcode a Micronaut version anywhere in generated code or in this skill's own guidance — always
read it from the target project's `gradle.properties`:

```properties
micronautVersion=4.10.2
```

The Platform Catalog plugin and every `mn.*` coordinate resolve against this value. When writing or
reviewing a Micronaut project, check `gradle.properties` first; do not assume the version shown in any
example here (including this skill's own examples) is current — Micronaut ships frequent minor releases,
and a stale version number in documentation is worse than no version number.

## Annotation processing

The `mn.*` catalog also carries the annotation processors a REST backend needs — add them explicitly,
they are not implicit:

```kotlin
dependencies {
    annotationProcessor(mn.micronaut.serde.processor)
    annotationProcessor(mn.micronaut.http.validation)
    annotationProcessor(mn.micronaut.data.processor)
    annotationProcessor(mn.micronaut.validation.processor)
    annotationProcessor(mn.micronaut.inject.java)
    annotationProcessor(mn.micronaut.openapi)

    compileOnly(mn.micronaut.openapi.annotations)
}
```

## CycloneDX (recommended, not mandatory)

The CycloneDX Gradle plugin (`org.cyclonedx.bom`) generates a Software Bill of Materials for the
project's dependency tree — recommended for supply-chain transparency, but not a hard requirement for
every Micronaut backend:

```kotlin
plugins {
    alias(libs.plugins.cyclonedx)
}
```

Adopt it when the project is externally deployed or when the org starts requiring SBOMs org-wide;
skip it for small internal-only services if the extra build step isn't worth it yet.

## Structured logging dependencies

The Logstash JSON encoder and the OpenTelemetry MDC appender (see `logging`) aren't part of the `mn.*`
platform catalog, so they need their own version-catalog entries:

```kotlin
// settings.gradle.kts version catalog
library("logstash.logback.encoder", "net.logstash.logback", "logstash-logback-encoder")
library("opentelemetry.logback.mdc", "io.opentelemetry.instrumentation", "opentelemetry-logback-mdc-1.0")
```

```kotlin
// build.gradle.kts
dependencies {
    implementation(libs.logstash.logback.encoder)
    implementation(libs.opentelemetry.logback.mdc)
    runtimeOnly(libs.janino) // enables <if>/<then>/<else> in logback.xml
}
```

`logging` covers when and how these get used (structured JSON output, trace/span correlation); this is
only where their Gradle coordinates come from.

## What lives in other skills, not here

- Metrics, tracing, and Kubernetes service discovery dependencies — `observability`.
- The database migration tool and its dependency — `liquibase`.
- Test dependencies for container-backed integration tests — `testcontainers`.
- Micronaut Security dependencies for the deny-by-default baseline — security.

This skill only establishes the Micronaut/Gradle plugin baseline and version-handling convention; it
does not enumerate every dependency a backend might need.
