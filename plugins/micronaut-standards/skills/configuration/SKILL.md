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
