---
name: routing
description: OneLiteFeather's HTTP routing conventions for Micronaut REST API controllers — resource-based paths with real HTTP verbs instead of action URLs, blocking HttpResponse<T> as the standard return type, and the Pageable/Page pagination convention. Use this whenever adding a new endpoint or reviewing a controller's @Controller/@Get/@Post/@Put/@Delete usage. For where OpenAPI documentation for the same endpoint goes, see openapi; for the global exception handler, see exception-handling — this skill covers routing and pagination only.
---

# HTTP routing

Controllers use resource-based paths with the HTTP verb that actually matches the operation — never an
action encoded into the URL path with every operation using the same verb.

## Real HTTP verbs, not action URLs

```java
// Correct
@Controller("/font")
public class FontController implements FontApi {

    @Override
    @Post
    @Validated(groups = ValidationGroup.Create.class)
    public HttpResponse<FontModelResponseDTO> add(@Body FontModelDTO item) { /* ... */ }

    @Override
    @Get("/{id}")
    public HttpResponse<FontModelResponseDTO> getById(@PathVariable UUID id) { /* ... */ }

    @Override
    @Put("/{id}")
    @Validated(groups = ValidationGroup.Update.class)
    public HttpResponse<FontModelResponseDTO> update(@PathVariable UUID id, @Body FontModelDTO item) { /* ... */ }

    @Override
    @Delete("/{id}")
    public HttpResponse<FontModelResponseDTO> remove(@PathVariable UUID id) { /* ... */ }
}
```

```java
// Wrong — action encoded in the path, verb doesn't match the operation
@Post("/update/{id}")
public HttpResponse<FontModelResponseDTO> update(@PathVariable UUID id, @Body FontModelDTO item) { /* ... */ }

@Post("/delete/{id}")
public HttpResponse<FontModelResponseDTO> remove(@PathVariable UUID id) { /* ... */ }
```

`/update/{id}` and `/delete/{id}` via `@Post` both work mechanically, but they throw away the
information the HTTP verb itself already carries — a caller (or an API gateway, or a cache) can no
longer tell a mutating call from a read just by looking at the verb.

Validation-group triggers (`@Validated(groups = ...)`) are set on the controller method itself,
alongside its routing annotation, as in the `add`/`update` examples above — see the `dto` skill for the
`ValidationGroup.Create`/`Update` marker interfaces themselves and why one shared DTO uses groups instead
of separate Create/Update DTO types.

## Blocking `HttpResponse<T>` as the standard return type

Every endpoint returns `HttpResponse<T>` synchronously — no `Mono<T>`, `Flux<T>`, or `Publisher<T>`
return types, unless a specific, documented reason requires the reactive model for one endpoint (e.g.
streaming a genuinely unbounded response body). The blocking model is simpler to reason about, test, and
debug, and matches every other convention in this plugin (the service layer, `dto`/`response-modeling`)
which are themselves synchronous.

## `@Controller` base path and resource naming

`@Controller("/font")` at the class level, with the resource name singular or plural depending on
whether the endpoints operate on a collection (`/fonts`, `GET` returns a page) or a single resource
addressed by ID (`/font/{id}`) — pick one convention per resource and keep it consistent across all of
that resource's endpoints; don't mix `/font/{id}` for reads with `/fonts/{id}` for writes on the same
resource.

## Pagination: `Pageable`/`Page<T>`

```java
@Override
@Get(uris = {"/"})
@Produces(MediaType.APPLICATION_JSON)
public HttpResponse<Page<FontModelResponseDTO.FontModelDTO>> getAll(Pageable pageable) {
    Page<FontModelResponseDTO.FontModelDTO> page = fontService.getAllFonts(pageable);
    return HttpResponse.ok(page);
}
```

Micronaut Data's `Pageable` as a method parameter and `Page<T>` as (part of) the return type is the
standard shape for any endpoint that returns a collection — the caller controls `page`/`size`/`sort` via
query parameters Micronaut binds automatically, with no manual parsing. Documenting the pagination
envelope's own OpenAPI schema is the `openapi` skill's job, not this one's.
