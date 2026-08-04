---
name: observability
description: Metrics and tracing infrastructure for a OneLiteFeather Micronaut REST API — Micrometer with Prometheus, OpenTelemetry tracing for HTTP and JDBC, and Kubernetes service discovery (inert outside a cluster). Use this whenever wiring up metrics/tracing dependencies or the /metrics endpoint in a Micronaut backend, or deciding whether a dependency like the Kubernetes discovery client is safe to always include. For log-usage conventions (what to log, structured JSON logging, trace/log correlation), see the logging skill instead — this skill covers the metrics/tracing infrastructure only.
---

# Observability: metrics and tracing

Every OneLiteFeather Micronaut backend ships the same baseline observability stack, regardless of
whether the deployment target is Kubernetes or not — the dependencies are inert (do nothing, cost
nothing at runtime) when their activation condition isn't met, so there is no cost to including them
everywhere and no per-project decision to make.

## Metrics: Micrometer + Prometheus

```kotlin
dependencies {
    implementation(mn.micronaut.management)
    implementation(mn.micronaut.micrometer.core)
    implementation(mn.micronaut.micrometer.registry.prometheus)
}
```

`micronaut-management` exposes the `/metrics` endpoint; the Prometheus registry formats those metrics
for scraping. Enable it in `application.yml`, keeping it marked `sensitive` so it stays behind the
`security` skill's deny-by-default baseline like every other endpoint, rather than carving out an
unauthenticated exception for it:

```yaml
endpoints:
  metrics:
    enabled: true
    sensitive: true
```

## Tracing: OpenTelemetry for HTTP and JDBC

```kotlin
dependencies {
    implementation(mn.micronaut.tracing.opentelemetry.http)
    implementation(mn.micronaut.tracing.opentelemetry.jdbc)
    implementation(libs.opentelemetry.exporter.otlp)
}
```

Spans are only actually exported when the `OTEL_TRACES_EXPORTER=otlp` environment variable is set —
locally, with no exporter configured, these dependencies are present but produce no network traffic and
no overhead beyond in-process span creation. Set `OTEL_TRACES_EXPORTER=otlp` (plus `OTEL_EXPORTER_OTLP_ENDPOINT`)
only in the environments (staging, production, Docker) that actually have a collector to receive spans.

The `logging` skill covers how these trace/span IDs get correlated into log lines via the OpenTelemetry
MDC appender — that correlation glue lives there, not here, since it's a logging-format concern, not a
tracing-infrastructure one.

## Kubernetes service discovery

```kotlin
dependencies {
    // Kubernetes service discovery — beans only activate in the k8s environment,
    // so this is inert outside it. Needs RBAC (read on services/endpoints) in-cluster.
    implementation(mn.micronaut.kubernetes.discovery.client)
}
```

Include this dependency in every backend's `build.gradle.kts`, not only ones that are currently deployed
to Kubernetes — the discovery client's beans only activate when the Micronaut `kubernetes` environment
is detected, so it is a no-op everywhere else. When a backend *is* deployed to a cluster, the
`ServiceAccount` running it needs RBAC permission to `get`/`list`/`watch` on `services` and `endpoints`
in its namespace, or the discovery client fails at startup instead of silently doing nothing.

## What lives in other skills, not here

- Log-usage conventions, structured JSON logging, log levels, trace/log correlation — `logging`.
- The Gradle plugin baseline (Micronaut Application/AOT) these dependencies sit on top of —
  `dependency-management`.
