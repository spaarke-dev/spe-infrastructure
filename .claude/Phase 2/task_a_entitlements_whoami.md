# task a — entitlements + whoami

## objective
give the spa a cheap way to understand the user and their allowed actions against a container **without probing graph**.

## deliverables
- `GET /api/me` → `{ displayName, userPrincipalName, oid }` (minimal; no sensitive pii)
- `GET /api/me/capabilities?containerId=...` → `{ read, write, delete, createFolder }`
- docs:
  - update `docs/spe/endpoints.md` with the above
  - update `docs/spe/openapi.yaml`
- tests:
  - 401 when no bearer
  - user with access: capabilities reflect true rights (read=true, write/delete per permissions)
  - user without access: read=false, write=false, delete=false, createFolder=false

## implementation notes
- compute capabilities by attempting **lightweight graph checks** via obo or cached permission info on container drive (do not enumerate every item).
- cache result in-memory for a few minutes per `(user, containerId)` to reduce chattiness.
- preserve existing rfc7807 error shape.

## acceptance criteria
- endpoints compile and pass tests
- openapi reflects both endpoints with response models
- problem details on 401; no token/claims in logs

## prompt for claude code
> implement task a exactly. add the two endpoints, minimal models, cache (5 min) per (user, containerId), update openapi and endpoints doc, and add tests for 401 and allowed/denied users.
