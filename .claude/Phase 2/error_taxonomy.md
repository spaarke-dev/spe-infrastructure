# error taxonomy

> purpose: define **consistent errors** for the api using **rfc 7807** (`application/problem+json`), map microsoft graph/spe failures, and give ops a quick way to triage issues. *applies to both mi and obo endpoints.*

last updated: 2025-09-23

---

## conventions

- **content-type:** `application/problem+json`
- **base shape (rfc 7807):**
  - `type` (string uri) — stable id of the problem (see **problem types**)
  - `title` (string) — short, human-readable summary
  - `status` (int) — http status
  - `detail` (string) — human-readable details (safe to show to end users)
  - `instance` (string) — optional, the request path or correlation
- **extensions (always present):**
  - `traceId` — current request/activity id (for app insights)
  - `graphRequestId` — if a graph call failed and provided `request-id`/`client-request-id` header
  - `errors` — when it’s a **validation** error: `{ "<field>": ["msg1","msg2"] }`

> never include tokens, claims, email addresses, file paths, or pii in error bodies or logs.

---

## status code matrix (summary)

| http | when | problem `type` |
|---|---|---|
| **200** | success (get/list) | (none; success payload) |
| **201** | created (create container, small upload maybe) | (none) |
| **202** | accepted (chunk upload in progress) | (none) |
| **204** | deleted / no content | (none) |
| **400** | validation errors, bad `content-range`, unsupported `conflictBehavior` | `urn:problem:validation` |
| **401** | missing/invalid api bearer (obo) | `urn:problem:unauthorized` |
| **403** | forbidden — **see mapping below** | `urn:problem:forbidden` |
| **404** | container/drive/item not found | `urn:problem:not-found` |
| **409** | conflict (rename/move collision when `fail` policy) | `urn:problem:conflict` |
| **413** | payload too large (small upload > limit or chunk > max) | `urn:problem:too-large` |
| **415** | unsupported content-type | `urn:problem:unsupported-media-type` |
| **416** | invalid range on download | `urn:problem:range-not-satisfiable` |
| **429** | throttled (graph, or local rate limiter) | `urn:problem:throttled` |
| **500** | unexpected app error | `urn:problem:internal` |
| **502/503/504** | upstream/transient graph issues (after retries) | `urn:problem:upstream` |

---

## forbidden (403) mapping — **critical**

There are **two** main 403 cases; show operators which one occurred:

1) **delegated consent/permission missing (obo misconfig)**  
   - graph error code: `Authorization_RequestDenied` (or equivalent)  
   - meaning: your **api app registration** lacks *delegated* graph permission or admin consent.  
   - action: fix app registration / consent — **not** a user problem.

2) **user denied by spe (business policy)**  
   - graph returns 403 without the above code  
   - meaning: user lacks the **container-type** permission for this container/drive/item.  
   - action: grant the user access (or use mi/admin path).

> **mi** path can also hit 403 if the **managed identity** lacks the **container-type** permission for that container type. reflect that in `detail`.

**what we include in the body** (both cases):  
- `type = "urn:problem:forbidden"`  
- `title = "Forbidden"`  
- `status = 403`  
- `detail` with a short remediation hint: either “check delegated Graph consent on API app” or “user lacks permission on container/item.”  
- `graphRequestId` when available  
- `traceId` always

---

## rfc 7807 examples

### 401 (no bearer)
```json
{
  "type": "urn:problem:unauthorized",
  "title": "Unauthorized",
  "status": 401,
  "detail": "Missing or invalid bearer token.",
  "traceId": "00-6f1b...-01"
}
```

### 403 — delegated consent missing (obo misconfig)
```json
{
  "type": "urn:problem:forbidden",
  "title": "Forbidden",
  "status": 403,
  "detail": "Application is not authorized to act on behalf of the user. Verify delegated Graph permissions and admin consent for the API app registration.",
  "graphRequestId": "0f9c2b5a-...-c882",
  "graphErrorCode": "Authorization_RequestDenied",
  "traceId": "00-6f1b...-01"
}
```

### 403 — user denied by SPE
```json
{
  "type": "urn:problem:forbidden",
  "title": "Forbidden",
  "status": 403,
  "detail": "User is not permitted to access this container or item.",
  "graphRequestId": "8f33d1ad-...-ba10",
  "traceId": "00-6f1b...-01"
}
```

