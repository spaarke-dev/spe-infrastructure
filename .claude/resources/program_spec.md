# spe bff – program specification

## purpose
backend-for-frontend (bff) for a react spa to manage spe containers and files via microsoft graph.

## non-goals
- no server-rendered ui (no razor/mvc views).
- no browser-direct graph calls.

## auth modes
- **app-only (mi):** user-assigned mi, graph `/.default`, app role `filestoragecontainer.selected (application)` + container-type permissions.
- **user (obo):** msal confidential client exchanges api token → graph token for per-user crud.

## endpoints (v1)
- `post /api/containers` → create spe container (mi)
- `get /api/containers?containertypeid=` → list containers (mi)
- `get /api/containers/{id}/drive` → return drive id (mi)
- `put /api/containers/{id}/files/{*path}` → upload small (mi)
- `post /api/drives/{driveid}/upload` → create upload session + chunk (mi)
- `get /api/drives/{driveid}/children?itemid=` → list (mi)
- (optional obo variants where per-user enforcement is required)

## services
- `igraphclientfactory` (mi + obo)
- `ispeservice` (containers, drives, files)

## policies
- `canmanagecontainers`, `canwritefiles` – mapped from dataverse/entra roles; enforced before calling graph.

## validation & errors
- reject invalid `containertypeid`, `path` early.
- return rfc 7807 problem details with `traceid`.

## observability
- opentelemetry + application insights
- structured logs (requestid, endpoint, graph status)

## config (env or key vault)
- `uami_client_id` (mi)
- `tenant_id`, `api_app_id`, `api_client_secret` (obo only; key vault)
- `default_ct_id`
