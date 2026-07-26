# Micronaut-Standards Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a new `micronaut-standards` plugin to this Claude Code plugin marketplace, containing fourteen skills that teach OneLiteFeather's standard for Micronaut REST APIs, per `docs/superpowers/specs/2026-07-26-micronaut-standards-design.md`.

**Architecture:** Pure skill-knowledge plugin (no MCP servers, no hooks, no commands) — one directory per skill under `plugins/micronaut-standards/skills/`, each with a `SKILL.md` entry point and (only for `entity-design`, which needs one) a `references/` subfolder, mirroring the existing `plugins/minestom-knowledge` and `plugins/release-engineering` plugins' structure exactly.

**Tech Stack:** Markdown with YAML frontmatter (`SKILL.md` files), JSON (plugin manifests, `marketplace.json`). No build step, no test framework in this repo — "tests" in this plan are structural/content verification via `jq` (JSON validity) and `grep` (required frontmatter fields and key content markers), matching the fact that this repo has no `package.json`, no CI, and no linter configured.

## Global Constraints

- Plugin name: `micronaut-standards`. Skill names (all lowercase, kebab-case): `dependency-management`, `observability`, `service-layer`, `entity-design`, `configuration`, `dto`, `response-modeling`, `openapi`, `routing`, `exception-handling`, `security`, `liquibase`, `testcontainers`, `logging`.
- Every `SKILL.md` needs YAML frontmatter with exactly `name` and `description` fields (no other frontmatter keys — verified against all existing `minestom-knowledge`/`release-engineering` skills).
- The standard is **normative, not descriptive** — where Otis or Vulpes-Backend show a weakness, the skill documents the corrected version, not the as-found one. Three explicit corrections apply throughout:
  1. The `*Api` documentation interface (see `openapi`) carries **only** `@Operation`/`@ApiResponse` — routing annotations (`@Controller`, `@Get`/`@Post`/`@Put`/`@Delete`) and validation triggers (`@Validated`, `@Valid`) stay on the concrete controller class (see `routing`).
  2. The global exception handler (see `exception-handling`) maps exception types to the correct HTTP status code — it must never unconditionally return one status (e.g. 404) for every `Throwable`, which is what Vulpes-Backend's current `ExceptionHandlerAdvice` does.
  3. Liquibase changelogs (see `liquibase`) are **always** XML — never YAML/SQL/JSON — so the same changelog runs unchanged against both MariaDB and PostgreSQL.
- Response modeling uses the sealed-interface pattern from Vulpes-Backend (`sealed interface FooResponseDTO` with a success record + an error record implementing a shared `ErrorResponse` marker interface) — not RFC 7807 problem-detail.
- Request DTOs use one shared Create/Update record controlled by JSR-380 validation groups (`ValidationGroup.Create`/`Update`) — never separate Create/Update DTO types.
- Conversion methods live on the DTOs themselves (`toXxxEntity()` on the request DTO, static `createDTO(entity)` on the response DTO) — never on the entity, never in a separate mapper class.
- Testcontainers + `micronaut-test-resources` is the mandatory integration-test approach — never a permanently embedded H2 driver as the only test strategy.
- The service layer (interface + `impl` sub-package) is mandatory — business logic never lives directly in a controller.
- Content is generic/example-driven with placeholder resource names (`Font`, `Foo`, etc., matching the real Vulpes-Backend `Font` example already used in the spec) — no content is copy-pasted verbatim from one specific real OneLiteFeather repo as "the" example beyond the already-agreed `Font` walkthrough, though real repos may be named as brief "seen in X" pointers.
- No scaffolding commands, no mandatory multi-module/separate-model-artifact setup, no complete auth/identity scheme, no reactive programming model, no CI/CD conventions — all explicitly out of scope per the spec's "Out of scope" section.
- Every new/modified plugin manifest and `marketplace.json` must remain valid JSON (`jq empty <file>` exits 0).

---

### Task 1: Plugin scaffold — manifests

**Files:**
- Create: `plugins/micronaut-standards/.claude-plugin/plugin.json`
- Create: `plugins/micronaut-standards/.codex-plugin/plugin.json`
- Create: `plugins/micronaut-standards/.antigravity-plugin/plugin.json`

**Interfaces:**
- Produces: the plugin directory `plugins/micronaut-standards/` that Tasks 3–17 populate with `skills/`. No code interfaces — these are static JSON manifests, structurally identical in shape to `plugins/release-engineering`'s three manifests.

- [ ] **Step 1: Write a failing structural check**

Run this before creating any files — it must fail because the directory doesn't exist yet:

```bash
test -f plugins/micronaut-standards/.claude-plugin/plugin.json && echo "UNEXPECTED: already exists" || echo "OK: missing as expected"
```

Expected output: `OK: missing as expected`

- [ ] **Step 2: Create `plugins/micronaut-standards/.claude-plugin/plugin.json`**

```json
{
  "name": "micronaut-standards",
  "displayName": "Micronaut Standards",
  "version": "0.1.0",
  "description": "OneLiteFeather's standard for Micronaut REST APIs: Gradle/Micronaut dependency management, observability, a mandatory service layer, entity design, configuration, DTO and sealed-interface response modeling, OpenAPI documentation via a doc-only *Api interface, HTTP routing, global exception handling, a deny-by-default security baseline, Liquibase migrations (always XML), Testcontainers-based integration testing, and structured logging.",
  "author": { "name": "OneLiteFeather", "url": "https://github.com/OneLiteFeatherNET" },
  "license": "MIT",
  "keywords": ["micronaut", "java", "rest-api", "openapi", "liquibase", "testcontainers", "dto", "architecture", "dependency-management", "gradle"]
}
```

- [ ] **Step 3: Create `plugins/micronaut-standards/.codex-plugin/plugin.json`**

```json
{
  "name": "micronaut-standards",
  "version": "0.1.0",
  "description": "OneLiteFeather's standard for Micronaut REST APIs: Gradle/Micronaut dependency management, observability, a mandatory service layer, entity design, configuration, DTO and sealed-interface response modeling, OpenAPI documentation via a doc-only *Api interface, HTTP routing, global exception handling, a deny-by-default security baseline, Liquibase migrations (always XML), Testcontainers-based integration testing, and structured logging.",
  "author": { "name": "OneLiteFeather", "url": "https://github.com/OneLiteFeatherNET" },
  "license": "MIT",
  "keywords": ["micronaut", "java", "rest-api", "openapi", "liquibase", "testcontainers", "dto", "architecture", "dependency-management", "gradle"],
  "skills": "./skills/",
  "hooks": {}
}
```

- [ ] **Step 4: Create `plugins/micronaut-standards/.antigravity-plugin/plugin.json`**

```json
{
  "name": "micronaut-standards",
  "version": "0.1.0",
  "description": "OneLiteFeather's standard for Micronaut REST APIs: Gradle/Micronaut dependency management, observability, a mandatory service layer, entity design, configuration, DTO and sealed-interface response modeling, OpenAPI documentation via a doc-only *Api interface, HTTP routing, global exception handling, a deny-by-default security baseline, Liquibase migrations (always XML), Testcontainers-based integration testing, and structured logging.",
  "author": { "name": "OneLiteFeather", "url": "https://github.com/OneLiteFeatherNET" },
  "license": "MIT",
  "keywords": ["micronaut", "java", "rest-api", "openapi", "liquibase", "testcontainers", "dto", "architecture", "dependency-management", "gradle"],
  "skills": "./skills/"
}
```

- [ ] **Step 5: Verify all three are valid JSON with matching `name`**

```bash
for f in plugins/micronaut-standards/.claude-plugin/plugin.json \
         plugins/micronaut-standards/.codex-plugin/plugin.json \
         plugins/micronaut-standards/.antigravity-plugin/plugin.json; do
  jq -e '.name == "micronaut-standards"' "$f" >/dev/null && echo "OK: $f" || echo "FAIL: $f"
done
```

Expected: three `OK:` lines, no `FAIL:` lines.

- [ ] **Step 6: Commit**

```bash
git add plugins/micronaut-standards/.claude-plugin/plugin.json \
        plugins/micronaut-standards/.codex-plugin/plugin.json \
        plugins/micronaut-standards/.antigravity-plugin/plugin.json
git commit -m "feat: scaffold micronaut-standards plugin manifests"
```

---

### Task 2: Register the plugin in `marketplace.json` and `README.md`

**Files:**
- Modify: `.claude-plugin/marketplace.json`
- Modify: `README.md`

**Interfaces:**
- Consumes: `plugins/micronaut-standards` directory existing (Task 1).
- Produces: nothing consumed by later tasks — this is a leaf registration step, but doing it early means every subsequent task can be checked out independently without the plugin being "invisible" to the marketplace tooling in the meantime.

- [ ] **Step 1: Write a failing check**

```bash
jq -e '.plugins[] | select(.name == "micronaut-standards")' .claude-plugin/marketplace.json >/dev/null \
  && echo "UNEXPECTED: already registered" || echo "OK: not registered yet"
```

Expected: `OK: not registered yet`

- [ ] **Step 2: Add the plugin entry to `.claude-plugin/marketplace.json`**

Open `.claude-plugin/marketplace.json`. The `"plugins"` array currently ends with the
`requirement-engineering` entry's closing `}` followed by `]`. Add a `,` after that `}`, then add:

```json
    {
      "name": "micronaut-standards",
      "displayName": "Micronaut Standards",
      "source": "./plugins/micronaut-standards",
      "description": "OneLiteFeather's standard for Micronaut REST APIs: dependency management, observability, service layer, entity design, configuration, DTO/response modeling, OpenAPI docs, HTTP routing, exception handling, security baseline, Liquibase migrations, Testcontainers, and logging.",
      "category": "productivity",
      "keywords": ["micronaut", "java", "rest-api", "openapi", "liquibase", "testcontainers", "dto", "architecture", "dependency-management"]
    }
```

The full `"plugins"` array must end up with seven entries: `framework`, `framework-code-navigation`, `minestom-knowledge`, `release-engineering`, `agent-orchestrator`, `requirement-engineering`, `micronaut-standards`, in that order.

- [ ] **Step 3: Verify JSON validity and the new entry**

```bash
jq empty .claude-plugin/marketplace.json && echo "OK: valid JSON"
jq -e '.plugins[] | select(.name == "micronaut-standards") | .source == "./plugins/micronaut-standards"' .claude-plugin/marketplace.json >/dev/null \
  && echo "OK: entry present" || echo "FAIL: entry missing or wrong source"
jq '.plugins | length' .claude-plugin/marketplace.json
```

Expected: `OK: valid JSON`, `OK: entry present`, and `7` as the length.

- [ ] **Step 4: Add a row to the plugin table in `README.md`**

In `README.md`, find the `## The plugins` table (currently six rows, ending with `requirement-engineering`). Add a seventh row directly after the `requirement-engineering` row:

