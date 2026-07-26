---
name: exception-handling
description: OneLiteFeather's global exception-handling convention for Micronaut REST APIs — exactly one org-wide ExceptionHandlerAdvice that maps exception types to the correct HTTP status code and returns the shared ErrorResponse type from response-modeling, plus dedicated domain exception classes instead of generic RuntimeExceptions. Use this whenever adding a new failure case a Micronaut backend needs to report, or reviewing an existing global exception handler that maps everything to one status code. This is an explicit correction of a mapping-everything-to-404 pattern seen in an early reference implementation — status-code mapping by exception type is mandatory.
---

# Global exception handling

Every Micronaut backend has exactly one global exception handler, mapping exception types to the HTTP
status code that actually matches the failure — never a single status code for every exception.

## One handler, mapped by exception type

```java
package net.onelitefeather.otis.exception;

@Produces
@Singleton
public class ExceptionHandlerAdvice implements ExceptionHandler<Throwable, HttpResponse<ErrorResponse>> {

    @Override
    public HttpResponse<ErrorResponse> handle(HttpRequest request, Throwable exception) {
        if (exception instanceof ConstraintViolationException || exception instanceof jakarta.validation.ValidationException) {
            return HttpResponse.badRequest(new ErrorResponse.ErrorResponseDTO(exception.getMessage()));
        }
        if (exception instanceof EntityNotFoundException) {
            return HttpResponse.notFound(new ErrorResponse.ErrorResponseDTO(exception.getMessage()));
        }
        return HttpResponse.serverError(new ErrorResponse.ErrorResponseDTO("An unexpected error occurred."));
    }
}
```

**This is an explicit correction, not an incidental design choice**: an early reference implementation's
global handler returned `HttpResponse.notFound(...)` unconditionally for every `Throwable`, regardless of
what actually went wrong. That is wrong even though it compiles and "handles" every exception — a
validation failure and an unexpected NPE are not the same situation, and reporting both as 404 actively
misleads whoever (a human, a client's retry logic) is reading the status code. Every new exception type
this handler needs to cover gets its own `if`/`instanceof` branch (or a `switch` pattern-matching on
sealed exception types, where Java version support allows it) mapped to the status code that matches it,
with `serverError()` (500) reserved for the genuinely-unexpected fallthrough case, not the default for
everything.

## Domain exceptions get their own classes

```java
package net.onelitefeather.otis.exception;

public class EntityNotFoundException extends RuntimeException {
    public EntityNotFoundException(String message) {
        super(message);
    }
}
```

Throw a specific, named exception (`EntityNotFoundException`, or a more specific subtype per resource if
warranted) from the service layer (see `service-layer`) for expected failure cases the global handler
needs to distinguish — not a bare `new RuntimeException("font not found")`. The global handler's
`instanceof` checks are only meaningful if the exception types they check for actually carry that
meaning in their name and type, not just their message string.

## Relationship to `response-modeling`'s per-resource error records

This global handler is the fallback for exceptions that escape a controller/service method entirely.
Where a controller already knows exactly what went wrong (e.g. `getById` not finding a row), returning
a resource-specific error record like `FontModelErrorDTO` directly from the controller (see the `openapi`
and `response-modeling` skills' `getById` example) is preferred over throwing and letting this handler
catch it — throwing is for the cases a controller method didn't and shouldn't need to anticipate inline.
Both paths return the same `ErrorResponse` abstraction, so a client parses errors the same way regardless
of which path produced one.
