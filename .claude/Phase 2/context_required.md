# context_required

provide or confirm these before running tasks:

## identities & permissions
- user-assigned managed identity (uami) per env (already used by mi endpoints).
- api app registration has **delegated** graph permissions for spe user ops; admin consent granted.
- at least two test users:
  - user a: has spe permission on target container/item.
  - user b: **no** access.

## configuration (app service)
- `uami_client_id`, `tenant_id`, `api_app_id`, key vault ref for `api_client_secret`.
- `cors:allowedorigins` set to your spa domains.
- `applicationinsights:connectionstring` (or azure monitor otel extension).

## api docs & conventions
- rfc7807 error format with `traceId` and `graphRequestId`.
- rate limits: `graph-read` on get/list; `graph-write` on write/delete.
- small upload cutoff: 4 MiB; chunk size target: 8–10 MiB.
- conflict behavior: `replace|rename|fail` — default = `replace`.

## test data
- `container_type_id` and at least one existing **container id** and its **drive id**.
- at least one **item id** for download/delete tests.
- sample files for upload (1–2 kb and 20–50 mb).

## docs to pin for claude code
- `docs/spe/security.md`
- `docs/spe/endpoints.md`
- `docs/spe/error_taxonomy.md` (create if missing)
- `docs/spe/openapi.yaml` (create/update as part of tasks)
- `docs/ops/runbooks.md` (create/update as part of task e)
