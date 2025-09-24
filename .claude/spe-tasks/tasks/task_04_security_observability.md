# task 04 – security & observability

## add
- Policies: `canmanagecontainers`, `canwritefiles` (claims/roles mapping stub).
- Request validators (lengths, patterns for ids/paths).
- Rate limiting policies: `graph-write`, `graph-read` (apply to endpoints).
- Security headers: CSP, HSTS, X-Content-Type-Options, Referrer-Policy.
- OpenTelemetry + Application Insights; propagate Graph `request-id` into logs.

## acceptance criteria
- All endpoints guarded by appropriate policy.
- Structured logs with `traceId`, policy name, endpoint, Graph status.
- OTel traces visible in App Insights locally/with connection string.

## prompt for claude
Implement the above and return patch + config notes.
