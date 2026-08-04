# Plugin `micronaut-standards` — Design

## Purpose

A new Claude Code plugin that sets OneLiteFeather's binding standard for Micronaut REST APIs — from
dependency management to software architecture to software design. Like `minestom-knowledge` and
`release-engineering`, it is pure skill knowledge — no MCP servers, no commands, no agents.

Sources: the cloned repositories **Otis** (`OneLiteFeatherNET/Otis`, backend under `backend/`) and
**Vulpes-Backend** (`OneLiteFeatherNET/Vulpes-Backend`). Otis supplies the baseline conventions
(dependency management, DTO/entity separation, consistent OpenAPI annotation), but also shows
weaknesses (no service layer, no global exception handler, no security layer, duplicated validation,
almost no test coverage, `hbm2ddl.auto=update` instead of a migration tool). Vulpes-Backend is the
architecturally more mature reference (service interfaces with impl, sealed-interface response
modeling, global exception handler, validation groups, Testcontainers, CycloneDX) and supplies most of
the patterns for the final standard.

## Scope decisions (from brainstorming)

- **Otis as the base, weaknesses deliberately fixed** — the standard is normative, not a plain mirror
  of the current state. Where Otis or Vulpes-Backend themselves show weaknesses (e.g. Vulpes' global
  handler mapping every exception to 404), the standard explicitly corrects it rather than adopting it.
- **Knowledge skills only, no scaffolding commands.** Claude reads the skills and applies the
  conventions when writing code; there are no `/micronaut-standards:new-controller`-style commands.
- **Many small, isolated skills instead of a few large ones.** Each skill covers exactly one
  sub-topic, with a precise `description`, so a single topic (e.g. just Liquibase) triggers without
  pulling in the other skills. This split emerged iteratively during brainstorming: originally 3
  skills, then 9, finally **14** — each round split formerly bundled topics (architecture, DTOs, HTTP,
  dependency management) into standalone skills. Explicit user preference: "I love lots of small
  isolated skills."
- **No mandatory multi-module / separate model artifact pattern.** Vulpes-Backend sources its entities
  from a separately published library (`vulpes-model`). This is only documented as an optional,
  advanced pattern in a `references/` file of the `entity-design` skill. The default case keeps
  entities inside the backend module itself (like Otis).
- **Portable**: `.claude-plugin/`, `.codex-plugin/`, `.antigravity-plugin/` manifests like
  `minestom-knowledge`/`requirement-engineering` — pure knowledge with no Claude-Code-specific tool
  usage ports losslessly.
- **Documentation split out of the controller**: OpenAPI annotations (`@Operation`, `@ApiResponse`)
  move into an accompanying `*Api` interface. **Correction made during brainstorming:** routing
  annotations (`@Controller`, `@Get`/`@Post`/`@Put`/`@Delete`) and validation triggers (`@Validated`,
  `@Valid`) stay on the concrete controller class — only the documentation is extracted, not the
  routing.
- **Response modeling via sealed interface** (adopted from Vulpes-Backend) instead of the initially
  proposed RFC 7807 problem-detail format: per resource, a `sealed interface FooResponseDTO` with a
  success record and an error record that implements a shared `ErrorResponse` marker interface.
- **Validation groups instead of separate Create/Update DTOs**: one shared request DTO with
  `ValidationGroup.Create`/`Update` markers (adopted from Vulpes-Backend), no dedicated mapper class —
  conversion methods live on the respective DTO itself.
- **Liquibase instead of `hbm2ddl.auto=update`**, always XML changelogs (never YAML/SQL/JSON) as its
  own skill, so the same changelog runs unchanged against both MariaDB and PostgreSQL.
- **Testcontainers as its own skill**, the mandatory integration-test approach instead of a
  permanently embedded H2.
- **Further skill decomposition (final iteration):** `dependency-management` hands off its
  observability portion to a dedicated `observability` skill; the former catch-all `architecture`
  skill becomes three standalone skills (`service-layer`, `entity-design`, `configuration`); `dto`
  hands off its response modeling to a dedicated `response-modeling` skill; `http` becomes `routing`
  and `exception-handling`. The overall package-layout overview (which skill owns which package) lives
  centrally in the plugin `README.md` instead of in any single skill.

