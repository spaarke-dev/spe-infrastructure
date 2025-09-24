# phase 2 — user crud infrastructure (steps a–e) — updated for `src/Spe.Bff.Api`
date: 2025-09-24

> Host: ASP.NET Core Minimal API in `src/Spe.Bff.Api`  
> Tests: `tests/Spe.Bff.Api.Tests` (WebApplicationFactory)  
> DI: `Spe.Bff.Api` container; OBO service available as `Services.IOboSpeService`

Run tasks **in order**. After each task, build, test, and run a quick smoke.

---

## common pre‑flight (once)
```bash
git checkout -b feature/phase2-a-e
dotnet clean && dotnet restore && dotnet build
dotnet test
```

Ensure you have two users (A allowed, B denied) and at least one SPE container/drive/item for OBO smokes.

---

## task A — entitlements + whoami
**Goal:** Give SPA a cheap way to learn “who am I” and “what can I do on {containerId}” without probing Graph for every click.

**Implement**
- `GET /api/me` → `{ displayName, userPrincipalName, oid }`
- `GET /api/me/capabilities?containerId=...` → `{ read, write, delete, createFolder }`
- Cache capabilities per `(user, containerId)` for 5 minutes

**Where to change**
- Endpoints in `src/Spe.Bff.Api/Api`
- If using service: add to `src/Spe.Bff.Api/Services` (or reuse `IOboSpeService` with a new method)

**Tests**
- 401 when no bearer
- User A: correct booleans; User B: all false
- Problem+json shape is preserved

**Smoke**
```bash
curl -i -H "Authorization: Bearer $TOKEN_A" https://localhost:5xxx/api/me
curl -i -H "Authorization: Bearer $TOKEN_A" "https://localhost:5xxx/api/me/capabilities?containerId=$CONTAINER_ID"
curl -i -H "Authorization: Bearer $TOKEN_B" "https://localhost:5xxx/api/me/capabilities?containerId=$CONTAINER_ID"
```

---

## task B — listing with paging, ordering, metadata
**Goal:** Deterministic listings that the SPA can page/sort easily.

**Extend**
- `GET /api/obo/containers/{id}/children` with:
  - `?top= (default 50, max 200)`
  - `?skip= (default 0)`
  - `?orderBy=name|lastModifiedDateTime|size` (default name)
  - `?orderDir=asc|desc` (default asc)
- Item DTO: `{ id, name, size, eTag, lastModifiedDateTime, contentType, folder:{ childCount? } }`
- Include `nextLink` (relative url) when more results exist

**Where to change**
- Endpoint in `src/Spe.Bff.Api/Api`
- Graph call in `Infrastructure/Graph` or `Services/OboSpeService`

**Tests**
- Default list ≤ 50, sorted by name asc
- top/skip work; nextLink present when applicable
- 401 (no bearer) and 403 (user denied)

**Smoke**
```bash
curl -s -H "Authorization: Bearer $TOKEN_A" "https://localhost:5xxx/api/obo/containers/$CONTAINER_ID/children?top=10&skip=0&orderBy=name&orderDir=asc"
```

---

## task C — large upload (session + chunk proxy)
**Goal:** Support files > 4 MiB via Graph upload sessions; avoid client holding Graph tokens.

**Add**
- `POST /api/obo/drives/{driveId}/upload-session?path=...&conflictBehavior=replace|rename|fail`
  - Return `{ uploadUrl, expirationDateTime }`
- `PUT /api/obo/upload-session/chunk`
  - Headers: `Upload-Session-Url`, `Content-Range`
  - Body: raw chunk bytes
  - Return 202 for intermediate; 201/200 with DriveItem on completion

**Rules**
- Chunk size 8–10 MiB (configurable)
- Validate `Content-Range` (no overlaps/gaps); 400 on invalid
- Honor `Retry-After` and reuse existing Polly policy
- Do not log session URLs

**Where to change**
- Endpoints in `Api`
- Call-through in `Services/OboSpeService` or dedicated upload helper

**Tests**
- Happy path: session → chunks → completion item
- Resume after simulated 503
- 401/403 preconditions
- 413 on too-large chunk

**Smoke**
```bash
# create session
curl -s -X POST -H "Authorization: Bearer $TOKEN_A"   "https://localhost:5xxx/api/obo/drives/$DRIVE_ID/upload-session?path=big.bin&conflictBehavior=replace"
# then PUT chunks to /api/obo/upload-session/chunk with Upload-Session-Url + Content-Range
```

---

## task D — file ops (rename/move/delete) + byte‑range download
**Goal:** Complete core CRUD and enable resumable downloads.

**Add/Extend**
- `PATCH /api/obo/drives/{driveId}/items/{itemId}` body: `{ name?, parentReferenceId? }`
- `DELETE /api/obo/drives/{driveId}/items/{itemId}` → 204
- `GET /api/obo/drives/{driveId}/items/{itemId}/content`  
  - support `Range: bytes=start-end` → return 206 with `Content-Range`, `Accept-Ranges: bytes`, preserve `ETag`
  - support `If-None-Match` → 304 when ETag matches

**Tests**
- Rename → 200; Move → 200; Delete → 204
- Download with Range → 206; invalid range → 416
- 401/403 preconditions

**Smoke**
```bash
# delete
curl -i -X DELETE -H "Authorization: Bearer $TOKEN_A" "https://localhost:5xxx/api/obo/drives/$DRIVE_ID/items/$ITEM_ID"
# range download sample
curl -i -H "Authorization: Bearer $TOKEN_A" -H "Range: bytes=0-1023" "https://localhost:5xxx/api/obo/drives/$DRIVE_ID/items/$ITEM_ID/content"
```

---

## task E — dashboards & alerts (app insights + runbooks)
**Goal:** Operational visibility & playbooks.

**Deliver**
- Workbooks/KQL:
  - 403 breakdown (Authorization_RequestDenied vs user-denied)
  - 429/503 trend & avg Retry‑After
  - P50/95/99 latency by route
  - Upload sessions started/completed/failed
- Two alerts: 403 spike, 429 spike
- Docs: `docs/ops/runbooks.md`

**Smoke (manual)**
- Trigger a known 403 (User B) and verify dashboard/trace appears
- Trigger throttling in a test (if feasible) and see 429 trend

---

## per‑task prompt (paste to Claude Code)
> Execute **Task {A|B|C|D|E}** exactly as specified in `phase 2 — user crud infrastructure (steps a–e)`. Update code in `src/Spe.Bff.Api/**`, add/modify tests in `tests/Spe.Bff.Api.Tests/**`, keep RFC7807 shapes per `docs/spe/error_taxonomy.md`, and ensure no secrets are logged. After implementing, run `dotnet build && dotnet test` and provide the results plus a patch.
