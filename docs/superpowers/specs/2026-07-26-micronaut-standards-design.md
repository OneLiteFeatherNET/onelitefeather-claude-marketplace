# Plugin `micronaut-standards` — Design

## Zweck

Ein neues Claude-Code-Plugin, das OneLiteFeathers verbindlichen Standard für Micronaut-REST-APIs setzt —
von Dependency-Verwaltung über Software-Architektur bis Software-Design. Wie `minestom-knowledge` und
`release-engineering` ist es reines Skill-Wissen — keine MCP-Server, keine Commands, keine Agents.

Quellen: die geklonten Repositories **Otis** (`OneLiteFeatherNET/Otis`, Backend unter `backend/`) und
**Vulpes-Backend** (`OneLiteFeatherNET/Vulpes-Backend`). Otis liefert die Grund-Konventionen
(Dependency-Management, DTO/Entity-Trennung, konsequente OpenAPI-Annotierung), zeigt aber auch
Schwachstellen (kein Service-Layer, kein globaler Exception-Handler, keine Security-Schicht, doppelte
Validierung, kaum Testabdeckung, `hbm2ddl.auto=update` statt Migrationstool). Vulpes-Backend ist die
architektonisch reifere Referenz (Service-Interfaces mit Impl, Sealed-Interface-Response-Modeling,
globaler Exception-Handler, Validation-Groups, Testcontainers, CycloneDX) und liefert den Großteil der
Muster für den finalen Standard.

## Scope-Entscheidungen (aus dem Brainstorming)

- **Otis als Basis, Schwachstellen bewusst beheben** — der Standard ist normativ, kein reines Abbild
  des Ist-Zustands. Wo Otis oder Vulpes-Backend selbst Schwächen zeigen (z. B. Vulpes' globaler
  Handler, der jede Exception auf 404 mappt), wird das im Standard explizit korrigiert, nicht
  übernommen.
- **Nur Wissens-Skills, keine Scaffolding-Commands.** Claude liest die Skills und wendet die
  Konventionen beim Schreiben von Code an; es gibt keine `/micronaut-standards:new-controller`-artigen
  Commands.
- **Viele kleine, isolierte Skills statt weniger großer.** Jedes Skill deckt genau ein Teilthema ab,
  mit präziser `description`, damit ein einzelnes Thema (z. B. nur Liquibase) triggert, ohne die
  anderen acht Skills mitzuladen. Diese Aufteilung entstand iterativ im Brainstorming (ursprünglich 3
  Skills, am Ende 9) und ist eine explizite Nutzerpräferenz.
- **Kein verpflichtendes Multi-Modul-/separates-Model-Artefakt-Muster.** Vulpes-Backend bezieht seine
  Entities aus einer separat published Library (`vulpes-model`). Das wird nur als optionales,
  fortgeschrittenes Muster in einer `references/`-Datei des `architecture`-Skills dokumentiert. Der
  Standardfall hält Entities im Backend-Modul selbst (wie Otis).
- **Portabel**: `.claude-plugin/`, `.codex-plugin/`, `.antigravity-plugin/` Manifeste wie bei
  `minestom-knowledge`/`requirement-engineering` — reines Wissen ohne Claude-Code-spezifische
  Tool-Nutzung lässt sich verlustfrei portieren.
- **Doku-Trennung im Controller**: OpenAPI-Annotationen (`@Operation`, `@ApiResponse`) wandern in ein
  begleitendes `*Api`-Interface. **Korrektur während des Brainstormings:** Routing-Annotationen
  (`@Controller`, `@Get`/`@Post`/`@Put`/`@Delete`) und Validation-Trigger (`@Validated`, `@Valid`)
  bleiben auf der konkreten Controller-Klasse — nur die Dokumentation wird ausgelagert, nicht das
  Routing.
- **Response-Modeling per Sealed Interface** (aus Vulpes-Backend übernommen) statt des zunächst
  vorgeschlagenen RFC-7807-Problem-Detail-Formats: pro Ressource ein `sealed interface FooResponseDTO`
  mit einem Erfolgs-Record und einem Fehler-Record, der ein gemeinsames `ErrorResponse`-Marker-Interface
  implementiert.
