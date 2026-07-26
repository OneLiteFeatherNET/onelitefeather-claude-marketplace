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
