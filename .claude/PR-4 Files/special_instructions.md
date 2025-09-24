# special instructions & pitfalls (pr-3 -> pr-4)

## ordering (why this order matters)
1) PR-2 (MI) — proves infra: MI app role + container-type permissions.
2) PR-3 (OBO) — proves **user** enforcement with minimal slice.
3) PR-4 (Security/Observability) — harden surface and add telemetry for supportability.
4) PR-5 (Tests/Cleanup) — raise coverage, remove legacy cert-based code.

## use these files in the PR-4 build
-PR-4 spec + wiring: pr4_security_observability.md
-Patch file only: pr4_security_observability.patch
-OBO smoke tests: obo_smoke_tests.md

## Apply patch
- Apply 'pr4_security_observability.patch
- If the patch bumps on Program.cs, hand the MD to Claude: “apply the unified diff; adapt if needed.”

## delegated permissions (obo)
- Your API app registration needs **delegated Graph permissions** for the user actions you call (the delegated counterparts to MI app role capabilities).  
- After adding, perform **admin consent** in the tenant.  
- OBO will request `https://graph.microsoft.com/.default` and receive only what has been granted.

## tokens (spa/power apps)
- The SPA/Power Apps must request a token with **audience = your API**. Do **not** pass Graph tokens to your API.  
- Your API then performs OBO to obtain a Graph user token.

## environment separation
- One **User-Assigned MI** per environment (dev/stg/prod).  
- Distinct App Insights resources per environment for clean telemetry.  
- Do not re-use secrets/certs across environments.

## secrets & key vault
- OBO confidential client secret/cert lives in **Key Vault** (cloud).  
- Use Key Vault references in App Service/Functions.  
- No secrets in repo; never log tokens/claims.

## cors
- Lock to explicit SPA origins in cloud.  
- Permit any origin only for **local dev**.

## rate limiting
- Keep `graph-write` low in prod to protect SPE (and your budget).  
- Consider per-IP or per-client limits if exposed publicly.

## logging hygiene
- Redact `Authorization` and any PII.  
- Log `traceId` and, when present, Graph `request-id`.

## rollout
- Use deployment **slots**. Warm up `/healthz`.  
- Validate PR-4 in a slot; if anything spikes, **swap back** immediately.

## backout plan
- PR-4 changes are additive. If needed, disable CORS policy or security headers middleware temporarily while investigating, but re-enable before merge.

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

## Extra tips
- Before merging, lock Cors:AllowedOrigins to exact SPA domains.
- Replace the placeholder policy lambdas with your real mapping (roles/claims).
- Add package Azure.Monitor.OpenTelemetry.AspNetCore and call .UseAzureMonitor() if you want traces/metrics/logs in App Insights without extra config.
- Keep MI endpoints and OBO endpoints separate and rate-limited (graph-write is your safety valve)