```markdown
| **micronaut-standards** | OneLiteFeather's standard for Micronaut REST APIs: dependency management, observability, service layer, entity design, configuration, DTO/response modeling, OpenAPI docs, HTTP routing, exception handling, security baseline, Liquibase migrations, Testcontainers, and logging. No MCP servers, pure skill content. |
```

- [ ] **Step 5: Add an install line to the `## Install` → `### Claude Code` section**

In the same `README.md`, in the `### Claude Code` fenced bash block, after the line
`/plugin install requirement-engineering@onelitefeather-claude-marketplace`, add:

```bash

# Micronaut REST API standard: dependency management, architecture, DTOs, OpenAPI, security, migrations
/plugin install micronaut-standards@onelitefeather-claude-marketplace
```

- [ ] **Step 6: Verify the README changes landed**

```bash
grep -c "micronaut-standards" README.md
```

Expected: `2` (the table row's `**micronaut-standards**` cell, and the
`/plugin install micronaut-standards@onelitefeather-claude-marketplace` line — the comment line above
it intentionally doesn't repeat the plugin name). Confirm both lines are present via
`grep -n "micronaut-standards" README.md`.

- [ ] **Step 7: Commit**

```bash
git add .claude-plugin/marketplace.json README.md
git commit -m "feat: register micronaut-standards in marketplace and README"
```

---

### Task 3: `dependency-management/SKILL.md`

**Files:**
- Create: `plugins/micronaut-standards/skills/dependency-management/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: cross-references to the skill names `observability`, `liquibase`, `testcontainers`, `logging` (Tasks 4, 15, 16, 17) — these must exist as skill names for the pointers to resolve, but there is no code dependency, only a naming match.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/micronaut-standards/skills/dependency-management/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
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

## What lives in other skills, not here

- Metrics, tracing, and Kubernetes service discovery dependencies — `observability`.
- The database migration tool and its dependency — `liquibase`.
- Test dependencies for container-backed integration tests — `testcontainers`.
- Structured logging dependencies (Logstash encoder, OpenTelemetry MDC appender) — `logging`.

This skill only establishes the Micronaut/Gradle plugin baseline and version-handling convention; it
does not enumerate every dependency a backend might need.
```

- [ ] **Step 3: Verify frontmatter and required content markers**

```bash
f=plugins/micronaut-standards/skills/dependency-management/SKILL.md
head -1 "$f" | grep -qx -- '---' && echo "OK: frontmatter fence"
grep -q '^name: dependency-management$' "$f" && echo "OK: name field"
grep -q '^description: ' "$f" && echo "OK: description field"
grep -q 'io.micronaut.platform.catalog' "$f" && echo "OK: platform catalog plugin documented"
grep -q 'micronautVersion=' "$f" && echo "OK: version-from-gradle.properties convention documented"
grep -q 'cyclonedx' "$f" && echo "OK: CycloneDX covered"
grep -q '^- Metrics, tracing' "$f" && echo "OK: cross-reference list present"
```

Expected: seven `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/micronaut-standards/skills/dependency-management/SKILL.md
git commit -m "feat: add dependency-management skill"
```

---

### Task 4: `observability/SKILL.md`

**Files:**
- Create: `plugins/micronaut-standards/skills/observability/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: a cross-reference to `logging` (Task 17) — naming match only.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/micronaut-standards/skills/observability/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
---
name: observability
description: Metrics and tracing infrastructure for a OneLiteFeather Micronaut REST API — Micrometer with Prometheus, OpenTelemetry tracing for HTTP and JDBC, and Kubernetes service discovery (inert outside a cluster). Use this whenever wiring up metrics/tracing dependencies or the /metrics endpoint in a Micronaut backend, or deciding whether a dependency like the Kubernetes discovery client is safe to always include. For log-usage conventions (what to log, structured JSON logging, trace/log correlation), see the logging skill instead — this skill covers the metrics/tracing infrastructure only.
---

# Observability: metrics and tracing

Every OneLiteFeather Micronaut backend ships the same baseline observability stack, regardless of
whether the deployment target is Kubernetes or not — the dependencies are inert (do nothing, cost
nothing at runtime) when their activation condition isn't met, so there is no cost to including them
everywhere and no per-project decision to make.

## Metrics: Micrometer + Prometheus

```kotlin
dependencies {
    implementation(mn.micronaut.management)
    implementation(mn.micronaut.micrometer.core)
    implementation(mn.micronaut.micrometer.registry.prometheus)
}
```

`micronaut-management` exposes the `/metrics` endpoint (guarded by the `security` skill's
deny-by-default baseline like every other endpoint); the Prometheus registry formats those metrics for
scraping. No extra configuration is needed beyond enabling the endpoint in `application.yml`:

```yaml
endpoints:
  metrics:
    enabled: true
    sensitive: false
```

## Tracing: OpenTelemetry for HTTP and JDBC

```kotlin
dependencies {
    implementation(mn.micronaut.tracing.opentelemetry.http)
    implementation(mn.micronaut.tracing.opentelemetry.jdbc)
    implementation(libs.opentelemetry.exporter.otlp)
}
```

Spans are only actually exported when the `OTEL_TRACES_EXPORTER=otlp` environment variable is set —
locally, with no exporter configured, these dependencies are present but produce no network traffic and
no overhead beyond in-process span creation. Set `OTEL_TRACES_EXPORTER=otlp` (plus `OTEL_EXPORTER_OTLP_ENDPOINT`)
only in the environments (staging, production, Docker) that actually have a collector to receive spans.

The `logging` skill covers how these trace/span IDs get correlated into log lines via the OpenTelemetry
MDC appender — that correlation glue lives there, not here, since it's a logging-format concern, not a
tracing-infrastructure one.

## Kubernetes service discovery

```kotlin
dependencies {
    // Kubernetes service discovery — beans only activate in the k8s environment,
    // so this is inert outside it. Needs RBAC (read on services/endpoints) in-cluster.
    implementation(mn.micronaut.kubernetes.discovery.client)
}
```

Include this dependency in every backend's `build.gradle.kts`, not only ones that are currently deployed
to Kubernetes — the discovery client's beans only activate when the Micronaut `kubernetes` environment
is detected, so it is a no-op everywhere else. When a backend *is* deployed to a cluster, the
`ServiceAccount` running it needs RBAC permission to `get`/`list`/`watch` on `services` and `endpoints`
in its namespace, or the discovery client fails at startup instead of silently doing nothing.

## What lives in other skills, not here

- Log-usage conventions, structured JSON logging, log levels, trace/log correlation — `logging`.
- The Gradle plugin baseline (Micronaut Application/AOT) these dependencies sit on top of —
  `dependency-management`.
```

- [ ] **Step 3: Verify frontmatter and content markers**

```bash
f=plugins/micronaut-standards/skills/observability/SKILL.md
grep -q '^name: observability$' "$f" && echo "OK: name field"
grep -q 'mn.micronaut.micrometer.registry.prometheus' "$f" && echo "OK: Prometheus registry documented"
grep -q 'OTEL_TRACES_EXPORTER' "$f" && echo "OK: OTel activation condition documented"
grep -q 'kubernetes.discovery.client' "$f" && grep -q 'RBAC' "$f" && echo "OK: k8s discovery + RBAC covered"
grep -q '^- Log-usage conventions' "$f" && echo "OK: cross-reference to logging present"
```

Expected: five `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/micronaut-standards/skills/observability/SKILL.md
git commit -m "feat: add observability skill"
```

---

### Task 5: `service-layer/SKILL.md`

**Files:**
- Create: `plugins/micronaut-standards/skills/service-layer/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: a naming convention (`FooService`/`FooServiceImpl`) that Task 9 (`dto`) and Task 10
  (`response-modeling`) reference by name when describing where conversion methods get called from.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/micronaut-standards/skills/service-layer/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
---
name: service-layer
description: OneLiteFeather's mandatory service-layer convention for Micronaut REST APIs — a service interface plus a service/impl implementation package, constructor injection only, business logic kept out of controllers. Use this whenever adding a new resource/feature to a Micronaut backend and deciding where its business logic should live, or when reviewing a controller that talks to a repository directly. This is a deliberate departure from a simpler controller-to-repository pattern sometimes seen in smaller Micronaut projects — for entity/persistence conventions specifically, see entity-design; for dependency-injection details beyond the constructor-injection rule itself, this skill is the single source of truth.
---

# Service layer

Every Micronaut REST API backend at OneLiteFeather has an explicit service layer between its
controllers and its repositories. Business logic — validation beyond what a DTO's annotations express,
multi-step operations, orchestration across more than one repository — belongs in a service, never
directly in a controller method body. A controller that calls a repository directly is a sign the
service layer was skipped, not a sign the feature was simple enough to skip it.

## Interface + impl

Each feature gets a service interface in `service/`, and its implementation in `service/impl/`:

```java
// service/FontService.java
public interface FontService {
    FontModelResponseDTO.FontModelDTO createFont(FontModelDTO fontModelDTO);
    FontModelResponseDTO updateFont(FontModelDTO fontModelDTO);
    FontModelResponseDTO deleteFont(UUID id);
    Page<FontModelResponseDTO.FontModelDTO> getAllFonts(Pageable pageable);
    Optional<FontEntity> findFontById(UUID id);
}
```

```java
// service/impl/FontServiceImpl.java
@Singleton
public class FontServiceImpl implements FontService {

    private final FontRepository fontRepository;

    @Inject
    public FontServiceImpl(FontRepository fontRepository) {
        this.fontRepository = fontRepository;
    }

    @Override
    public FontModelResponseDTO.FontModelDTO createFont(FontModelDTO fontModelDTO) {
        FontEntity saved = fontRepository.save(fontModelDTO.toFontModel());
        return FontModelResponseDTO.FontModelDTO.createDTO(saved);
    }

    // ...
}
```

The interface is what the controller depends on (`FontController` is constructed with a `FontService`,
never a `FontServiceImpl` directly) — this keeps the controller decoupled from the implementation and
makes the service trivially mockable in controller-level unit tests.

## Constructor injection only

`@Inject` goes on the constructor, on every injectable bean — services, controllers, anything else
Micronaut manages. No field injection (`@Inject` on a field directly) anywhere in the codebase:

```java
// Correct
@Inject
public FontServiceImpl(FontRepository fontRepository) {
    this.fontRepository = fontRepository;
}
```

```java
// Wrong — do not do this
@Inject
private FontRepository fontRepository;
```

Constructor injection makes dependencies explicit in the type's public API, lets the dependency be
`final`, and makes the class constructible in a plain unit test without a DI container.

## What the service does and doesn't do

- Orchestrates one or more repository calls into a single business operation.
- Calls the conversion methods that live on the DTOs themselves (`toXxxEntity()` on the request DTO,
  `createDTO(entity)` on the response DTO — see `dto` and `response-modeling`) — the service is the
  caller of these methods, not the owner of the conversion logic.
- Does **not** contain persistence logic itself (no manual SQL, no `EntityManager` juggling beyond what
  the repository already provides) — that belongs entirely behind the repository interface.
- Does **not** know about HTTP concepts (`HttpResponse`, status codes) — those are the controller's
  concern (see `routing`), so a service method returns a plain DTO or entity, never an `HttpResponse<T>`.
```

- [ ] **Step 3: Verify frontmatter and content markers**

```bash
f=plugins/micronaut-standards/skills/service-layer/SKILL.md
grep -q '^name: service-layer$' "$f" && echo "OK: name field"
grep -q 'service/impl/FontServiceImpl.java' "$f" && echo "OK: interface+impl example present"
grep -q 'No field injection' "$f" && echo "OK: constructor-injection rule stated"
grep -q 'Does \*\*not\*\* contain persistence logic' "$f" && echo "OK: scope boundary documented"
```

Expected: four `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/micronaut-standards/skills/service-layer/SKILL.md
git commit -m "feat: add service-layer skill"
```

---

### Task 6: `entity-design/SKILL.md`

**Files:**
- Create: `plugins/micronaut-standards/skills/entity-design/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: links to `references/separate-model-module.md`, which Task 7 creates — the exact relative
  path `references/separate-model-module.md` must match.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/micronaut-standards/skills/entity-design/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
---
name: entity-design
description: OneLiteFeather's JPA/Micronaut Data entity conventions for Micronaut REST APIs — entities as a pure persistence layer with no Bean Validation annotations, the internal-UUID-vs-external-identifier pattern, custom AttributeConverters for complex column types, and why entities are plain Java beans rather than records or Lombok classes. Use this whenever adding or reviewing a database/entity/ class in a Micronaut backend. For where entity validation actually lives, see the dto skill; for the optional pattern of publishing entities from a separate Maven module instead of keeping them in the backend, see references/separate-model-module.md in this skill.
---

# Entity design

Entities in `database/entity/` are a pure persistence layer — nothing more. They map to a table, and
that is their entire job. Validation, conversion, and API shape all live elsewhere (see `dto` and
`response-modeling`); an entity that also carries `@NotBlank`/`@Size` annotations or a `toDto()` method
is doing someone else's job.

## No Bean Validation on the entity

```java
// database/entity/FontEntity.java — correct: no @NotBlank, @Size, etc. here
@Entity
@Table(indexes = { @Index(columnList = "uiName") })
public class FontEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private String uiName;
    private String provider;
    // ...

    public FontEntity() {
    } // required by Hibernate

    public FontEntity(UUID id, String uiName, String provider /*, ... */) {
        this.id = id;
        this.uiName = uiName;
        this.provider = provider;
    }

    // getters and setters
}
```

The DTO (see `dto`) is the single source of truth for validation. Putting `@NotBlank` on both the DTO
field and the entity field means the same rule can drift out of sync between the two — one gets updated,
the other doesn't, and now the entity silently accepts data the DTO would have rejected (or vice versa).
Keep it in exactly one place: the DTO.

## Internal ID vs. external identifier

When an entity represents something that also has an identifier from an external system (a Minecraft
player's Mojang UUID, a third-party API's own ID), keep the entity's own primary key separate from that
external identifier instead of reusing it as the `@Id`:

```java
@Entity
@Table(indexes = {
    @Index(columnList = "playerUuid"),
    @Index(columnList = "playerName")
})
public class PlayerEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;              // internal primary key

    private UUID playerUuid;      // external identifier (Mojang UUID) — indexed, not the PK

    private String playerName;
}
```

This decouples the row's identity from an identifier the application doesn't control — if the external
system's ID scheme ever needs to change or be re-issued, the entity's own primary key and every foreign
key pointing at it are unaffected.

## Custom AttributeConverters for complex columns

For a column type Hibernate doesn't map natively — a `Locale`, a `Map<String, Object>` stored as JSON —
write a JPA `AttributeConverter` rather than serializing it ad hoc in application code:

```java
@Converter
public class LocaleAttributeConverter implements AttributeConverter<Locale, String> {

