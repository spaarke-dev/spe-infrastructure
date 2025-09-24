# task c — large upload: create session + chunk proxy

## objective
support files > 4 mib using graph upload sessions and server-side chunk proxy to avoid browser → graph tokens.

## endpoints
- `POST /api/obo/drives/{driveId}/upload-session?path=...&conflictBehavior=replace|rename|fail`
  - returns `{ uploadUrl, expirationDateTime }`
- `PUT /api/obo/upload-session/chunk`
  - headers: `Upload-Session-Url`, `Content-Range`
  - body: raw chunk bytes
  - returns 202 for intermediate, 201/200 with drive item on completion

## rules
- chunk size: 8–10 mib (configurable)
- honor `Retry-After`; retry transient 429/503 with existing polly policy
- validate `Content-Range` and total length; reject overlaps/gaps (rfc7807 400)
- forbid exposing the session url to clients in logs

## tests
- happy path: create session → upload chunks → completion returns item
- resume after a failed chunk (simulate 503)
- 401/403 preconditions
- 413 when chunk > configured max

## docs
- update `endpoints.md` and `openapi.yaml`; document conflict behavior and limits

## prompt
> implement task c exactly. create the session and add a server endpoint that proxies chunk `PUT` to the session URL using OBO token, validating `Content-Range`, honoring Retry-After, and returning the final item when complete. add tests for happy path and resume.
