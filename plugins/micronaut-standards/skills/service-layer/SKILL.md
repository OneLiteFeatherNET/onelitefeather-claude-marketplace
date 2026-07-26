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
