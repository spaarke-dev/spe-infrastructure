# task 02 – mi endpoints (containers + files)

## goal
Implement app-only endpoints using Managed Identity.

## endpoints
- `POST /api/containers` (create container)
- `GET /api/containers?containerTypeId=` (list containers)
- `GET /api/containers/{id}/drive` (return drive id)
- `PUT /api/containers/{id}/files/{*path}` (small upload)
- `POST /api/drives/{driveId}/upload` (upload session + chunk)

## rules
- Enforce policies before calling Graph.
- Use `graphclientfactory.createapponlyclient()`.
- Container files via container drive (`drives/{driveId}`); never `me/drive`.
- Error handling: RFC7807; differentiate 403 (missing Graph app role) vs 403 (missing container-type permission).
- Retry 429/503 with exponential backoff (Polly). Respect `Retry-After` if provided.

## rfc7807 shape (example)
```json
{
  "type": "about:blank",
  "title": "forbidden",
  "status": 403,
  "detail": "missing graph app role (filestoragecontainer.selected) for the api identity.",
  "traceId": "00-<activity>-<span>-01",
  "extensions": {
    "graphErrorCode": "Authorization_RequestDenied",
    "graphRequestId": "<request-id>"
  }
}
```

## acceptance criteria
- Postman smoke: create container → upload small → list children.
- Logs include `requestId` and Graph `request-id` when present.

## prompt for claude
Implement Task 02 per `docs/spe/endpoints.md` and this file. Return patch + test snippets.
