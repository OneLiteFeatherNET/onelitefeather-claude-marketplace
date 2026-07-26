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

A request DTO owns its own `toXxxEntity()` conversion method (as `toFontModel()` above) — never on the entity (see `entity-design`, which explicitly keeps entities free of anything but persistence concerns),
and never in a standalone `FooMapper` class. The DTO already knows its own field-to-constructor mapping;
introducing a third class whose only job is to repeat that knowledge adds a file with no independent
reason to change on its own.

## Field-level `@Schema` annotations belong here

`@Schema(description = ..., requiredMode = ...)` on each field documents the field for OpenAPI. This is
this skill's responsibility, not `openapi`'s — `openapi` covers the endpoint-level `@Operation`/
`@ApiResponse` documentation on the controller/`*Api` interface, while the DTO documents its own shape
once, reused by every endpoint that consumes or returns it.
