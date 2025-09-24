# pr plan (5 small prs)

**PR-1 – foundation (auth seam + di + ping)**
- Add `graphclientfactory` (MI + OBO), `speservice` shell, DI wiring, `/ping`.
- No Razor, no browser Graph calls.

**PR-2 – mi endpoints (containers + files)**
- Add: `POST /api/containers`, `GET /api/containers?containerTypeId=`, `GET /api/containers/{id}/drive`,
  `PUT /api/containers/{id}/files/{*path}`, `POST /api/drives/{driveId}/upload`.
- RFC7807 errors, structured logs, Polly retries (429/503).

**PR-3 – obo endpoints (user-enforced crud)**
- Add OBO variants for list/read/upload/delete where per-user access must be enforced by SPE.

**PR-4 – security & observability**
- Policies (`canmanagecontainers`, `canwritefiles`), validation, rate limits, security headers, OpenTelemetry.

**PR-5 – tests & cleanup**
- Unit tests (service w/ fake Graph), integration tests (401/403/413), remove legacy cert-based app-only code.
