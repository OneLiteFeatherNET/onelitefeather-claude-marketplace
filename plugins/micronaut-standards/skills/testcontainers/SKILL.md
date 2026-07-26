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
  database, no Micronaut application context needed) — fast, and the default choice for anything that
  isn't itself testing persistence or wiring.
- **Integration test**: exercises a repository, a Liquibase migration, or a full controller request
  end-to-end — needs a real container, via the setup above.

Don't reach for a container-backed test to verify pure business logic that a mocked-repository unit test
would cover just as well, and don't reach for a mocked-repository unit test to verify that a query or a
migration actually behaves correctly against a real database — each has a job the other can't do.
