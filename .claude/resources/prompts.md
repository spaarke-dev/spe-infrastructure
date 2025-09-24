# engineering prompts (mi-first, spa+bff)

## goals
- react spa + asp.net core (minimal api **or** azure functions) as bff.
- **user-assigned managed identity (mi)** for app-only microsoft graph calls.
- **obo** only where per-user crud must be enforced by sharepoint embedded (spe).
- clean vertical slices (feature folders), policy-based authorization, strong logging/telemetry.
- no secrets in repo; key vault only for confidential client (obo) if used.

## ground rules
- do not add razor/mvc views (spa owns ui).
- never call graph/spe from the browser; the bff does all token brokerage.
- app-only path uses mi: `defaultazurecredential(managedidentityclientid=...)` + scope `https://graph.microsoft.com/.default`.
- obo path: exchange incoming api token for a graph token via msal confidential client; secret/cert is stored in key vault.
- require `filestoragecontainer.selected (application)` + container-type permissions for app-only calls.
- for files in containers, operate on the **container’s drive** (`drives/{driveid}`), not `me/drive`.

## required artifacts per feature
- **endpoint** (minimal api/function) + request/response dtos.
- **service** encapsulating graph calls (no msal in endpoints).
- **auth policy** name(s) and mapping (roles/claims).
- **validation** (fluentvalidation or minimal guard clauses).
- **logs** (structured), **errors** (problem+trace id), **metrics** (duration, status).

## code patterns to generate
1) **graphclientfactory**
   - `createapponlyclient()` → mi
   - `createonbehalfofclientasync(userapitoken)` → obo

2) **speservice**
   - `createcontainerasync(containertypeid, name, description?)`
   - `uploadsmallasync(containerid, path, stream)`
   - `createuploadsessionasync`, `uploadchunkasync`, `completeuploadasync`
   - `listchildrenasync(driveid, itemid?)`

3) **endpoints**
   - `post /api/containers` (mi)
   - `put /api/containers/{id}/files/{*path}` (mi)
   - `get /api/drives/{driveid}/children?itemid=` (mi)
   - add obo variants only when user-level enforcement is required.

## security prompts (append to any security-sensitive change)
- ensure no secrets in source control; read secret/cert via key vault only for obo.
- verify mi has graph app role & container-type permissions; return 403 with actionable error when missing.
- add cors allowlist, rate-limiting, security headers, and pii-safe logs.

## testing prompts
- generate unit tests for services with a fake graph client.
- add endpoint integration tests (happy + 401 + 403 + 413).
- add perf smoke (upload 20mb via upload session).

## do / don’t
- ✅ do centralize token acquisition in the factory.
- ✅ do add health checks and opentelemetry.
- ❌ don’t fetch graph tokens in controllers.
- ❌ don’t put user tokens in logs.