    @Override
    public String convertToDatabaseColumn(Locale locale) {
        return locale == null ? null : locale.toLanguageTag();
    }

    @Override
    public Locale convertToEntityAttribute(String dbData) {
        if (dbData == null) return Locale.ENGLISH;
        try {
            return Locale.forLanguageTag(dbData);
        } catch (IllformedLocaleException e) {
            return Locale.ENGLISH; // fall back rather than fail the whole entity load
        }
    }
}
```

For a JSON column, combine `@Convert` with `@JdbcTypeCode(SqlTypes.JSON)` (Hibernate 6):

```java
@Convert(converter = MapStringObjectConverter.class)
@JdbcTypeCode(SqlTypes.JSON)
private Map<String, Object> metadata;
```

Apply the converter on the field with `@Convert(converter = LocaleAttributeConverter.class)`, and give
it a sensible fallback value (as above, `Locale.ENGLISH`) rather than throwing and failing the whole
entity load over one malformed value — a `@ColumnDefault` on the column is a reasonable second line of
defense for the same default at the database level.

## Plain Java beans, not records, not Lombok

Entities are classic Java beans: a no-args constructor (required by Hibernate to instantiate the entity
via reflection before populating fields), an all-args constructor for convenience, and plain
getters/setters. No Lombok, no records. Records are reserved for DTOs (see `dto`/`response-modeling`) —
an entity's mutability and Hibernate's reflection-based instantiation are exactly what a record's
immutable, canonical-constructor-only shape is unsuited for.

## Further reference

`references/separate-model-module.md` — the optional pattern of publishing entities from a separately
versioned Maven module instead of keeping them inside the backend, for projects with more than one
consumer of the same data model.
```

- [ ] **Step 3: Verify frontmatter and content markers**

```bash
f=plugins/micronaut-standards/skills/entity-design/SKILL.md
grep -q '^name: entity-design$' "$f" && echo "OK: name field"
grep -q 'AttributeConverter' "$f" && echo "OK: converter pattern documented"
grep -q 'internal primary key' "$f" && echo "OK: internal-vs-external ID pattern documented"
grep -q 'No Lombok, no records' "$f" && echo "OK: plain-bean rule stated"
grep -q 'references/separate-model-module.md' "$f" && echo "OK: points to separate-model-module reference"
```

Expected: five `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/micronaut-standards/skills/entity-design/SKILL.md
git commit -m "feat: add entity-design skill"
```

---

### Task 7: `entity-design/references/separate-model-module.md`

**Files:**
- Create: `plugins/micronaut-standards/skills/entity-design/references/separate-model-module.md`

**Interfaces:**
- Consumes: `plugins/micronaut-standards/skills/entity-design/SKILL.md` (Task 6) links here.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/micronaut-standards/skills/entity-design/references/separate-model-module.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
# Optional pattern: entities in a separately published model module

SKILL.md covers the default case: entities live inside the backend module, under `database/entity/`.
Vulpes-Backend uses a different pattern instead — its entities (e.g. `FontEntity`) live in a separately
versioned and published Maven artifact (`net.onelitefeather:vulpes-model`), consumed by the backend via
the private OneLiteFeather Maven repo like any other dependency:

```kotlin
// settings.gradle.kts version catalog
library("vulpes.api", "net.onelitefeather", "vulpes-model").versionRef("vulpes.model")
```

```kotlin
// build.gradle.kts
dependencies {
    implementation(libs.vulpes.api)
}
```

```java
import net.onelitefeather.vulpes.api.model.FontEntity;
```

## When this is worth the extra effort

Adopt a separate model module only when the entity/model shapes genuinely need to be shared with more
than one consumer beyond the backend itself — e.g. a Minecraft plugin or CLI client that needs to
deserialize the same data structures the backend persists. The module then becomes the one place both
sides depend on, instead of the client hand-maintaining a parallel copy of the same shapes that can
silently drift out of sync.

## The trade-offs

- **Independent versioning and a publish pipeline are now required** for the model module itself — it
  needs its own `release-please`/version bump cadence (see the `release-engineering` plugin) separate
  from the backend's own release cadence, and a `gradle-publish.yml`-style CI job.
- **A change to an entity now means two PRs** (or at least two review cycles) instead of one — a PR to
  the model module, published, then a PR in the backend bumping the dependency version — unless the
  backend and model module are deliberately kept in the same monorepo with a project-local dependency
  instead of a published one (which then reintroduces the "not actually separate" question).
