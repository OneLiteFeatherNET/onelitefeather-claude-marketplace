# Final-review fix report — micronaut-standards plugin

Branch: `micronaut-standards-plugin`. All fixes applied directly to the affected `SKILL.md` files
under `plugins/micronaut-standards/skills/`. Frontmatter (`name`/`description`) left untouched in
every file.

## CRITICAL

**1. `observability/SKILL.md`** — Changed the `/metrics` YAML example from `sensitive: false` to
`sensitive: true`, and reworded the surrounding sentence so it no longer contradicts itself: it now
says the endpoint is enabled while staying marked `sensitive` so it remains behind the `security`
skill's deny-by-default baseline, instead of claiming that baseline while showing a config that
bypasses it.

## IMPORTANT

**2. Structured-logging dependency ownership** — Added a new "Structured logging dependencies"
subsection to `dependency-management/SKILL.md` (before "What lives in other skills, not here") with
the actual Gradle coordinates:
- `library("logstash.logback.encoder", "net.logstash.logback", "logstash-logback-encoder")`
- `library("opentelemetry.logback.mdc", "io.opentelemetry.instrumentation", "opentelemetry-logback-mdc-1.0")`
- `implementation(libs.logstash.logback.encoder)`, `implementation(libs.opentelemetry.logback.mdc)`,
  `runtimeOnly(libs.janino)`

Removed the now-incorrect "Structured logging dependencies ... — `logging`" bullet from that same
skill's "What lives in other skills, not here" list (dependency-management now owns them).
Changed `logging/SKILL.md`'s cross-reference to point only at `dependency-management` for the
coordinates (dropped the `observability` half of that pointer).

**3. Security dependency** — Added a "Dependencies" section near the top of `security/SKILL.md` with:
```kotlin
dependencies {
    annotationProcessor(mn.micronaut.security.annotations)
    implementation(mn.micronaut.security)
}
```
Added `- Micronaut Security dependencies for the deny-by-default baseline — security.` to
`dependency-management/SKILL.md`'s "What lives in other skills, not here" list.

**4. Validation triggers missing from `routing`** — Added `@Validated(groups = ValidationGroup.Create.class)`
to routing's `add` example and `@Validated(groups = ValidationGroup.Update.class)` to its `update`
example, matching `dto/SKILL.md`'s actual usage. Added a sentence to `routing/SKILL.md` stating that
validation-group triggers are set on the controller method alongside its routing annotation, with a
cross-reference to `dto` for the `ValidationGroup.Create`/`Update` marker interfaces.

**5. `FontEntity` field drift in `entity-design`** — Renamed the `provider` field/constructor
parameter to `texturePath` throughout the `FontEntity` example (field declaration, constructor
parameter, and constructor body assignment), matching `dto`, `response-modeling`, and
`testcontainers`'s use of `texturePath` for the same conceptual field. No other, genuinely distinct
`provider` field existed elsewhere in the file.

**6. `dto`'s `update` example missing `@PathVariable`** — Changed
`update(@Body FontModelDTO item)` to `update(@PathVariable UUID id, @Body FontModelDTO item)` in
`dto/SKILL.md`, matching `routing/SKILL.md`'s form and Micronaut's requirement that a `{id}` URI
variable be bound to a method parameter.

**7. `Throwable`-wide handler superseding built-ins** — Added a paragraph to
`exception-handling/SKILL.md` after the code example noting that registering a handler for
`Throwable` replaces Micronaut's own built-in per-type exception handlers (not just adds to them), so
status codes Micronaut normally derives automatically (e.g. `UnsatisfiedRouteException` → 400) need
their own explicit branch too — the three branches shown are not assumed exhaustive for a real
project.

## MINOR

**8.** `liquibase/SKILL.md`: `implementation(mn.liquibase)` → `implementation(mn.micronaut.liquibase)`,
matching the `mn.micronaut.<module>` alias pattern used everywhere else in the plugin.

**9.** `testcontainers/SKILL.md`: added a sentence clarifying that even with
`micronaut-test-resources` managing container lifecycle, the Testcontainers module dependencies
(`mn.testcontainers.mariadb`, `mn.testcontainers.postgresql`) still need to be on the test classpath
for test-resources to know which container images to manage.

**11.** `security/SKILL.md`: removed the non-existent `intercept-url-map-uses-security-rule: true`
line from the YAML example — `micronaut.security.enabled: true` alone is real and already sufficient
for the deny-by-default claim.

**13.** `dto/SKILL.md`: reworded the prose so it no longer separately promises `@Introspected` next
to `@Serdeable` — it now explains `@Serdeable` is itself meta-annotated with `@Introspected`, so no
separate annotation is needed on the example record (smaller edit than adding `@Introspected`
explicitly to the code block).

**15.** `exception-handling/SKILL.md`: changed `HttpRequest request` to `HttpRequest<?> request`, and
`jakarta.validation.ValidationException` to the unqualified `ValidationException`, so both types in
the `instanceof` expression are consistently unqualified.

## Left as-is (per instructions)

Findings #10, #12, #14 — parked, not touched.

## Verification

1. `grep -rn "Micronaml\|TBD\|TODO\|FIXME" plugins/micronaut-standards/` → no matches (clean).
2. `for f in plugins/micronaut-standards/skills/*/SKILL.md; do sed -n '2,/^---$/p' "$f" | sed '$d' | grep -c '^[a-z]*:'; done` → every one of the 14 files prints `2` (frontmatter untouched).
