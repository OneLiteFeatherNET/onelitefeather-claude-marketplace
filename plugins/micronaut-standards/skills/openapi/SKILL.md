---
name: openapi
description: OneLiteFeather's OpenAPI documentation convention for Micronaut REST APIs — a doc-only *Api interface per controller carrying @Operation/@ApiResponse (never routing annotations), operationId/tags naming, @ApiResponse schemas referencing the response-modeling skill's success/error records, and enabling Swagger UI/Rapidoc/OpenAPI Explorer. Use this whenever documenting a Micronaut controller endpoint. Routing annotations (@Controller, @Get/@Post/etc.) and validation triggers stay on the controller class itself — see the routing skill for those; this skill covers documentation only.
---

# OpenAPI documentation

Every controller has an accompanying `*Api` interface, in the same `controller/<feature>/` package, that
carries **only** OpenAPI annotations. The controller implements the interface and supplies routing
(`@Controller`, `@Get`/`@Post`/etc. — see `routing`) plus the method body; the interface never routes,
it only documents.

## The `*Api` interface pattern

```java
// controller/font/FontApi.java — documentation only, no routing, no @Body/@PathVariable binding needed
public interface FontApi {

    @Operation(
            summary = "Get a font by ID",
            operationId = "getFontById",
            description = "Gets a font by ID from the database.",
            tags = {"Font"}
    )
    @ApiResponse(
            responseCode = "200",
            description = "The font was successfully retrieved from the database.",
            content = @Content(
                    mediaType = MediaType.APPLICATION_JSON,
                    schema = @Schema(implementation = FontModelResponseDTO.FontModelDTO.class)
            )
    )
    @ApiResponse(
            responseCode = "404",
            description = "The font was not found in the database.",
            content = @Content(
                    mediaType = MediaType.APPLICATION_JSON,
                    schema = @Schema(implementation = FontModelResponseDTO.FontModelErrorDTO.class)
            )
    )
    HttpResponse<FontModelResponseDTO> getById(UUID id);
}
```

```java
// controller/font/FontController.java — routing + logic, implements FontApi
@Controller("/font")
public class FontController implements FontApi {

    private final FontService fontService;

    @Inject
    public FontController(FontService fontService) {
        this.fontService = fontService;
    }

    @Override
    @Get("/{id}")
    @Produces(MediaType.APPLICATION_JSON)
    public HttpResponse<FontModelResponseDTO> getById(@PathVariable UUID id) {
        return fontService.findFontById(id)
                .map(entity -> HttpResponse.ok((FontModelResponseDTO) FontModelResponseDTO.FontModelDTO.createDTO(entity)))
                .orElseGet(() -> HttpResponse.notFound(new FontModelResponseDTO.FontModelErrorDTO("Font not found")));
    }
}
```

Micronaut's OpenAPI annotation processor and its routing engine both read the full type hierarchy of a
controller class — annotations on an interface the class implements are picked up the same as if they
were declared directly on the class. This is what makes the split safe: `@Operation`/`@ApiResponse` on
`FontApi` still end up in the generated OpenAPI document, with zero duplication needed on
`FontController`.

## `operationId` and `tags` naming

- `operationId`: camelCase verb + noun, matching the method name (`getFontById`, `addFont`,
  `deleteFont`) — this becomes the generated client SDK's method name in any OpenAPI-codegen consumer,
  so it should read the same as the Java method it documents.
- `tags`: one tag per resource/domain (`"Font"`, `"Item"`), used to group endpoints in the generated
  Swagger UI — not per HTTP verb, not per module.

## `@ApiResponse` per actual status code

Document every status code the endpoint can actually return, and only those — no blanket `200` with no
`404`/`400` entries when the method can in fact return them. Reference the success/error records from
`response-modeling` in the `schema = @Schema(implementation = ...)` attribute, one `@ApiResponse` block
per status code, exactly as in the `getById` example above.

## Enabling the interactive documentation UIs

```kotlin
tasks {
    compileJava {
        options.forkOptions.jvmArgs = listOf(
            "-Dmicronaut.openapi.views.spec=rapidoc.enabled=true,openapi-explorer.enabled=true,swagger-ui.enabled=true,swagger-ui.theme=flattop"
        )
    }
}
```

This is a recommended developer convenience (serves Swagger UI, Rapidoc, and OpenAPI Explorer from the
running application in dev/staging), not something that changes the generated OpenAPI document itself.