- **Validation-Groups statt separater Create-/Update-DTOs**: ein gemeinsames Request-DTO mit
  `ValidationGroup.Create`/`Update`-Markern (aus Vulpes-Backend übernommen), keine eigene
  Mapper-Klasse — Konvertierungsmethoden leben auf dem DTO selbst.
- **Liquibase statt `hbm2ddl.auto=update`**, immer XML-Changelogs (nie YAML/SQL/JSON) als eigener Skill,
  damit derselbe Changelog unverändert gegen MariaDB und PostgreSQL läuft.
- **Testcontainers als eigener Skill**, verbindlicher Integrationstest-Ansatz statt dauerhaft
  eingebundenem H2.

## Struktur

```
plugins/micronaut-standards/
├── .claude-plugin/plugin.json
├── .codex-plugin/plugin.json
├── .antigravity-plugin/plugin.json
├── README.md
└── skills/
    ├── dependency-management/
    │   ├── SKILL.md
    │   └── references/
    │       └── observability-stack.md
    ├── architecture/
    │   ├── SKILL.md
    │   └── references/
    │       └── separate-model-module.md
    ├── dto/
    │   └── SKILL.md
    ├── openapi/
    │   └── SKILL.md
    ├── http/
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

`plugin.json` bleibt schlank (kein `mcpServers`, keine `dependencies`), analog zu
`minestom-knowledge`/`release-engineering`. Registrierung erfolgt als neuer Eintrag in
`.claude-plugin/marketplace.json` (Kategorie `productivity`, Keywords u. a. `micronaut`, `java`,
`rest-api`, `openapi`, `liquibase`) sowie eine Tabellenzeile + Install-Codeblock in der Root-`README.md`,
im exakten Stil der bestehenden Plugin-Einträge.

## Skill: `dependency-management`

**SKILL.md**:

- Micronaut Application Plugin (`io.micronaut.application`) + AOT-Plugin (`io.micronaut.aot`) als
  Grundgerüst; Micronaut-Version einzig aus `gradle.properties`/dem Versionskatalog lesen, nie im Skill
  hardcoden — Anweisung an Claude, die tatsächliche Version im Zielprojekt zu prüfen, statt sie aus
  diesem Skill zu übernehmen (Otis' CLAUDE.md hatte hier eine veraltete Angabe, das darf sich nicht
  wiederholen).
- Micronaut Platform Catalog Plugin (`io.micronaut.platform.catalog`) für den `mn.*`-Versionskatalog;
  privates Maven-Repo (`repo.onelitefeather.dev`) mit CI/Local-Credential-Split.
- Querverweis auf `minestom-knowledge:gradle`/`boms` für die generelle OLF-Gradle-/BOM-Mechanik (privates
  Repo, Java-Toolchain-Pattern) — keine Duplizierung, dieser Skill beschreibt nur das
  Micronaut-Spezifische (AOT-Flags, `mn`-Catalog, Annotation-Processing für Serde/Data/Validation/DI/
  OpenAPI).
- CycloneDX-Plugin (`org.cyclonedx.bom`) als empfohlener, nicht verpflichtender Baustein für
  SBOM-Generierung.
- Kommentare im Build-File zur Begründung von Trade-off-Entscheidungen (AOT-Flags, inerte Dependencies
  wie Kubernetes-Discovery außerhalb von k8s) sind vorbildlich und werden als Konvention übernommen.
- Schema-Migration, Testcontainers und Logging-Dependencies werden nicht hier behandelt, sondern in den
  jeweils eigenen Skills (`liquibase`, `testcontainers`, `logging`) — dieser Skill listet nur, welche
  Gradle-Koordinaten dafür nötig sind, mit Verweis auf den zuständigen Skill für Nutzungskonventionen.

**references/observability-stack.md**: Micrometer/Prometheus, OpenTelemetry-Tracing (HTTP/JDBC),
Kubernetes-Service-Discovery (inert außerhalb k8s, RBAC-Voraussetzung) — die vollständigen
Gradle-Koordinaten und Aktivierungsbedingungen aus Otis/Vulpes-Backend.

## Skill: `architecture`

**SKILL.md**:

- Feature-orientiertes Package-Layout statt rein technischer Schichtung:
  `domain/<feature>/` (DTOs), `controller/<feature>/` (Controller + `*Api`-Interface),
  `service/` (Interfaces) + `service/impl/` (Implementierungen), `database/entity/` (Entities),
  `exception/` (globaler Handler), `validation/` (`ValidationGroup`).
- **Service-Layer ist verbindlich** — Business-Logik gehört nie in den Controller (bewusste Abkehr von
  Otis' Controller→Repository-Direktzugriff). Konkret als Interface + `impl`-Unterpaket, analog
  `FontService`/`FontServiceImpl` aus Vulpes-Backend.
- Constructor-Injection ausschließlich (`@Inject` auf dem Konstruktor), kein Field-Injection.
- Entities bleiben reine Persistenzschicht: keine Bean-Validation-Annotationen auf der Entity (Single
  Source of Truth für Validation ist das DTO, behebt Otis' doppelte Validierung); das Muster "interne
  UUID getrennt vom fachlichen/externen Identifier" (Otis' `OtisPlayer`) wird übernommen; Custom
  `AttributeConverter`s für komplexe Spaltentypen (z. B. `Locale`, JSON-Map) sind der Standardweg für
  Nicht-Primitive.
- Dedizierte `@ConfigurationProperties`-Klassen pro Fachbereich statt Ad-hoc-Konfiguration auf der
  Application-Klasse (Otis' `OtisApplication` mit direkt angehängten `@ConfigurationProperties` ist kein
  zu übernehmendes Muster).

**references/separate-model-module.md**: das Vulpes-Backend-Muster (Entities/Models in einem separat
versionierten und published Artefakt, z. B. `vulpes-model`, Konsum über das private Maven-Repo) als
optionales Muster für Projekte mit mehreren Konsumenten (Backend + Minecraft-Plugin/Client). Enthält
Trade-offs (eigene Versionierung/Publish-Pipeline nötig) und eine klare Entscheidungsregel, wann sich der
Mehraufwand lohnt.

## Skill: `dto`

**SKILL.md**:

- Request- und Response-DTOs sind Java Records mit `@Serdeable` + `@Introspected`.
- **Request-DTO**: ein gemeinsames DTO für Create/Update statt getrennter Typen, gesteuert über
  JSR-380-Validation-Groups (`ValidationGroup.Create`/`Update`-Marker-Interfaces im `validation`-Paket),
  z. B. `@NotNull(groups = Update.class) @Null(groups = Create.class)` für ein serverseitig vergebenes
  Feld wie die ID.
- **Response-DTO als Sealed Interface**: pro Ressource `sealed interface FooResponseDTO` mit einem
  Erfolgs-Record (`FooDTO`, mit `@Schema`-Feldannotationen) und einem Fehler-Record (`FooErrorDTO`), der
  zusätzlich ein gemeinsames `ErrorResponse`-Marker-Interface (mit Default-`ErrorResponseDTO`) aus einem
  zentralen `domain/error`-Paket implementiert. Damit bekommt jeder Statuscode in der OpenAPI-Doku ein
  präzises Schema, und der Controller kann typsicher per `instanceof`/Pattern-Matching auf Fehlerfälle
  reagieren.
- **Konvertierung lebt auf dem DTO**, nicht auf der Entity und nicht in einer separaten
  Mapper-Klasse: Request-DTO bekommt eine `toXxxEntity()`-Instanzmethode, Response-DTO bekommt statische
  `createDTO(entity)`-Factory-Methoden (ggf. mehrere Varianten, z. B. `createDTOWithChars(entity)` für
  angereicherte Projektionen).
- `@Schema`-Feldannotationen (`description`, `requiredMode`) gehören zum DTO selbst; die
  Controller-/Endpunkt-Dokumentation (`@Operation`, `@ApiResponse`) ist Sache des `openapi`-Skills —
  expliziter Querverweis, um Redundanz zu vermeiden.

## Skill: `openapi`

**SKILL.md**:

- **`*Api`-Doku-Interface-Pattern**: pro Controller ein begleitendes Interface (z. B. `FontApi`) im
  selben `controller/<feature>/`-Paket, das ausschließlich `@Operation`- und `@ApiResponse`-Annotationen
  trägt. Der Controller implementiert dieses Interface. **Wichtig:** Routing (`@Controller`, `@Get`/
  `@Post`/...) und Validation-Trigger bleiben auf der Controller-Klasse — das Interface dokumentiert nur,
  es routet nicht (Detail-Beispiel siehe unten).
- `operationId`/`tags`-Namenskonvention (camelCase Verb+Nomen, z. B. `getFontById`; ein Tag pro
  Ressource/Domain).
- `@ApiResponse` pro tatsächlich möglichem Statuscode, `schema = @Schema(implementation = ...)`
  referenziert die Sealed-Interface-DTOs aus dem `dto`-Skill (Erfolgs- und Fehler-Record getrennt nach
  Statuscode).
- Aktivierung von Swagger-UI/Rapidoc/OpenAPI-Explorer über die
  `-Dmicronaut.openapi.views.spec=...`-JVM-Property als empfohlene Dev-Convenience (aus Vulpes-Backend
  übernommen).
- Beispiel für das Interface-Pattern:

  ```java
  // FontApi.java — nur Dokumentation
  public interface FontApi {
      @Operation(summary = "Get a font by ID", operationId = "getFontById", tags = {"Font"})
      @ApiResponse(responseCode = "200", content = @Content(schema = @Schema(implementation = FontModelResponseDTO.FontModelDTO.class)))
      @ApiResponse(responseCode = "404", content = @Content(schema = @Schema(implementation = FontModelResponseDTO.FontModelErrorDTO.class)))
      HttpResponse<FontModelResponseDTO> getById(UUID id);
  }

  // FontController.java — Routing + Logik
  @Controller("/font")
  public class FontController implements FontApi {
      @Override
      @Get("/{id}")
      @Produces(MediaType.APPLICATION_JSON)
      public HttpResponse<FontModelResponseDTO> getById(@PathVariable UUID id) { /* ... */ }
  }
  ```

## Skill: `http`

**SKILL.md**:

- Ressourcenbasierte Pfade mit echten HTTP-Verben (`@Get`/`@Post`/`@Put`/`@Delete`) statt Action-URLs
  wie Otis' `/update/{id}` bzw. `/delete/{id}` per `@Post` — explizite Korrektur.
- Blockierendes `HttpResponse<T>` als Standard-Rückgabetyp (kein `Mono`/`Flux`/`Publisher`, außer
  begründete Ausnahme).
- `Pageable`/`Page<T>`-Pagination-Konvention (Otis' gutes Muster wird übernommen), inkl.
  OpenAPI-Dokumentation der Paginierungshülle im `openapi`-Skill.
- **Globaler Exception-Handler** (`ExceptionHandlerAdvice implements ExceptionHandler<Throwable,
  HttpResponse<ErrorResponse>>`) ist verbindlich. **Korrektur ggü. Vulpes-Backand:** Der Handler mappt
  Exception-Typen auf passende Statuscodes (Validierungsfehler → 400, fachliche
  Not-Found-Exception → 404, alles andere → 500) statt pauschal `notFound()` für jede Exception
  zurückzugeben. Rückgabetyp ist der `ErrorResponse`-Typ aus dem `dto`-Skill.

## Skill: `security`

**SKILL.md**:

- Micronaut-Security-Baseline "deny by default": jeder Endpunkt ist implizit gesperrt, bis er
  explizit geöffnet wird.
- `@Secured`-Konvention pro Endpunkt/Controller; explizites Öffnen einzelner Routen dokumentiert (z. B.
  `@Secured(SecurityRule.IS_ANONYMOUS)` für öffentliche Endpunkte).
- Da weder Otis noch Vulpes-Backend eine Security-Schicht zeigen, ist dieser Skill stärker
  präskriptiv/grundlegend statt aus Beispielcode abgeleitet — er beschreibt die Baseline-Konvention
  und den Entscheidungsprozess (welche Endpunkte dürfen offen sein und warum), nicht ein vollständiges
  Auth-Schema (JWT/OAuth-Konfiguration ist bewusst außerhalb des Scopes, siehe „Out of scope“).

## Skill: `liquibase`

**SKILL.md**:

- Liquibase ist verbindlich für jede Schemaänderung, statt `hbm2ddl.auto=update`.
- **Immer XML-Changelogs**, nie YAML/SQL/JSON — Begründung: Liquibases abstrakte Change-Types
  (`createTable`, `addColumn`, `addForeignKeyConstraint`, ...) sind in XML am konsequentesten
  dialektneutral. Rohes `<sql>` wird vermieden bzw. nur mit explizitem `dbms`-Attribut pro Dialekt
  eingesetzt, wenn kein abstrakter Change-Type existiert.
- Struktur: `db/changelog/db.changelog-master.xml` inkludiert versionierte Einzeldateien unter
  `db/changelog/changes/<nnn>-<beschreibung>.xml`; ein Changeset pro fachlicher Änderung, `id` + `author`
  verpflichtend gesetzt.
- Micronaut-Integration: `micronaut-liquibase`-Dependency, Konfiguration in `application.yml` je
  Datenquelle/Environment.
- `rollback`-Elemente bzw. `<preConditions>` wo sinnvoll, statt ungetesteter Vorwärts-only-Migrationen.
- Cross-DB-Verifikation (Changelog gegen MariaDB **und** PostgreSQL laufen lassen) wird nicht hier
  beschrieben, sondern verweist auf den `testcontainers`-Skill.

## Skill: `testcontainers`

**SKILL.md**:

- Testcontainers + `micronaut-test-resources` ist der verbindliche Integrationstest-Ansatz — löst
  Otis' Muster ab, dauerhaft einen H2-Treiber einzubinden, nur damit Tests ohne echte Datenbank laufen.
- Container-Setup für MariaDB und PostgreSQL parallel, damit ein Liquibase-Changelog gegen beide
  verifiziert werden kann (Querverweis vom `liquibase`-Skill hierher).
- JUnit5-Lifecycle-Konventionen (`@Testcontainers`/`@Container`, Container-Wiederverwendung zwischen
  Testklassen, Vermeidung unnötiger Neustarts).
- Abgrenzung: reine Unit-Tests (Service-Logik mit gemockten Repositories) brauchen keinen Container;
  Repository-/Migrations-/Controller-Integrationstests brauchen einen.

## Skill: `logging`

**SKILL.md**:

- SLF4J-Logger-Konvention: ein `private static final Logger` pro Klasse (Controller, Service-Impl),
  keine Klasse ohne Logger — behebt Otis' inkonsistente Nutzung (nicht jeder Controller loggt).
  Konkrete Gradle-Dependencies dafür stehen im `dependency-management`-Skill (Querverweis).
- Strukturiertes JSON-Logging (Logstash-Encoder) + OpenTelemetry-MDC-Appender für Trace/Span-Korrelation
  — Nutzungskonventionen (wann strukturiert vs. plain, wie Trace-IDs in Log-Zeilen landen).
- Log-Level-Richtlinien: wann `debug`/`info`/`warn`/`error` angemessen ist.
- Explizites Verbot: keine PII, Secrets oder vollständigen Request-Bodies mit sensiblen Feldern loggen.

## Out of scope

- Scaffolding-Commands/Codegeneratoren (`/micronaut-standards:new-controller` o. ä.) — bewusst nicht
  Teil dieses Plugins (Nutzerentscheidung im Brainstorming).
- Verpflichtendes Multi-Modul-/separates-Model-Artefakt-Setup — bleibt optionales Muster in einer
  Referenzdatei, nicht Teil des Kern-Standards.
- Vollständiges Auth-/Identity-Schema (JWT-Ausstellung, OAuth2-Flows, Rollen-/Berechtigungsmodell) — der
  `security`-Skill deckt nur die Deny-by-default-Baseline und `@Secured`-Konvention ab, kein komplettes
  Auth-System.
- Reactive Programmiermodell (`Mono`/`Flux`/`Publisher`) — der Standard setzt durchgängig auf
  blockierendes `HttpResponse<T>`, reaktive Alternativen werden nicht behandelt.
- CI/CD-Konventionen (Release-Please, Renovate, reusable Workflows) — dafür existiert bereits das
  `release-engineering`-Plugin; `micronaut-standards` verweist bei Bedarf dorthin, statt es zu
  duplizieren.
