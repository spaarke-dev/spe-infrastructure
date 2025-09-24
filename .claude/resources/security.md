# security

## principles
- secretless app-only by default (mi).
- OBO is mandatory when SPE must enforce the user’s permissions; MI is for platform/admin.
- No tokens/claims in logs; store confidential client secret/cert in Key Vault (cloud).
- obo only when user-level enforcement is required.
- least privilege on graph app role + container-type permissions.

## controls
- **identity**: user-assigned mi attached to compute.
- **permissions**:
  - entra: graph app role `filestoragecontainer.selected (application)`.
  - spe: container-type permissions (create/readcontent/writecontent) granted to mi.
- **config**: no secrets in repo. key vault for obo confidential client.
- **network**: https only, cors allowlist.
- **headers**: csp, hsts, x-content-type-options, referrer-policy.
- **abuse**: rate limiting, request size limits, retry/backoff to graph.
- **logging**: structured logs, no tokens/pii. differentiate 401 vs 403 with clear reasons.
- **validation**: dto validation (lengths, patterns); url/path encoding.

## threat notes
- token leakage → never log authorization or claims; avoid query tokens.
- over-privilege → keep minimal container-type permissions; review quarterly.
- upload abuse → limit size, chunk uploads, scan where required.
