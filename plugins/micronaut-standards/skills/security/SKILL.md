---
name: security
description: OneLiteFeather's Micronaut Security baseline for REST APIs — deny-by-default access control with explicit per-endpoint @Secured annotations. Use this whenever adding a new controller endpoint and deciding who is allowed to call it, or when reviewing an existing endpoint that has no @Secured annotation at all. This is a foundational, prescriptive baseline rather than a pattern lifted from an existing reference codebase — neither of this plugin's two source repos has a security layer at all, which is itself the gap this skill exists to close. Does not cover a full auth/identity scheme (JWT issuance, OAuth2 flows, roles) — see this skill's own "Out of scope" note.
---

# Security baseline: deny by default

Every Micronaut backend enables Micronaut Security and configures it to deny access by default — an
endpoint is locked down unless it explicitly opts out of that default. This is the opposite of the
common failure mode of adding security "later" once a public-facing deployment forces the question,
which almost always means auditing every existing endpoint retroactively instead of every new endpoint
having to justify why it's open.

## Dependencies

```kotlin
dependencies {
    annotationProcessor(mn.micronaut.security.annotations)
    implementation(mn.micronaut.security)
}
```

Both resolve through the `mn.*` platform catalog like every other Micronaut module dependency (see
`dependency-management`) — no separate version-catalog entry is needed.

## Enabling the deny-by-default baseline

```yaml
# application.yml
micronaut:
  security:
    enabled: true
```

With Micronaut Security enabled and no further per-endpoint configuration, every controller method is
rejected with `401 Unauthorized` by default — nothing is reachable until it's explicitly annotated.

## Opening an endpoint explicitly with `@Secured`

```java
@Controller("/font")
public class FontController implements FontApi {

    @Override
    @Get("/{id}")
    @Secured(SecurityRule.IS_AUTHENTICATED)
    public HttpResponse<FontModelResponseDTO> getById(@PathVariable UUID id) { /* ... */ }
}
```

For a genuinely public endpoint (health checks, a public read-only listing), open it explicitly and
narrowly rather than disabling security for the whole controller:

```java
@Override
@Get(uris = {"/"})
@Secured(SecurityRule.IS_ANONYMOUS)
public HttpResponse<Page<FontModelResponseDTO.FontModelDTO>> getAll(Pageable pageable) { /* ... */ }
```

`@Secured` can be placed at the class level (applies to every method that doesn't override it) or the
method level (overrides the class-level value for that one method) — prefer the most restrictive
sensible default at the class level, with individual methods opting into something looser
(`IS_ANONYMOUS`) only where that's a deliberate, reviewed decision, never as an oversight from a missing
annotation.

## Deciding which endpoints get opened, and how

Ask, for each endpoint: does this need to be reachable without authentication at all (`IS_ANONYMOUS`),
does it need any authenticated caller regardless of role (`IS_AUTHENTICATED`), or does it need a specific
role/permission (a custom `@Secured("ROLE_ADMIN")`-style value, once the project defines its own roles)?
Document the answer as the `@Secured` value itself — the annotation is the documentation; there should be
no endpoint where the answer to "who can call this" requires reading application-wide security
configuration to figure out.

## Out of scope

This skill establishes the deny-by-default baseline and the `@Secured` convention only. It does not cover
issuing or validating JWTs, configuring an OAuth2/OIDC provider, or designing a role/permission model —
those are project-specific decisions that depend on what identity provider (if any) a given backend
integrates with, and belong in that project's own documentation once decided.