- **Cross-referencing project-local resources gets harder**: a repository interface (`FooRepository`)
  and the annotation-processor-generated Micronaut Data implementation still need to live in the module
  that also depends on the JPA/Hibernate stack — decide upfront whether the model module holds just the
  plain entity classes (JPA-annotated, but no repositories) or the full persistence layer, since mixing
  "shared model" and "persistence implementation" in the same published artifact usually forces every
  consumer (including a lightweight client that only wants the DTOs' shape) to pull in JPA/Hibernate as
  a transitive dependency it doesn't need.

## Decision rule

Default to keeping entities in the backend module (SKILL.md's main pattern). Reach for a separate
published model module only when a second, independently-deployed consumer of the exact same data
shapes already exists or is concretely planned — not speculatively, in case one might exist later.
```

- [ ] **Step 3: Verify content markers**

```bash
f=plugins/micronaut-standards/skills/entity-design/references/separate-model-module.md
grep -q 'vulpes-model' "$f" && echo "OK: real Vulpes-Backend example present"
grep -q 'Independent versioning and a publish pipeline' "$f" && echo "OK: trade-offs documented"
grep -q '## Decision rule' "$f" && echo "OK: decision rule present"
```

Expected: three `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/micronaut-standards/skills/entity-design/references/separate-model-module.md
git commit -m "feat: add entity-design separate-model-module reference"
```

---

### Task 8: `configuration/SKILL.md`

**Files:**
- Create: `plugins/micronaut-standards/skills/configuration/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/micronaut-standards/skills/configuration/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
---
name: configuration
description: OneLiteFeather's convention for typed application configuration in a Micronaut REST API — one @ConfigurationProperties class per functional area in a dedicated config/ package, instead of ad-hoc properties scattered across the application entry point. Use this whenever a Micronaut backend needs a new piece of externalized configuration (a feature flag, an external service URL, a limit/threshold) and you're deciding where the corresponding Java type should live.
---

# Configuration

External configuration (`application.yml` values, environment-specific settings) is exposed to the rest
of the application through dedicated `@ConfigurationProperties` classes in a `config/` package — never
attached ad hoc to the application entry point class.

## One class per functional area

```java
// config/FontStorageConfiguration.java
@ConfigurationProperties("font-storage")
public record FontStorageConfiguration(
        @NotBlank String basePath,
        @Positive int maxUploadSizeBytes
) {
}
```

```yaml
# application.yml
font-storage:
  base-path: /var/lib/otis/fonts
  max-upload-size-bytes: 5242880
```

Each functional area (font storage, external API credentials, feature flags) gets its own
`@ConfigurationProperties` class with its own prefix, injected wherever it's needed via constructor
injection like any other bean:

```java
@Singleton
public class FontServiceImpl implements FontService {

    private final FontStorageConfiguration storageConfig;

    @Inject
    public FontServiceImpl(FontStorageConfiguration storageConfig) {
        this.storageConfig = storageConfig;
    }
}
```

Do not create one large configuration class that maps the entire `application.yml` — that class has no
single responsibility and becomes a dumping ground every unrelated feature adds a field to. If two
configuration values are read by unrelated parts of the codebase, they belong in two separate
`@ConfigurationProperties` classes, even if they happen to live under the same `application.yml`
top-level key today.

## Anti-pattern: configuration on the application entry point

Do not attach `@ConfigurationProperties` directly to the `@Singleton`/`Application` bootstrap class the
way `public class OtisApplication { public static void main(...) { ... } }` did in Otis. The application
entry point's only job is starting Micronaut; it should not also double as a configuration holder that
unrelated services then depend on.

## Records over fields-and-setters

Prefer a record for the configuration class body (as in the example above) over a plain class with
fields and setters, wherever Micronaut's binding supports it (it does, via the record's canonical
constructor) — it keeps the class immutable and removes the boilerplate of writing setters that only
Micronaut itself ever calls.
```

- [ ] **Step 3: Verify frontmatter and content markers**

```bash
f=plugins/micronaut-standards/skills/configuration/SKILL.md
grep -q '^name: configuration$' "$f" && echo "OK: name field"
grep -q '@ConfigurationProperties("font-storage")' "$f" && echo "OK: dedicated config class example present"
grep -q 'Anti-pattern: configuration on the application entry point' "$f" && echo "OK: anti-pattern documented"
grep -q 'Records over fields-and-setters' "$f" && echo "OK: record-preference guidance present"
```

Expected: four `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/micronaut-standards/skills/configuration/SKILL.md
git commit -m "feat: add configuration skill"
```

---

### Task 9: `dto/SKILL.md`

**Files:**
- Create: `plugins/micronaut-standards/skills/dto/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: cross-references to `response-modeling` (Task 10) and `openapi` (Task 11) — naming matches
  only, no code dependency.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/micronaut-standards/skills/dto/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
---
name: dto
description: OneLiteFeather's request-DTO conventions for Micronaut REST APIs — records with @Serdeable/@Introspected, one shared Create/Update DTO controlled by JSR-380 validation groups instead of separate DTO types per action, and entity conversion methods living on the DTO itself. Use this whenever adding a new request body type to a Micronaut controller. For the response side (success/error modeling), see the response-modeling skill; for endpoint-level OpenAPI documentation, see openapi — this skill covers only the incoming request DTO and its own field-level @Schema annotations.
---

# Request DTOs

A request DTO is a Java record, annotated `@Serdeable` (Micronaut Serde, for JSON (de)serialization) and
`@Introspected` (Micronaut bean introspection, needed for validation to work without reflection at
runtime). It lives in `domain/<feature>/`, alongside the response DTOs from the `response-modeling`
skill.

## One shared DTO for Create and Update, via validation groups

Rather than a separate `CreateFooDTO`/`UpdateFooDTO` pair, one DTO serves both actions, with JSR-380
validation groups deciding which fields are required for which action:

```java
package net.onelitefeather.otis.domain.font;

import net.onelitefeather.otis.validation.ValidationGroup.Create;
import net.onelitefeather.otis.validation.ValidationGroup.Update;

@Schema
@Serdeable
public record FontModelDTO(
        @Schema(description = "ID of the font model", requiredMode = Schema.RequiredMode.NOT_REQUIRED)
        @Null(groups = Create.class)
        @NotNull(groups = Update.class)
        UUID id,

        @Schema(description = "Display name for the UI", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(groups = {Create.class, Update.class})
        String uiName,

        @Schema(description = "The path to the texture", requiredMode = Schema.RequiredMode.REQUIRED)
        @NotBlank(groups = {Create.class, Update.class})
        String texturePath
) {
    public @NotNull FontEntity toFontModel() {
        return new FontEntity(id, uiName, texturePath);
    }
}
```

The marker interfaces live in a shared `validation` package, next to the DTOs that use them:

```java
package net.onelitefeather.otis.validation;

public interface ValidationGroup {
    interface Create { }
    interface Update { }
}
```

The controller (see `routing`) triggers the right group per action:

```java
@Post
@Validated(groups = ValidationGroup.Create.class)
public HttpResponse<FontModelResponseDTO> add(@Body FontModelDTO item) { /* ... */ }

@Put("/{id}")
@Validated(groups = ValidationGroup.Update.class)
public HttpResponse<FontModelResponseDTO> update(@Body FontModelDTO item) { /* ... */ }
```

The `id` field is a good example of why groups matter here: it must be absent (`@Null`) on create — the
server assigns it — and present (`@NotNull`) on update — the client must say which record it's updating.
A single DTO with groups expresses this without two near-duplicate record types that would drift apart
over time as fields get added to one and forgotten on the other.

## Conversion lives on the DTO, not the entity, not a separate mapper

A request DTO owns its own `toXxxEntity()` conversion method (as `toFontModel()` above) — never on the
entity (see `entity-design`, which explicitly keeps entities free of anything but persistence concerns),
and never in a standalone `FooMapper` class. The DTO already knows its own field-to-constructor mapping;
introducing a third class whose only job is to repeat that knowledge adds a file with no independent
reason to change on its own.

## Field-level `@Schema` annotations belong here

`@Schema(description = ..., requiredMode = ...)` on each field documents the field for OpenAPI. This is
this skill's responsibility, not `openapi`'s — `openapi` covers the endpoint-level `@Operation`/
`@ApiResponse` documentation on the controller/`*Api` interface, while the DTO documents its own shape
once, reused by every endpoint that consumes or returns it.
```

- [ ] **Step 3: Verify frontmatter and content markers**

```bash
f=plugins/micronaut-standards/skills/dto/SKILL.md
grep -q '^name: dto$' "$f" && echo "OK: name field"
grep -q 'ValidationGroup.Create' "$f" && grep -q 'ValidationGroup.Update' "$f" && echo "OK: validation groups shown"
grep -q 'toFontModel' "$f" && echo "OK: DTO-owned conversion method example present"
grep -q 'never on the entity' "$f" && grep -q 'never in a standalone' "$f" && echo "OK: anti-pattern (entity/mapper) explicit"
grep -q 'Field-level `@Schema`' "$f" && echo "OK: @Schema field-annotation scope documented"
```

Expected: five `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/micronaut-standards/skills/dto/SKILL.md
git commit -m "feat: add dto skill"
```

---

### Task 10: `response-modeling/SKILL.md`

**Files:**
- Create: `plugins/micronaut-standards/skills/response-modeling/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks (self-contained, cross-references `dto`, `openapi`,
  `exception-handling` by name only).
- Produces: the `ErrorResponse` interface name and `FooResponseDTO`/`FooErrorDTO` naming convention that
  Task 12 (`openapi`) and Task 13 (`exception-handling`) reference by name — the exact type names
  (`ErrorResponse`, `ErrorResponseDTO`) must match what those tasks use.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/micronaut-standards/skills/response-modeling/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
---
name: response-modeling
description: OneLiteFeather's sealed-interface response-DTO pattern for Micronaut REST APIs — a per-resource sealed interface with a success record and an error record, both implementing a shared org-wide ErrorResponse marker interface, plus static createDTO(entity) factory methods for entity-to-DTO conversion. Use this whenever defining what a controller endpoint returns. This replaces returning a raw String or null on failure, and replaces a generic RFC-7807-style problem-detail format — for the request-DTO side, see the dto skill; for how the global exception handler uses the same ErrorResponse type, see exception-handling; for how these types get referenced in @ApiResponse schemas, see openapi.
---

# Response modeling

Every resource's response type is a `sealed interface` with exactly two implementations: a success
record and an error record. This gives every endpoint a type-safe way to express "either the data, or a
specific error" instead of returning `null`, a raw `String` error message, or throwing for cases that are
really just "not found."

## The pattern

```java
package net.onelitefeather.otis.domain.font;

@Serdeable
public sealed interface FontModelResponseDTO {

    @Schema(name = "ResponseFontModelDTO", description = "Font model data")
    @Serdeable
    record FontModelDTO(
            @Schema(description = "The id of the model", requiredMode = Schema.RequiredMode.REQUIRED) UUID id,
            @Schema(description = "Display name for the UI", requiredMode = Schema.RequiredMode.REQUIRED) String uiName,
            @Schema(description = "The path to the texture", requiredMode = Schema.RequiredMode.REQUIRED) String texturePath
    ) implements FontModelResponseDTO {

        public static FontModelDTO createDTO(FontEntity entity) {
            return new FontModelDTO(entity.getId(), entity.getUiName(), entity.getTexturePath());
        }
    }

    @Schema(name = "ResponseFontModelErrorDTO", description = "Error message")
    @Serdeable
    record FontModelErrorDTO(
            @Schema(description = "Error message") String errorMessage
    ) implements FontModelResponseDTO, ErrorResponse {
    }
}
```

## The shared `ErrorResponse` marker

Every resource's error record additionally implements one shared, org-wide `ErrorResponse` interface,
so callers (and the global exception handler — see `exception-handling`) can work with "an error
response" as a single type regardless of which resource produced it:

```java
package net.onelitefeather.otis.domain.error;

public interface ErrorResponse {

    @Schema(description = "Error message")
    String errorMessage();

    @Schema(description = "Error message")
    @Serdeable
    record ErrorResponseDTO(
            @Schema(description = "Error message") String errorMessage
    ) implements ErrorResponse {
    }
}
```

`ErrorResponseDTO` is the default/generic error shape, used by the global exception handler (see
`exception-handling`) for unexpected failures. A resource-specific error record like `FontModelErrorDTO`
is used instead when the controller/service already knows exactly what went wrong (e.g. "font not
found") and wants that reflected in its own OpenAPI schema rather than the generic one.

## Static factory methods do the entity-to-DTO conversion

`createDTO(entity)` (and, where a projection needs extra data, additional named factories like
`createDTOWithChars(entity)`) live as static methods on the success record — the mirror image of the
`toXxxEntity()` instance method on the request DTO (see `dto`). This keeps entity↔DTO conversion
entirely inside the `domain/<feature>/` package, with the service layer (see `service-layer`) as the
caller on both sides, never the owner of the conversion logic itself.

## Why this instead of RFC 7807 problem-detail

A generic `type`/`title`/`status`/`detail`/`instance` problem-detail body was considered and rejected in
favor of this sealed-interface pattern: it gives each endpoint a precise, resource-specific OpenAPI
schema per status code (see `openapi`) instead of one generic error shape reused everywhere, and it lets
a controller react to a failure with `instanceof`/pattern matching on a concrete type instead of parsing
a generic `detail` string.

```java
FontModelResponseDTO result = fontService.deleteFont(id);
if (result instanceof FontModelResponseDTO.FontModelErrorDTO) {
    return HttpResponse.notFound(result);
}
return HttpResponse.ok(result);
```
```

- [ ] **Step 3: Verify frontmatter and content markers**

```bash
f=plugins/micronaut-standards/skills/response-modeling/SKILL.md
grep -q '^name: response-modeling$' "$f" && echo "OK: name field"
grep -q 'sealed interface FontModelResponseDTO' "$f" && echo "OK: sealed interface example present"
grep -q 'implements FontModelResponseDTO, ErrorResponse' "$f" && echo "OK: error record implements both interfaces"
grep -q 'interface ErrorResponse' "$f" && grep -q 'record ErrorResponseDTO' "$f" && echo "OK: shared ErrorResponse marker documented"
grep -q 'createDTO(FontEntity entity)' "$f" && echo "OK: static factory conversion documented"
grep -q 'instanceof FontModelResponseDTO.FontModelErrorDTO' "$f" && echo "OK: pattern-matching usage example present"
```

Expected: six `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/micronaut-standards/skills/response-modeling/SKILL.md
git commit -m "feat: add response-modeling skill"
```

---

### Task 11: `openapi/SKILL.md`

**Files:**
- Create: `plugins/micronaut-standards/skills/openapi/SKILL.md`

**Interfaces:**
- Consumes: the `FontModelResponseDTO`/`FontModelErrorDTO` names from `response-modeling` (Task 10) —
  reused verbatim in this skill's example so the two skills' examples visibly agree with each other.
- Produces: the `FontApi`/`FontController` split that Task 12 (`routing`) and Task 13
  (`exception-handling`) reference by name.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/micronaut-standards/skills/openapi/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
---
name: openapi
description: OneLiteFeather's OpenAPI documentation convention for Micronaut REST APIs — a doc-only *Api interface per controller carrying @Operation/@ApiResponse (never routing annotations), operationId/tags naming, @ApiResponse schemas referencing the response-modeling skill's success/error records, and enabling Swagger UI/Rapidoc/OpenAPI Explorer. Use this whenever documenting a Micronaut controller endpoint. Routing annotations (@Controller, @Get/@Post/etc.) and validation triggers stay on the controller class itself — see the routing skill for those; this skill covers documentation only.
---

# OpenAPI documentation

Every controller has an accompanying `*Api` interface, in the same `controller/<feature>/` package, that
carries **only** OpenAPI annotations. The controller implements the interface and supplies routing
(`@Controller`, `@Get`/`@Post`/etc. — see `routing`) plus the method body; the interface never routes,
it only documents.

## The `*Api` interface pattern

```java
// controller/font/FontApi.java — documentation only, no routing, no @Body/@PathVariable binding needed
public interface FontApi {

    @Operation(
            summary = "Get a font by ID",
            operationId = "getFontById",
            description = "Gets a font by ID from the database.",
            tags = {"Font"}
    )
    @ApiResponse(
            responseCode = "200",
            description = "The font was successfully retrieved from the database.",
            content = @Content(
                    mediaType = MediaType.APPLICATION_JSON,
                    schema = @Schema(implementation = FontModelResponseDTO.FontModelDTO.class)
            )
    )
    @ApiResponse(
            responseCode = "404",
            description = "The font was not found in the database.",
            content = @Content(
                    mediaType = MediaType.APPLICATION_JSON,
                    schema = @Schema(implementation = FontModelResponseDTO.FontModelErrorDTO.class)
            )
    )
    HttpResponse<FontModelResponseDTO> getById(UUID id);
}
```

```java
// controller/font/FontController.java — routing + logic, implements FontApi
@Controller("/font")
public class FontController implements FontApi {

    private final FontService fontService;

    @Inject
    public FontController(FontService fontService) {
        this.fontService = fontService;
    }

    @Override
    @Get("/{id}")
    @Produces(MediaType.APPLICATION_JSON)
    public HttpResponse<FontModelResponseDTO> getById(@PathVariable UUID id) {
        return fontService.findFontById(id)
                .map(entity -> HttpResponse.ok((FontModelResponseDTO) FontModelResponseDTO.FontModelDTO.createDTO(entity)))
                .orElseGet(() -> HttpResponse.notFound(new FontModelResponseDTO.FontModelErrorDTO("Font not found")));
    }
}
```

Micronaut's OpenAPI annotation processor and its routing engine both read the full type hierarchy of a
controller class — annotations on an interface the class implements are picked up the same as if they
were declared directly on the class. This is what makes the split safe: `@Operation`/`@ApiResponse` on
`FontApi` still end up in the generated OpenAPI document, with zero duplication needed on
`FontController`.

## `operationId` and `tags` naming

- `operationId`: camelCase verb + noun, matching the method name (`getFontById`, `addFont`,
  `deleteFont`) — this becomes the generated client SDK's method name in any OpenAPI-codegen consumer,
  so it should read the same as the Java method it documents.
- `tags`: one tag per resource/domain (`"Font"`, `"Item"`), used to group endpoints in the generated
  Swagger UI — not per HTTP verb, not per module.

## `@ApiResponse` per actual status code

Document every status code the endpoint can actually return, and only those — no blanket `200` with no
`404`/`400` entries when the method can in fact return them. Reference the success/error records from
`response-modeling` in the `schema = @Schema(implementation = ...)` attribute, one `@ApiResponse` block
per status code, exactly as in the `getById` example above.

## Enabling the interactive documentation UIs

```kotlin
tasks {
    compileJava {
        options.forkOptions.jvmArgs = listOf(
            "-Dmicronaut.openapi.views.spec=rapidoc.enabled=true,openapi-explorer.enabled=true,swagger-ui.enabled=true,swagger-ui.theme=flattop"
        )
    }
}
```

This is a recommended developer convenience (serves Swagger UI, Rapidoc, and OpenAPI Explorer from the
running application in dev/staging), not something that changes the generated OpenAPI document itself.
```

- [ ] **Step 3: Verify frontmatter and content markers**

```bash
f=plugins/micronaut-standards/skills/openapi/SKILL.md
grep -q '^name: openapi$' "$f" && echo "OK: name field"
grep -q 'public interface FontApi' "$f" && echo "OK: Api interface example present"
grep -q 'class FontController implements FontApi' "$f" && echo "OK: controller implements Api interface"
grep -q '@Get("/{id}")' "$f" && grep -qv 'FontApi' <<<"$(grep -A1 'interface FontApi' "$f")" ; grep -c '@Get' "$f" | grep -q '^1$' && echo "OK: routing annotation appears only on the controller"
grep -q 'operationId.*camelCase' "$f" && echo "OK: operationId naming rule stated"
grep -q 'micronaut.openapi.views.spec' "$f" && echo "OK: Swagger UI/Rapidoc activation documented"
```

Expected: five `OK:` lines (the fourth check's grep-count assertion is the load-bearing one for the
routing/doc split — confirm manually that `@Get`/`@Post`/`@Controller` appear only inside the
`FontController` code block, never inside the `FontApi` code block, since that separation is the whole
point of this skill).

- [ ] **Step 4: Commit**

```bash
git add plugins/micronaut-standards/skills/openapi/SKILL.md
git commit -m "feat: add openapi skill"
```

---

### Task 12: `routing/SKILL.md`

**Files:**
- Create: `plugins/micronaut-standards/skills/routing/SKILL.md`

**Interfaces:**
- Consumes: the `FontController`/`FontApi` split established in `openapi` (Task 11) — this skill's
  examples must stay consistent with that split (routing annotations on the controller only).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/micronaut-standards/skills/routing/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
---
name: routing
description: OneLiteFeather's HTTP routing conventions for Micronaut REST API controllers — resource-based paths with real HTTP verbs instead of action URLs, blocking HttpResponse<T> as the standard return type, and the Pageable/Page pagination convention. Use this whenever adding a new endpoint or reviewing a controller's @Controller/@Get/@Post/@Put/@Delete usage. For where OpenAPI documentation for the same endpoint goes, see openapi; for the global exception handler, see exception-handling — this skill covers routing and pagination only.
---

# HTTP routing

Controllers use resource-based paths with the HTTP verb that actually matches the operation — never an
action encoded into the URL path with every operation using the same verb.

## Real HTTP verbs, not action URLs

```java
// Correct
@Controller("/font")
public class FontController implements FontApi {

    @Override
    @Post
    public HttpResponse<FontModelResponseDTO> add(@Body FontModelDTO item) { /* ... */ }

    @Override
    @Get("/{id}")
    public HttpResponse<FontModelResponseDTO> getById(@PathVariable UUID id) { /* ... */ }

    @Override
    @Put("/{id}")
    public HttpResponse<FontModelResponseDTO> update(@PathVariable UUID id, @Body FontModelDTO item) { /* ... */ }

    @Override
    @Delete("/{id}")
    public HttpResponse<FontModelResponseDTO> remove(@PathVariable UUID id) { /* ... */ }
}
```

```java
// Wrong — action encoded in the path, verb doesn't match the operation
@Post("/update/{id}")
public HttpResponse<FontModelResponseDTO> update(@PathVariable UUID id, @Body FontModelDTO item) { /* ... */ }

@Post("/delete/{id}")
public HttpResponse<FontModelResponseDTO> remove(@PathVariable UUID id) { /* ... */ }
```

`/update/{id}` and `/delete/{id}` via `@Post` both work mechanically, but they throw away the
information the HTTP verb itself already carries — a caller (or an API gateway, or a cache) can no
longer tell a mutating call from a read just by looking at the verb.

## Blocking `HttpResponse<T>` as the standard return type

Every endpoint returns `HttpResponse<T>` synchronously — no `Mono<T>`, `Flux<T>`, or `Publisher<T>`
return types, unless a specific, documented reason requires the reactive model for one endpoint (e.g.
streaming a genuinely unbounded response body). The blocking model is simpler to reason about, test, and
debug, and matches every other convention in this plugin (the service layer, `dto`/`response-modeling`)
which are themselves synchronous.

## `@Controller` base path and resource naming

`@Controller("/font")` at the class level, with the resource name singular or plural depending on
whether the endpoints operate on a collection (`/fonts`, `GET` returns a page) or a single resource
addressed by ID (`/font/{id}`) — pick one convention per resource and keep it consistent across all of
that resource's endpoints; don't mix `/font/{id}` for reads with `/fonts/{id}` for writes on the same
resource.

## Pagination: `Pageable`/`Page<T>`

```java
@Override
@Get(uris = {"/"})
@Produces(MediaType.APPLICATION_JSON)
public HttpResponse<Page<FontModelResponseDTO.FontModelDTO>> getAll(Pageable pageable) {
    Page<FontModelResponseDTO.FontModelDTO> page = fontService.getAllFonts(pageable);
    return HttpResponse.ok(page);
}
```

Micronaut Data's `Pageable` as a method parameter and `Page<T>` as (part of) the return type is the
standard shape for any endpoint that returns a collection — the caller controls `page`/`size`/`sort` via
query parameters Micronaut binds automatically, with no manual parsing. Documenting the pagination
envelope's own OpenAPI schema is the `openapi` skill's job, not this one's.
```

- [ ] **Step 3: Verify frontmatter and content markers**

```bash
f=plugins/micronaut-standards/skills/routing/SKILL.md
grep -q '^name: routing$' "$f" && echo "OK: name field"
grep -q '@Put("/{id}")' "$f" && grep -q '@Delete("/{id}")' "$f" && echo "OK: real-HTTP-verb example present"
grep -q '/update/{id}' "$f" && grep -qi 'Wrong' "$f" && echo "OK: action-URL anti-pattern shown"
grep -q 'no `Mono<T>`, `Flux<T>`, or `Publisher<T>`' "$f" && echo "OK: blocking-response rule stated"
grep -q 'Pageable pageable' "$f" && echo "OK: pagination convention documented"
```

Expected: five `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/micronaut-standards/skills/routing/SKILL.md
git commit -m "feat: add routing skill"
```

---

### Task 13: `exception-handling/SKILL.md`

**Files:**
- Create: `plugins/micronaut-standards/skills/exception-handling/SKILL.md`

**Interfaces:**
- Consumes: the `ErrorResponse`/`ErrorResponseDTO` types from `response-modeling` (Task 10) — this
  skill's `ExceptionHandlerAdvice` example must return exactly this type.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/micronaut-standards/skills/exception-handling/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
---
name: exception-handling
description: OneLiteFeather's global exception-handling convention for Micronaut REST APIs — exactly one org-wide ExceptionHandlerAdvice that maps exception types to the correct HTTP status code and returns the shared ErrorResponse type from response-modeling, plus dedicated domain exception classes instead of generic RuntimeExceptions. Use this whenever adding a new failure case a Micronaut backend needs to report, or reviewing an existing global exception handler that maps everything to one status code. This is an explicit correction of a mapping-everything-to-404 pattern seen in an early reference implementation — status-code mapping by exception type is mandatory.
---

# Global exception handling

Every Micronaut backend has exactly one global exception handler, mapping exception types to the HTTP
status code that actually matches the failure — never a single status code for every exception.

## One handler, mapped by exception type

```java
package net.onelitefeather.otis.exception;

@Produces
@Singleton
public class ExceptionHandlerAdvice implements ExceptionHandler<Throwable, HttpResponse<ErrorResponse>> {

    @Override
    public HttpResponse<ErrorResponse> handle(HttpRequest request, Throwable exception) {
        if (exception instanceof ConstraintViolationException || exception instanceof jakarta.validation.ValidationException) {
            return HttpResponse.badRequest(new ErrorResponse.ErrorResponseDTO(exception.getMessage()));
        }
        if (exception instanceof EntityNotFoundException) {
            return HttpResponse.notFound(new ErrorResponse.ErrorResponseDTO(exception.getMessage()));
        }
        return HttpResponse.serverError(new ErrorResponse.ErrorResponseDTO("An unexpected error occurred."));
    }
}
```

**This is an explicit correction, not an incidental design choice**: an early reference implementation's
global handler returned `HttpResponse.notFound(...)` unconditionally for every `Throwable`, regardless of
what actually went wrong. That is wrong even though it compiles and "handles" every exception — a
validation failure and an unexpected NPE are not the same situation, and reporting both as 404 actively
misleads whoever (a human, a client's retry logic) is reading the status code. Every new exception type
this handler needs to cover gets its own `if`/`instanceof` branch (or a `switch` pattern-matching on
sealed exception types, where Java version support allows it) mapped to the status code that matches it,
with `serverError()` (500) reserved for the genuinely-unexpected fallthrough case, not the default for
everything.

## Domain exceptions get their own classes

```java
package net.onelitefeather.otis.exception;

public class EntityNotFoundException extends RuntimeException {
    public EntityNotFoundException(String message) {
        super(message);
    }
}
```

Throw a specific, named exception (`EntityNotFoundException`, or a more specific subtype per resource if
warranted) from the service layer (see `service-layer`) for expected failure cases the global handler
needs to distinguish — not a bare `new RuntimeException("font not found")`. The global handler's
`instanceof` checks are only meaningful if the exception types they check for actually carry that
meaning in their name and type, not just their message string.

## Relationship to `response-modeling`'s per-resource error records

This global handler is the fallback for exceptions that escape a controller/service method entirely.
Where a controller already knows exactly what went wrong (e.g. `getById` not finding a row), returning
a resource-specific error record like `FontModelErrorDTO` directly from the controller (see the `openapi`
and `response-modeling` skills' `getById` example) is preferred over throwing and letting this handler
catch it — throwing is for the cases a controller method didn't and shouldn't need to anticipate inline.
Both paths return the same `ErrorResponse` abstraction, so a client parses errors the same way regardless
of which path produced one.
```

- [ ] **Step 3: Verify frontmatter and content markers**

```bash
f=plugins/micronaut-standards/skills/exception-handling/SKILL.md
grep -q '^name: exception-handling$' "$f" && echo "OK: name field"
grep -q 'implements ExceptionHandler<Throwable, HttpResponse<ErrorResponse>>' "$f" && echo "OK: handler signature matches response-modeling's ErrorResponse type"
grep -q 'unconditionally for every' "$f" && echo "OK: explicit correction of always-404 pattern documented"
grep -q 'class EntityNotFoundException extends RuntimeException' "$f" && echo "OK: dedicated domain exception example present"
grep -q 'not a bare `new RuntimeException' "$f" && echo "OK: anti-pattern (generic RuntimeException) stated"
```

Expected: five `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/micronaut-standards/skills/exception-handling/SKILL.md
git commit -m "feat: add exception-handling skill"
```

---

### Task 14: `security/SKILL.md`

**Files:**
- Create: `plugins/micronaut-standards/skills/security/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/micronaut-standards/skills/security/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
---
name: security
description: OneLiteFeather's Micronaut Security baseline for REST APIs — deny-by-default access control with explicit per-endpoint @Secured annotations. Use this whenever adding a new controller endpoint and deciding who is allowed to call it, or when reviewing an existing endpoint that has no @Secured annotation at all. This is a foundational, prescriptive baseline rather than a pattern lifted from an existing reference codebase — neither of this plugin's two source repos has a security layer at all, which is itself the gap this skill exists to close. Does not cover a full auth/identity scheme (JWT issuance, OAuth2 flows, roles) — see this skill's own "Out of scope" note.
---

# Security baseline: deny by default

Every Micronaut backend enables Micronaut Security and configures it to deny access by default — an
endpoint is locked down unless it explicitly opts out of that default. This is the opposite of the
common failure mode of adding security "later" once a public-facing deployment forces the question,
which almost always means auditing every existing endpoint retroactively instead of every new endpoint
having to justify why it's open.

## Enabling the deny-by-default baseline

```yaml
# application.yml
micronaut:
  security:
    enabled: true
    intercept-url-map-uses-security-rule: true
```

With Micronaut Security enabled and no further per-endpoint configuration, every controller method is
rejected with `401 Unauthorized` by default — nothing is reachable until it's explicitly annotated.

## Opening an endpoint explicitly with `@Secured`

```java
@Controller("/font")
public class FontController implements FontApi {

    @Override
    @Get("/{id}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<FontModelResponseDTO> getById(@PathVariable UUID id) { /* ... */ }
}
```

For a genuinely public endpoint (health checks, a public read-only listing), open it explicitly and
narrowly rather than disabling security for the whole controller:

```java
@Override
@Get(uris = {"/"})
@Secured(SecurityRule.IS_ANONYMOUS)
public HttpResponse<Page<FontModelResponseDTO.FontModelDTO>> getAll(Pageable pageable) { /* ... */ }
```

`@Secured` can be placed at the class level (applies to every method that doesn't override it) or the
method level (overrides the class-level value for that one method) — prefer the most restrictive
sensible default at the class level, with individual methods opting into something looser
(`IS_ANONYMOUS`) only where that's a deliberate, reviewed decision, never as an oversight from a missing
annotation.

## Deciding which endpoints get opened, and how

Ask, for each endpoint: does this need to be reachable without authentication at all (`IS_ANONYMOUS`),
does it need any authenticated caller regardless of role (`IS_AUTHENTICATED`), or does it need a specific
role/permission (a custom `@Secured("ROLE_ADMIN")`-style value, once the project defines its own roles)?
Document the answer as the `@Secured` value itself — the annotation is the documentation; there should be
no endpoint where the answer to "who can call this" requires reading application-wide security
configuration to figure out.

## Out of scope

This skill establishes the deny-by-default baseline and the `@Secured` convention only. It does not cover
issuing or validating JWTs, configuring an OAuth2/OIDC provider, or designing a role/permission model —
those are project-specific decisions that depend on what identity provider (if any) a given backend
integrates with, and belong in that project's own documentation once decided.
```

- [ ] **Step 3: Verify frontmatter and content markers**

```bash
f=plugins/micronaut-standards/skills/security/SKILL.md
grep -q '^name: security$' "$f" && echo "OK: name field"
grep -q 'micronaut:\s*$' "$f" || grep -q 'security:' "$f" && echo "OK: deny-by-default yaml config present"
grep -q 'SecurityRule.IS_AUTHENTICATED' "$f" && grep -q 'SecurityRule.IS_ANONYMOUS' "$f" && echo "OK: both Secured examples present"
grep -q '## Out of scope' "$f" && echo "OK: out-of-scope note present"
```

Expected: four `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/micronaut-standards/skills/security/SKILL.md
git commit -m "feat: add security skill"
```

---

### Task 15: `liquibase/SKILL.md`

**Files:**
- Create: `plugins/micronaut-standards/skills/liquibase/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: a cross-reference to `testcontainers` (Task 16) — naming match only.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/micronaut-standards/skills/liquibase/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
---
name: liquibase
description: OneLiteFeather's mandatory Liquibase database-migration convention for Micronaut REST APIs — always XML changelogs (never YAML/SQL/JSON), the master-changelog-plus-versioned-files structure, and why this replaces Hibernate's hbm2ddl.auto=update. Use this whenever a Micronaut backend needs a schema change, or when reviewing a project still relying on hbm2ddl.auto=update for schema management. For verifying a changelog actually works against both MariaDB and PostgreSQL, see the testcontainers skill.
---

# Liquibase: database migrations

Every schema change to a Micronaut backend's database goes through a Liquibase changelog. Hibernate's
`hbm2ddl.auto=update` is never used for anything beyond a throwaway local prototype — it has no
migration history, no rollback, and silently diverges between environments that started from different
schema versions.

## Always XML, never YAML/SQL/JSON

```xml
<!-- db/changelog/changes/001-create-font-table.xml -->
<databaseChangeLog xmlns="http://www.liquibase.org/xml/ns/dbchangelog"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog
                        http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.29.xsd">

    <changeSet id="001-create-font-table" author="theEvilReaper">
        <createTable tableName="font">
            <column name="id" type="uuid">
                <constraints primaryKey="true" nullable="false"/>
            </column>
            <column name="ui_name" type="varchar(255)">
                <constraints nullable="false"/>
            </column>
            <column name="texture_path" type="varchar(1024)">
                <constraints nullable="false"/>
            </column>
        </createTable>
    </changeSet>
</databaseChangeLog>
```

XML is the only accepted changelog format at OneLiteFeather — never YAML, SQL, or JSON changelogs, even
though Liquibase supports all four. Liquibase's abstract change types (`createTable`, `addColumn`,
`addForeignKeyConstraint`, and so on) are the most consistently dialect-neutral in XML: the same
changelog runs unchanged against both MariaDB and PostgreSQL, because Liquibase itself translates each
abstract change type into the right SQL dialect at execution time. Raw SQL changelogs make that
translation the author's job instead, per statement, per dialect.

## When an abstract change type doesn't exist

Reach for `<sql>` only when no abstract change type covers what's needed, and scope it to the specific
dialect it's needed for using the `dbms` attribute — never a bare `<sql>` block assumed to work
everywhere:

```xml
<changeSet id="002-add-generated-column" author="theEvilReaper">
    <sql dbms="postgresql">
        ALTER TABLE font ADD COLUMN search_vector tsvector GENERATED ALWAYS AS (to_tsvector('english', ui_name)) STORED;
    </sql>
    <sql dbms="mariadb">
        ALTER TABLE font ADD COLUMN search_vector TEXT GENERATED ALWAYS AS (ui_name) VIRTUAL;
    </sql>
</changeSet>
```

## Structure: master changelog + versioned files

```
db/changelog/
├── db.changelog-master.xml
└── changes/
    ├── 001-create-font-table.xml
    └── 002-add-generated-column.xml
```

```xml
<!-- db/changelog/db.changelog-master.xml -->
<databaseChangeLog xmlns="http://www.liquibase.org/xml/ns/dbchangelog" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    xsi:schemaLocation="http://www.liquibase.org/xml/ns/dbchangelog http://www.liquibase.org/xml/ns/dbchangelog/dbchangelog-4.29.xsd">
    <include file="changes/001-create-font-table.xml" relativeToChangelogFile="true"/>
    <include file="changes/002-add-generated-column.xml" relativeToChangelogFile="true"/>
</databaseChangeLog>
```

One `changeSet` per functional change, with `id` and `author` set on every one — both are mandatory,
since Liquibase uses the `(id, author, filename)` triple to track which changesets have already run
against a given database.

## Micronaut integration

```kotlin
dependencies {
    implementation(mn.liquibase)
}
```

```yaml
# application.yml
liquibase:
  datasources:
    default:
      change-log: classpath:db/changelog/db.changelog-master.xml
```

Micronaut runs pending changesets against the configured datasource at application startup, before the
rest of the application context finishes initializing.

## Rollback

Add `<rollback>` elements (or rely on Liquibase's automatic rollback for change types simple enough to
auto-generate one, like `createTable`) rather than treating every migration as forward-only and
untested:

```xml
<changeSet id="002-add-generated-column" author="theEvilReaper">
    <sql dbms="postgresql">ALTER TABLE font ADD COLUMN search_vector tsvector;</sql>
    <rollback>
        <sql dbms="postgresql">ALTER TABLE font DROP COLUMN search_vector;</sql>
    </rollback>
</changeSet>
```

`<preConditions>` (e.g. `columnExists`/`tableExists` checks) are the other tool for making a changeset
safe to re-run or safe against a database that's already partway migrated by hand.

## Cross-DB verification

Whether a changelog genuinely works against both MariaDB and PostgreSQL is verified by actually running
it against both in tests, not by inspection — see the `testcontainers` skill for the container setup
that does this.
```

- [ ] **Step 3: Verify frontmatter and content markers**

```bash
f=plugins/micronaut-standards/skills/liquibase/SKILL.md
grep -q '^name: liquibase$' "$f" && echo "OK: name field"
grep -q 'Always XML, never YAML/SQL/JSON' "$f" && echo "OK: XML-only rule stated as its own heading"
grep -q 'dbms="postgresql"' "$f" && grep -q 'dbms="mariadb"' "$f" && echo "OK: per-dialect sql fallback example present"
grep -q 'db.changelog-master.xml' "$f" && echo "OK: master-changelog structure documented"
grep -q '<rollback>' "$f" && echo "OK: rollback convention documented"
grep -q 'the `testcontainers` skill' "$f" && echo "OK: cross-reference to testcontainers present"
```

Expected: six `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/micronaut-standards/skills/liquibase/SKILL.md
git commit -m "feat: add liquibase skill"
```

---

### Task 16: `testcontainers/SKILL.md`

**Files:**
- Create: `plugins/micronaut-standards/skills/testcontainers/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks (cross-references `liquibase` by name only).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/micronaut-standards/skills/testcontainers/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
---
name: testcontainers
description: OneLiteFeather's mandatory Testcontainers integration-test convention for Micronaut REST APIs — MariaDB and PostgreSQL containers via micronaut-test-resources, JUnit 5 lifecycle conventions, and the boundary between unit tests (no container) and integration tests (container required). Use this whenever writing a repository, migration, or controller integration test for a Micronaut backend, or reviewing a project that still relies on an embedded H2 database as its only test strategy.
---

# Testcontainers: integration testing against real databases

Every Micronaut backend's integration tests run against real MariaDB and PostgreSQL instances via
Testcontainers — never against an embedded H2 database standing in for "a database" in general. H2's SQL
dialect and behavior diverge from both real targets in exactly the ways that matter for catching a
migration or query bug before production does.

## Dependencies

```kotlin
dependencies {
    testImplementation(mn.testcontainers.core)
    testImplementation(mn.testcontainers.mariadb)
    testImplementation(mn.testcontainers.postgresql)
    testImplementation(mn.micronaut.test.resources.extensions.core)
    testImplementation(mn.micronaut.test.resources.extensions.junit.platform)
}
```

`micronaut-test-resources` manages the container lifecycle automatically per test run — a test class
doesn't need to manually start/stop a container or wire its JDBC URL into `application-test.yml` by hand;
Micronaut's test-resources service starts the right container on demand and injects its connection
properties.

## JUnit 5 lifecycle

```java
@MicronautTest
class FontRepositoryTest {

    @Inject
    FontRepository fontRepository;

    @Test
    void savesAndFindsAFont() {
        FontEntity saved = fontRepository.save(new FontEntity(null, "Test Font", "textures/test.png"));
        assertThat(fontRepository.findById(saved.getId())).isPresent();
    }
}
```

With `micronaut-test-resources` on the test classpath, `@MicronautTest` is enough — no explicit
`@Testcontainers`/`@Container` annotations are needed for the common case, since test-resources handles
container startup/teardown itself. Reach for manual `@Testcontainers`/`@Container` management only for a
test that needs direct control over the container instance (e.g. asserting against a container's own
logs, or deliberately restarting it mid-test) rather than the default managed lifecycle.

Containers are reused across test classes within the same test run by default — avoid forcing a fresh
container per test class (e.g. via a per-class-unique container label) unless a test genuinely needs
total isolation from every other test's data, since that multiplies test suite runtime for no benefit in
the common case.

## Verifying a Liquibase changelog against both dialects

```java
@MicronautTest(environments = "mariadb")
class LiquibaseMariaDbTest {
    @Test
    void changelogAppliesCleanly(DataSource dataSource) throws Exception {
        // schema is already migrated by the time the Micronaut context starts;
        // assert against the resulting schema/data here.
    }
}

@MicronautTest(environments = "postgresql")
class LiquibasePostgresTest {
    @Test
    void changelogAppliesCleanly(DataSource dataSource) throws Exception {
        // same assertions, against the PostgreSQL-backed context
    }
}
```

Running the same test logic under both a `mariadb` and a `postgresql` Micronaut environment (each
resolving to its own Testcontainers-backed datasource) is how a Liquibase changelog's cross-DB claim
(see the `liquibase` skill) gets actually verified, rather than assumed from reading the XML.

## Unit tests vs. integration tests

- **Unit test**: exercises a service's business logic with a mocked repository (no container, no
  database, no Micronaml application context needed) — fast, and the default choice for anything that
  isn't itself testing persistence or wiring.
- **Integration test**: exercises a repository, a Liquibase migration, or a full controller request
  end-to-end — needs a real container, via the setup above.

Don't reach for a container-backed test to verify pure business logic that a mocked-repository unit test
would cover just as well, and don't reach for a mocked-repository unit test to verify that a query or a
migration actually behaves correctly against a real database — each has a job the other can't do.
```

- [ ] **Step 3: Verify frontmatter and content markers**

```bash
f=plugins/micronaut-standards/skills/testcontainers/SKILL.md
grep -q '^name: testcontainers$' "$f" && echo "OK: name field"
grep -q 'mn.testcontainers.mariadb' "$f" && grep -q 'mn.testcontainers.postgresql' "$f" && echo "OK: both container dependencies present"
grep -q 'micronaut-test-resources' "$f" && echo "OK: test-resources managed-lifecycle convention documented"
grep -q 'environments = "mariadb"' "$f" && grep -q 'environments = "postgresql"' "$f" && echo "OK: cross-DB verification example present"
grep -q '## Unit tests vs. integration tests' "$f" && echo "OK: unit-vs-integration boundary documented"
```

Expected: five `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/micronaut-standards/skills/testcontainers/SKILL.md
git commit -m "feat: add testcontainers skill"
```

---

### Task 17: `logging/SKILL.md`

**Files:**
- Create: `plugins/micronaut-standards/skills/logging/SKILL.md`

**Interfaces:**
- Consumes: nothing from other tasks (cross-references `dependency-management` and `observability` by
  name only).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/micronaut-standards/skills/logging/SKILL.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create the file**

```markdown
---
name: logging
description: OneLiteFeather's logging conventions for Micronaut REST APIs — one SLF4J logger per class with no exceptions, structured JSON logging with OpenTelemetry trace/span correlation, log-level guidelines, and what must never be logged (PII, secrets, full request bodies). Use this whenever adding a new class that should log something, or reviewing an existing controller/service for inconsistent logging. For the Gradle dependencies and the metrics/tracing infrastructure this logging setup correlates with, see dependency-management and observability.
---

# Logging

Every controller and service implementation class has its own SLF4J logger — no class silently has no
logger just because nobody added one when the class was created.

## One logger per class, no exceptions

```java
public class FontServiceImpl implements FontService {

    private static final Logger LOGGER = LoggerFactory.getLogger(FontServiceImpl.class);

    @Override
    public FontModelResponseDTO.FontModelDTO createFont(FontModelDTO fontModelDTO) {
        LOGGER.info("Creating font '{}'", fontModelDTO.uiName());
        FontEntity saved = fontRepository.save(fontModelDTO.toFontModel());
        LOGGER.debug("Persisted font with id {}", saved.getId());
        return FontModelResponseDTO.FontModelDTO.createDTO(saved);
    }
}
```

`private static final Logger LOGGER = LoggerFactory.getLogger(<ThisClass>.class);` at the top of every
controller and service-impl class — an inconsistency where some controllers log and neighboring ones
don't makes production incidents harder to diagnose for no reason other than an omission when the class
was written.

## Structured JSON logging + trace correlation

The Gradle dependencies for the Logstash JSON encoder and the OpenTelemetry MDC appender are covered in
`dependency-management`/`observability`; this skill covers when and how to use the result. With the
appender configured, every log line automatically carries the current `trace_id`/`span_id` from
OpenTelemetry (see `observability`) when one is active — logs and traces correlate in whatever log
aggregation tool (e.g. Grafana Loki) ingests them, with no manual MDC-setting code needed in application
classes. Switch between structured JSON and plain-text console output via an environment variable
(commonly `LOG_JSON=true`/`false`), driven by a Logback `<if>`/`<then>`/`<else>` conditional — plain text
for local development readability, JSON in any environment with a log aggregator behind it.

## Log-level guidelines

- **`debug`** — detail useful while actively developing/troubleshooting a specific code path (e.g. an
  intermediate value), not left enabled by default in production.
- **`info`** — a business-meaningful event happened (a resource was created/updated/deleted, a scheduled
  job ran) — one line per meaningful event, not one line per method call.
- **`warn`** — something recoverable but unexpected happened (a fallback was used, a retry occurred, an
  external call was slow) — worth a human's attention if it happens often, not worth paging anyone.
- **`error`** — something failed and the failure is visible to a caller or corrupts state — pairs with
  the `exception-handling` skill's global handler, which is a reasonable place to log at `error` for the
  server-error (500) branch specifically, not for every branch (a 404 from a normal not-found case is not
  an `error`-level event).

## What must never be logged

Never log personally identifiable information, secrets/credentials/tokens, or a full request body that
might contain sensitive fields (passwords, tokens, payment details) — log identifiers (a UUID, a
username) instead of the sensitive value itself, and log a request's shape/summary rather than its raw
body when the body could contain something sensitive.
```

- [ ] **Step 3: Verify frontmatter and content markers**

```bash
f=plugins/micronaut-standards/skills/logging/SKILL.md
grep -q '^name: logging$' "$f" && echo "OK: name field"
grep -q 'private static final Logger LOGGER' "$f" && echo "OK: one-logger-per-class example present"
grep -q 'trace_id' "$f" && grep -q 'LOG_JSON' "$f" && echo "OK: structured logging + trace correlation documented"
grep -q '## Log-level guidelines' "$f" && echo "OK: log-level guidance present"
grep -q '## What must never be logged' "$f" && echo "OK: PII/secrets prohibition present"
```

Expected: five `OK:` lines.

- [ ] **Step 4: Commit**

```bash
git add plugins/micronaut-standards/skills/logging/SKILL.md
git commit -m "feat: add logging skill"
```

---

### Task 18: Plugin README and final plugin-wide verification

**Files:**
- Create: `plugins/micronaut-standards/README.md`

**Interfaces:**
- Consumes: every file from Tasks 1–17 (the README's package-layout table names every skill by name —
  all fourteen must already exist for the table to be accurate).
- Produces: nothing — this is the plan's closing task.

- [ ] **Step 1: Write a failing check**

```bash
test -f plugins/micronaut-standards/README.md && echo "UNEXPECTED" || echo "OK: missing as expected"
```

Expected: `OK: missing as expected`

- [ ] **Step 2: Create `plugins/micronaut-standards/README.md`**

```markdown
# micronaut-standards

OneLiteFeather's standard for Micronaut REST APIs — dependency management, architecture, and software
design, as fourteen small, independently-triggering skills. No MCP servers, no commands, pure skill
content (see `docs/superpowers/specs/2026-07-26-micronaut-standards-design.md` in this repo for the full
design rationale).

## Skills

| Skill | Covers |
|---|---|
| `dependency-management` | Micronaut Application/AOT Gradle plugins, version handling, CycloneDX. |
| `observability` | Micrometer/Prometheus, OpenTelemetry tracing, Kubernetes service discovery. |
| `service-layer` | Mandatory service interface + `impl`, constructor injection. |
| `entity-design` | JPA entity conventions, internal-vs-external ID, attribute converters. |
| `configuration` | Dedicated `@ConfigurationProperties` classes per concern. |
| `dto` | Request DTOs, validation groups, DTO-owned conversion. |
| `response-modeling` | Sealed-interface success/error response DTOs. |
| `openapi` | The doc-only `*Api` interface pattern, `@Operation`/`@ApiResponse`. |
| `routing` | Resource-based paths, real HTTP verbs, pagination. |
| `exception-handling` | The global exception handler, status-code mapping. |
| `security` | Deny-by-default `@Secured` baseline. |
| `liquibase` | XML-only changelogs, cross-DB-safe migrations. |
| `testcontainers` | MariaDB/PostgreSQL containers for integration tests. |
| `logging` | SLF4J conventions, structured JSON logging, log levels. |

## Package layout

A Micronaut REST API backend built to this standard is laid out feature-first:

```
src/main/java/.../
├── controller/<feature>/   # routing (routing) + *Api doc interface (openapi)
├── domain/<feature>/       # request DTOs (dto) + response DTOs (response-modeling)
├── domain/error/           # the shared ErrorResponse type (response-modeling)
├── service/                # service interfaces (service-layer)
├── service/impl/           # service implementations (service-layer)
├── database/entity/        # entities (entity-design)
├── config/                 # @ConfigurationProperties classes (configuration)
├── validation/             # ValidationGroup markers (dto)
└── exception/              # domain exceptions + the global handler (exception-handling)
```

Plus, outside `src/main/java`: `db/changelog/` (`liquibase`) and the Gradle/Testcontainers/observability
setup in `build.gradle.kts`/`settings.gradle.kts` (`dependency-management`, `observability`,
`testcontainers`).

## Install

```bash
/plugin install micronaut-standards@onelitefeather-claude-marketplace
```
```

- [ ] **Step 3: Verify the full directory structure matches the spec**

```bash
find plugins/micronaut-standards -type f | sort
```

Expected output (19 lines, exact set):

```
plugins/micronaut-standards/.antigravity-plugin/plugin.json
plugins/micronaut-standards/.claude-plugin/plugin.json
plugins/micronaut-standards/.codex-plugin/plugin.json
plugins/micronaut-standards/README.md
plugins/micronaut-standards/skills/configuration/SKILL.md
plugins/micronaut-standards/skills/dependency-management/SKILL.md
plugins/micronaut-standards/skills/dto/SKILL.md
plugins/micronaut-standards/skills/entity-design/SKILL.md
plugins/micronaut-standards/skills/entity-design/references/separate-model-module.md
plugins/micronaut-standards/skills/exception-handling/SKILL.md
plugins/micronaut-standards/skills/liquibase/SKILL.md
plugins/micronaut-standards/skills/logging/SKILL.md
plugins/micronaut-standards/skills/observability/SKILL.md
plugins/micronaut-standards/skills/openapi/SKILL.md
plugins/micronaut-standards/skills/response-modeling/SKILL.md
plugins/micronaut-standards/skills/routing/SKILL.md
plugins/micronaut-standards/skills/security/SKILL.md
plugins/micronaut-standards/skills/service-layer/SKILL.md
plugins/micronaut-standards/skills/testcontainers/SKILL.md
```

- [ ] **Step 4: Every SKILL.md has exactly `name` + `description` frontmatter, no more, no less**

```bash
for f in plugins/micronaut-standards/skills/*/SKILL.md; do
  fields=$(sed -n '2,/^---$/p' "$f" | sed '$d' | grep -c '^[a-z]*:')
  echo "$f: $fields top-level frontmatter field(s)"
done
```

Expected: `2 top-level frontmatter field(s)` for all fourteen files.

- [ ] **Step 5: No placeholder markers anywhere in the new content**

```bash
grep -rniE 'TBD|TODO|FIXME|fill in|placeholder for' plugins/micronaut-standards/ && echo "FAIL: placeholder found" || echo "OK: no placeholders"
```

Expected: `OK: no placeholders`. (The intentional example resource name `Font`/`Foo` used throughout is
not matched by this pattern and is expected to remain.)

- [ ] **Step 6: All three plugin manifests and `marketplace.json` are valid JSON**

```bash
for f in plugins/micronaut-standards/.claude-plugin/plugin.json \
         plugins/micronaut-standards/.codex-plugin/plugin.json \
         plugins/micronaut-standards/.antigravity-plugin/plugin.json \
         .claude-plugin/marketplace.json; do
  jq empty "$f" && echo "OK: $f valid" || echo "FAIL: $f invalid"
done
```

Expected: four `OK: ... valid` lines.

- [ ] **Step 7: Every cross-reference link inside the new skills resolves to a real file or a real skill name**

```bash
test -f plugins/micronaut-standards/skills/entity-design/references/separate-model-module.md && echo "OK: entity-design -> separate-model-module.md"
for skill in dependency-management observability service-layer entity-design configuration dto response-modeling openapi routing exception-handling security liquibase testcontainers logging; do
  test -d "plugins/micronaut-standards/skills/$skill" && echo "OK: skill directory exists: $skill" || echo "FAIL: missing skill directory: $skill"
done
```

Expected: one `OK: entity-design -> separate-model-module.md` line, then fourteen
`OK: skill directory exists: ...` lines, no `FAIL:` lines.

- [ ] **Step 8: `git status` is clean — every file from Tasks 1–17 was committed**

```bash
git status --short plugins/micronaut-standards/ .claude-plugin/marketplace.json README.md
```

Expected: empty output (except this task's own new `README.md`, which Step 9 below commits).

- [ ] **Step 9: Commit the plugin README**

```bash
git add plugins/micronaut-standards/README.md
git commit -m "feat: add micronaut-standards plugin README"
```

- [ ] **Step 10: Final clean-status check**

```bash
git status --short plugins/micronaut-standards/ .claude-plugin/marketplace.json README.md
```

Expected: empty output.