## Structure

```
plugins/micronaut-standards/
├── .claude-plugin/plugin.json
├── .codex-plugin/plugin.json
├── .antigravity-plugin/plugin.json
├── README.md
└── skills/
    ├── dependency-management/
    │   └── SKILL.md
    ├── observability/
    │   └── SKILL.md
    ├── service-layer/
    │   └── SKILL.md
    ├── entity-design/
    │   ├── SKILL.md
    │   └── references/
    │       └── separate-model-module.md
    ├── configuration/
    │   └── SKILL.md
    ├── dto/
    │   └── SKILL.md
    ├── response-modeling/
    │   └── SKILL.md
    ├── openapi/
    │   └── SKILL.md
    ├── routing/
    │   └── SKILL.md
    ├── exception-handling/
    │   └── SKILL.md
    ├── security/
    │   └── SKILL.md
    ├── liquibase/
    │   └── SKILL.md
    ├── testcontainers/
    │   └── SKILL.md
    └── logging/
        └── SKILL.md
```

`plugin.json` stays lean (no `mcpServers`, no `dependencies`), analogous to
`minestom-knowledge`/`release-engineering`. The `README.md` contains, besides the skill overview, the
package-layout diagram (`domain/<feature>/`, `controller/<feature>/`, `service/` + `service/impl/`,
`database/entity/`, `exception/`, `validation/`) with one line per package stating which skill owns it
— this is the only place that shows the whole picture, so no single skill has to carry that overview
burden. Registration happens as a new entry in `.claude-plugin/marketplace.json` (category
`productivity`, keywords including `micronaut`, `java`, `rest-api`, `openapi`, `liquibase`) plus a table
row + install code block in the root `README.md`, in the exact style of the existing plugin entries.

## Skill: `dependency-management`

**SKILL.md**:

- Micronaut Application plugin (`io.micronaut.application`) + AOT plugin (`io.micronaut.aot`) as the
  baseline; the Micronaut version is read solely from `gradle.properties`/the version catalog, never
  hardcoded in the skill — an instruction to Claude to verify the actual version in the target project
  instead of copying it from this skill (Otis' CLAUDE.md had a stale version number here, that must not
  repeat).
- Micronaut Platform Catalog plugin (`io.micronaut.platform.catalog`) for the `mn.*` version catalog;
  private Maven repo (`repo.onelitefeather.dev`) with a CI/local credential split.
- Cross-reference to `minestom-knowledge:gradle`/`boms` for the general OLF Gradle/BOM mechanics
  (private repo, Java toolchain pattern) — no duplication; this skill covers only the
  Micronaut-specific parts (AOT flags, `mn` catalog, annotation processing for Serde/Data/
  Validation/DI/OpenAPI).
- CycloneDX plugin (`org.cyclonedx.bom`) as a recommended, non-mandatory building block for SBOM
  generation.
- Comments in the build file explaining trade-off decisions (AOT flags, inert dependencies) are
  exemplary and adopted as a convention.
- Plain Gradle coordinates for observability, migrations, Testcontainers, and logging are not listed
  here — cross-reference to `observability`, `liquibase`, `testcontainers`, `logging`, each of which
  brings its own dependencies.

## Skill: `observability`

**SKILL.md** (formerly `references/observability-stack.md` under `dependency-management`, now
standalone):

- Micrometer + Prometheus (`mn.micronaut.management`, `mn.micronaut.micrometer.*`) as the metrics
  baseline.
- OpenTelemetry tracing for HTTP and JDBC (`mn.micronaut.tracing.opentelemetry.*`) — only activates
  when the `OTEL_TRACES_EXPORTER` environment variable is set (inert in local development without an
  exporter).
- Kubernetes service discovery (`mn.micronaut.kubernetes.discovery.client`) — inert outside k8s
  environments, requires RBAC (`read` on `services`/`endpoints`) in-cluster; still always included,
  justified by a build-file comment (convention from `dependency-management`).
