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
