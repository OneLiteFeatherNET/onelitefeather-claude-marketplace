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