### 400 — validation (bad path)
```json
{
  "type": "urn:problem:validation",
  "title": "One or more validation errors occurred.",
  "status": 400,
  "errors": {
    "path": [ "path must not end with '/'" ]
  },
  "traceId": "00-6f1b...-01"
}
```

### 413 — too large (small upload)
```json
{
  "type": "urn:problem:too-large",
  "title": "Payload Too Large",
  "status": 413,
  "detail": "Small upload limit is 4 MiB. Use the upload session endpoints for larger files.",
  "traceId": "00-6f1b...-01"
}
```

### 429 — throttled
```json
{
  "type": "urn:problem:throttled",
  "title": "Too Many Requests",
  "status": 429,
  "detail": "Please retry after the interval indicated by Retry-After.",
  "traceId": "00-6f1b...-01"
}
```

### 416 — invalid range
```json
{
  "type": "urn:problem:range-not-satisfiable",
  "title": "Requested Range Not Satisfiable",
  "status": 416,
  "detail": "The requested byte range is invalid for the target resource.",
  "traceId": "00-6f1b...-01"
}
```

---

## problem types (stable uris)

Use **URNs** so we don’t depend on a public domain:

- `urn:problem:unauthorized`
- `urn:problem:forbidden`
- `urn:problem:validation`
- `urn:problem:not-found`
- `urn:problem:conflict`
- `urn:problem:too-large`
- `urn:problem:unsupported-media-type`
- `urn:problem:range-not-satisfiable`
- `urn:problem:throttled`
- `urn:problem:internal`
- `urn:problem:upstream`

> these strings are **contract**; once shipped, only add new types—don’t rename existing ones.

---

## mi vs obo — mapping rules

- **shared**:
  - catch `Microsoft.Graph.ServiceException`
  - copy `request-id` / `client-request-id` from response headers (if present) to `graphRequestId`
  - include `traceId` from current activity
  - retry transient errors (polly) before returning 502/503/504

- **mi path**:
  - 403 → likely **container-type** permission missing for the **managed identity**; message should say “managed identity lacks permission”

- **obo path**:
  - 401 → missing/invalid **api** bearer (never accept Graph token from client)
  - 403 + `Authorization_RequestDenied` → **delegated** permission/consent missing (app config)
  - other 403 → user lacks permission on container/drive/item (business denial)

---

## headers & correlation

- pass-through to logs/telemetry:
  - `traceId` (W3C traceparent is also present)
  - `graphRequestId` (from Graph headers)
- **never** log:
  - `Authorization`
  - cookies
  - raw request/response bodies

---

## validation errors

- status: **400**
- shape:
  ```json
  {
    "type": "urn:problem:validation",
    "title": "One or more validation errors occurred.",
    "status": 400,
    "errors": {
      "<field>": ["<message>", "..."]
    },
    "traceId": "..."
  }
  ```
- map model binding failures (e.g., invalid guid) to this shape with a clear field name.

---

## throttling & retry

- **429** from Graph or local limiter:
  - include `Retry-After` (seconds or http-date) if available
  - client guidance: exponential backoff respecting `Retry-After`
- **503/504** after retries:
  - return `urn:problem:upstream` with a short message, include `graphRequestId`

---

## download — byte-range semantics

- support `Range: bytes=start-end`
- success: **206** with headers:
  - `Accept-Ranges: bytes`
  - `Content-Range: bytes <start>-<end>/<total>`
  - preserve `ETag`
- invalid range: **416** with `urn:problem:range-not-satisfiable`
- `If-None-Match` equals ETag → **304 Not Modified** (no problem+json body)

---

## operator decision tree (quick)

1) **401?** → client didn’t send/renew API bearer (obo)
2) **403 with `Authorization_RequestDenied`?** → fix API app delegated consent/permissions
3) **403 without that code?**  
   - MI endpoint → grant container-type permission to the **managed identity**  
   - OBO endpoint → grant the **user** permission on the container/item
4) **429?** → throttled; check retry-after and rate limits
5) **503/504?** → transient Graph; look for spikes and retry budget
6) **413?** → use upload session/chunked path
7) **416?** → invalid download range from client

---

## testing expectations

- all error endpoints return `application/problem+json`
- bodies include `traceId`; when applicable, include `graphRequestId`
- validation tests assert `errors` object with field keys
- 403 tests cover both branches (delegated consent vs user denied)

---
