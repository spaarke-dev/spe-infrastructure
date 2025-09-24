# task d — file ops (rename/move/delete) + byte-range download

## objective
complete core file ops and enable resumable/partial downloads.

## endpoints
- `PATCH /api/obo/drives/{driveId}/items/{itemId}` body: `{ name?, parentReferenceId? }`  → rename or move
- `DELETE /api/obo/drives/{driveId}/items/{itemId}`
- `GET /api/obo/drives/{driveId}/items/{itemId}/content` (extend)
  - support `Range: bytes=start-end`
  - return `206 Partial Content` with `Content-Range`, `Accept-Ranges: bytes`, preserve `ETag`

## tests
- rename → 200 with new name; move → 200 new parent
- delete → 204
- download with `Range` → 206 with correct headers; 416 on invalid range
- 401/403 preconditions
- if `If-None-Match` equals ETag → 304

## docs
- update openapi and endpoints doc with patch schema and range support

## prompt
> implement task d exactly. add rename/move/delete and extend content download with `Range` and `If-None-Match`. return proper status codes and headers. add tests for 206/416/304 and for CRUD ops happy path and 403.
