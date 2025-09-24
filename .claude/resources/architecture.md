# architecture (spa + bff, mi-first)

## frontend
- react spa (fluent ui). calls bff only.

## backend (bff)
- asp.net core minimal api (or azure functions)
- feature-oriented vertical slices:
  - `features/containers/*`
  - `features/drives/*`
  - `features/files/*`

## auth & tokens
- **managed identity (user-assigned)** for app-only calls to graph.
- **obo** only when per-user crud must be enforced.

## integration
- microsoft graph – file storage (spe) + drives
- container-type registration provides app permissions (create/readcontent/writecontent).

## security
- no secrets in repo.
- key vault for obo client secret/cert; mi for runtime.
- cors allowlist, security headers, rate limiting.

## ops
- app service / functions with mi attached.
- app gateway/front door, app insights, health checks.

## extensibility
- background workers (functions/queues) reuse the same user-assigned mi.
