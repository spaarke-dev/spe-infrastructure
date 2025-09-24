# prompts guardrails (paste into every claude request)

- do not add razor/mvc or browser graph calls.
- always use managed identity (mi) for app-only; obo only when per-user crud is required.
- operate on container drives (`drives/{driveId}`), never `me/drive`.
- centralize token acquisition in `graphclientfactory`; controllers/endpoints may not fetch tokens.
- enforce policies before calling graph; return rfc7807 errors with `traceId`.
- no secrets in repo; use key vault for obo confidential client.
- add polly retry for graph 429/5xx; include graph `request-id` in logs.
- follow `tasks/endpoint_matrix.md` for which endpoints are mi vs obo.