- Boundary with `logging`: this skill covers metrics/tracing infrastructure, `logging` covers the
  actual log-usage conventions (including trace/log correlation).

## Skill: `service-layer`

**SKILL.md**:

- The service layer is mandatory — business logic never belongs in the controller (a deliberate
  departure from Otis' direct controller→repository access).
- Concretely as an interface + `impl` sub-package: `service/FooService.java` (interface) +
  `service/impl/FooServiceImpl.java` (implementation), analogous to `FontService`/`FontServiceImpl`
  from Vulpes-Backend.
- Constructor injection only (`@Inject` on the constructor), no field injection — applies org-wide to
  services, controllers, and all injectable beans.
- The service orchestrates repository access and DTO↔entity conversion (invoking the conversion methods
  that live on the DTOs themselves, see `dto`/`response-modeling`), but contains no persistence logic
  itself.

## Skill: `entity-design`

**SKILL.md**:

- `database/entity/` package: entities are a pure persistence layer, with **no** bean-validation
  annotations on the entity (the single source of truth for validation is the DTO, fixing Otis'
  duplicated validation).
- The "internal UUID separate from the business/external identifier" pattern (Otis' `OtisPlayer`: its
  own `@Id` UUID vs. an external `playerUuid`) is adopted.
- Custom `AttributeConverter`s for complex column types (e.g. `Locale`, JSON `Map`), combined with
  `@JdbcTypeCode(SqlTypes.JSON)` for JSON columns (a Hibernate 6 pattern from Otis).
- No Lombok, no records for entities (records are reserved for DTOs, see `dto`) — the classic Java
  bean pattern with a no-args and an all-args constructor, since Hibernate requires a no-args
  constructor.

**references/separate-model-module.md**: the Vulpes-Backend pattern (entities/models in a separately
versioned and published artifact, e.g. `vulpes-model`, consumed via the private Maven repo) as an
optional pattern for projects with multiple consumers (backend + Minecraft plugin/client). Includes the
trade-offs (needs its own versioning/publish pipeline) and a clear decision rule for when the extra
effort is worth it.

## Skill: `configuration`

**SKILL.md**:

- Dedicated `@ConfigurationProperties` classes per concern in the `config` package, instead of ad-hoc
  configuration attached directly to the application class (Otis' `OtisApplication` with
  `@ConfigurationProperties("application.properties")` attached directly is not a pattern to adopt).
- One configuration class per functional area (not one giant class for the whole `application.yml`),
  with a descriptive `@ConfigurationProperties("prefix")`.
- Constructor- or record-based configuration classes are preferred over field-plus-setter style
  wherever Micronaut allows it.

## Skill: `dto`

**SKILL.md**:

- Request DTOs are Java records with `@Serdeable` + `@Introspected`, in the `domain/<feature>/`
  package.
- One shared request DTO for create/update instead of separate types, controlled via JSR-380
  validation groups (`ValidationGroup.Create`/`Update` marker interfaces in the `validation` package),
  e.g. `@NotNull(groups = Update.class) @Null(groups = Create.class)` for a server-assigned field like
  the ID.
- **Conversion lives on the request DTO itself**, not on the entity and not in a separate mapper
  class: a `toXxxEntity()` instance method converts the DTO into the entity.
- `@Schema` field annotations (`description`, `requiredMode`) belong on the DTO itself; the
  controller/endpoint documentation (`@Operation`, `@ApiResponse`) is the concern of the `openapi`
  skill, and the response counterpart (success/error modeling) is the concern of `response-modeling` —
  both cross-referenced explicitly to avoid redundancy.

## Skill: `response-modeling`

**SKILL.md**:

- **Response DTO as a sealed interface**: per resource, a `sealed interface FooResponseDTO` with a
  success record (`FooDTO`, with `@Schema` field annotations) and an error record (`FooErrorDTO`).
- The error record additionally implements a shared `ErrorResponse` marker interface (with a default
  `ErrorResponseDTO`) from a central `domain/error` package — one type for all error responses
  org-wide, regardless of which resource is involved.
- Static `createDTO(entity)` factory methods on the response DTO (possibly several variants, e.g.
  `createDTOWithChars(entity)` for enriched projections) handle entity→DTO conversion — the
  counterpart to the `toXxxEntity()` method on the request DTO from the `dto` skill.
- Benefit: every status code gets a precise schema in the OpenAPI docs (see `openapi`), and the
  controller can react to error cases type-safely via `instanceof`/pattern matching instead of
  checking raw strings or `null`.
- Cross-reference to `exception-handling`: the global exception handler also returns `ErrorResponse` —
  the same error abstraction is used for expected (here) and unexpected (there) failure cases.

## Skill: `openapi`

**SKILL.md**:

- **`*Api` documentation-interface pattern**: per controller, an accompanying interface (e.g.
  `FontApi`) in the same `controller/<feature>/` package that carries exclusively `@Operation` and
  `@ApiResponse` annotations. The controller implements this interface. **Important:** routing
  (`@Controller`, `@Get`/`@Post`/...) and validation triggers stay on the controller class (see
  `routing`) — the interface documents only, it does not route.
- `operationId`/`tags` naming convention (camelCase verb+noun, e.g. `getFontById`; one tag per
  resource/domain).
- One `@ApiResponse` per status code that can actually occur, `schema = @Schema(implementation = ...)`
  referencing the success/error records from `response-modeling` (separated by status code).
- Enabling Swagger UI/Rapidoc/OpenAPI Explorer via the `-Dmicronaut.openapi.views.spec=...` JVM
  property as a recommended dev convenience (adopted from Vulpes-Backend).
- Example of the interface pattern:

  ```java
  // FontApi.java — documentation only
  public interface FontApi {
      @Operation(summary = "Get a font by ID", operationId = "getFontById", tags = {"Font"})
      @ApiResponse(responseCode = "200", content = @Content(schema = @Schema(implementation = FontModelResponseDTO.FontModelDTO.class)))
      @ApiResponse(responseCode = "404", content = @Content(schema = @Schema(implementation = FontModelResponseDTO.FontModelErrorDTO.class)))
      HttpResponse<FontModelResponseDTO> getById(UUID id);
  }

  // FontController.java — routing + logic
  @Controller("/font")
  public class FontController implements FontApi {
      @Override
      @Get("/{id}")
      @Produces(MediaType.APPLICATION_JSON)
      public HttpResponse<FontModelResponseDTO> getById(@PathVariable UUID id) { /* ... */ }
  }
  ```

## Skill: `routing`

**SKILL.md**:

- Resource-based paths with real HTTP verbs (`@Get`/`@Post`/`@Put`/`@Delete`) instead of action URLs
  like Otis' `/update/{id}` / `/delete/{id}` via `@Post` — an explicit correction.
- Blocking `HttpResponse<T>` as the default return type (no `Mono`/`Flux`/`Publisher`, unless
  justified).
- `Pageable`/`Page<T>` pagination convention (Otis' good pattern is adopted) as a method parameter or
  return type; documenting the pagination envelope in OpenAPI is the concern of the `openapi` skill.
- `@Controller("/base-path")` at the class level, consistent resource naming (plural vs. singular
  depending on collection vs. single resource).

## Skill: `exception-handling`

**SKILL.md**:

- A **global exception handler** (`ExceptionHandlerAdvice implements ExceptionHandler<Throwable,
  HttpResponse<ErrorResponse>>`) is mandatory — every backend has exactly one.
- **Correction relative to Vulpes-Backend:** the handler maps exception types to the appropriate
  status code (validation errors → 400, a domain not-found exception → 404, everything else → 500)
  instead of unconditionally returning `notFound()` for every exception.
- Domain exceptions get their own classes in the `exception` package (e.g.
  `EntityNotFoundException`), not generic `RuntimeException`s with a string message as the only error
  information.
- The return type is always `ErrorResponse` from the `response-modeling` skill — the same abstraction
  for both expected (handled in the controller) and unexpected (handled here, globally) failure cases.

## Skill: `security`

**SKILL.md**:

- Micronaut Security baseline "deny by default": every endpoint is implicitly locked down until
  explicitly opened.
- `@Secured` convention per endpoint/controller; explicitly opening individual routes is documented
  (e.g. `@Secured(SecurityRule.IS_ANONYMOUS)` for public endpoints).
- Since neither Otis nor Vulpes-Backend show a security layer, this skill is more prescriptive/
  foundational rather than derived from example code — it describes the baseline convention and the
  decision process (which endpoints may be open and why), not a complete auth scheme (JWT/OAuth
  configuration is deliberately out of scope, see "Out of scope").

## Skill: `liquibase`

**SKILL.md**:

- Liquibase is mandatory for every schema change, instead of `hbm2ddl.auto=update`.
- **Always XML changelogs**, never YAML/SQL/JSON — rationale: Liquibase's abstract change types
  (`createTable`, `addColumn`, `addForeignKeyConstraint`, ...) are most consistently dialect-neutral in
  XML. Raw `<sql>` is avoided, or only used with an explicit `dbms` attribute per dialect when no
  abstract change type exists.
- Structure: `db/changelog/db.changelog-master.xml` includes versioned individual files under
  `db/changelog/changes/<nnn>-<description>.xml`; one changeset per functional change, `id` + `author`
  mandatory.
- Micronaut integration: the `micronaut-liquibase` dependency, configuration in `application.yml` per
  data source/environment.
- `rollback` elements or `<preConditions>` where sensible, instead of untested forward-only
  migrations.
- Cross-DB verification (running the changelog against both MariaDB **and** PostgreSQL) is not
  described here — it refers to the `testcontainers` skill.

## Skill: `testcontainers`

**SKILL.md**:

- Testcontainers + `micronaut-test-resources` is the mandatory integration-test approach — replaces
  Otis' pattern of permanently including an H2 driver just so tests can run without a real database.
- Container setup for MariaDB and PostgreSQL in parallel, so a Liquibase changelog can be verified
  against both (cross-reference from the `liquibase` skill here).
- JUnit 5 lifecycle conventions (`@Testcontainers`/`@Container`, container reuse across test classes,
  avoiding unnecessary restarts).
- Boundary: pure unit tests (service logic with mocked repositories) don't need a container;
  repository/migration/controller integration tests do.

## Skill: `logging`

**SKILL.md**:

- SLF4J logger convention: one `private static final Logger` per class (controller, service impl), no
  class without a logger — fixes Otis' inconsistent usage (not every controller logged). The concrete
  Gradle dependencies for this live in the `dependency-management` skill (cross-reference).
- Structured JSON logging (Logstash encoder) + OpenTelemetry MDC appender for trace/span correlation —
  usage conventions (when to log structured vs. plain, how trace IDs end up in log lines); the
  underlying metrics/tracing infrastructure itself is the concern of the `observability` skill.
- Log-level guidelines: when `debug`/`info`/`warn`/`error` is appropriate.
- Explicit prohibition: never log PII, secrets, or full request bodies containing sensitive fields.

## Out of scope

- Scaffolding commands/code generators (`/micronaut-standards:new-controller` or similar) —
  deliberately not part of this plugin (user decision during brainstorming).
- Mandatory multi-module / separate model artifact setup — remains an optional pattern in a reference
  file (`entity-design`), not part of the core standard.
- A complete auth/identity scheme (JWT issuance, OAuth2 flows, role/permission model) — the `security`
  skill covers only the deny-by-default baseline and the `@Secured` convention, not a full auth system.
- Reactive programming model (`Mono`/`Flux`/`Publisher`) — the standard consistently uses blocking
  `HttpResponse<T>`; reactive alternatives are not covered.
- CI/CD conventions (Release Please, Renovate, reusable workflows) — the `release-engineering` plugin
  already exists for that; `micronaut-standards` refers to it where relevant instead of duplicating it.
