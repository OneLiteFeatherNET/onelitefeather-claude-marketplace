---
name: logging
description: OneLiteFeather's logging conventions for Micronaut REST APIs — one SLF4J logger per class with no exceptions, structured JSON logging with OpenTelemetry trace/span correlation, log-level guidelines, and what must never be logged (PII, secrets, full request bodies). Use this whenever adding a new class that should log something, or reviewing an existing controller/service for inconsistent logging. For the Gradle dependencies and the metrics/tracing infrastructure this logging setup correlates with, see dependency-management and observability.
---

# Logging

Every controller and service implementation class has its own SLF4J logger — no class silently has no
logger just because nobody added one when the class was created.

## One logger per class, no exceptions

```java
public class FontServiceImpl implements FontService {

    private static final Logger LOGGER = LoggerFactory.getLogger(FontServiceImpl.class);

    @Override
    public FontModelResponseDTO.FontModelDTO createFont(FontModelDTO fontModelDTO) {
        LOGGER.info("Creating font '{}'", fontModelDTO.uiName());
        FontEntity saved = fontRepository.save(fontModelDTO.toFontModel());
        LOGGER.debug("Persisted font with id {}", saved.getId());
        return FontModelResponseDTO.FontModelDTO.createDTO(saved);
    }
}
```

`private static final Logger LOGGER = LoggerFactory.getLogger(<ThisClass>.class);` at the top of every
controller and service-impl class — an inconsistency where some controllers log and neighboring ones
don't makes production incidents harder to diagnose for no reason other than an omission when the class
was written.

## Structured JSON logging + trace correlation

The Gradle dependencies for the Logstash JSON encoder and the OpenTelemetry MDC appender are covered in
`dependency-management`; this skill covers when and how to use the result. With the
appender configured, every log line automatically carries the current `trace_id`/`span_id` from
OpenTelemetry (see `observability`) when one is active — logs and traces correlate in whatever log
aggregation tool (e.g. Grafana Loki) ingests them, with no manual MDC-setting code needed in application
classes. Switch between structured JSON and plain-text console output via an environment variable
(commonly `LOG_JSON=true`/`false`), driven by a Logback `<if>`/`<then>`/`<else>` conditional — plain text
for local development readability, JSON in any environment with a log aggregator behind it.

## Log-level guidelines

- **`debug`** — detail useful while actively developing/troubleshooting a specific code path (e.g. an
  intermediate value), not left enabled by default in production.
- **`info`** — a business-meaningful event happened (a resource was created/updated/deleted, a scheduled
  job ran) — one line per meaningful event, not one line per method call.
- **`warn`** — something recoverable but unexpected happened (a fallback was used, a retry occurred, an
  external call was slow) — worth a human's attention if it happens often, not worth paging anyone.
- **`error`** — something failed and the failure is visible to a caller or corrupts state — pairs with
  the `exception-handling` skill's global handler, which is a reasonable place to log at `error` for the
  server-error (500) branch specifically, not for every branch (a 404 from a normal not-found case is not
  an `error`-level event).

## What must never be logged

Never log personally identifiable information, secrets/credentials/tokens, or a full request body that
might contain sensitive fields (passwords, tokens, payment details) — log identifiers (a UUID, a
username) instead of the sensitive value itself, and log a request's shape/summary rather than its raw
body when the body could contain something sensitive.
