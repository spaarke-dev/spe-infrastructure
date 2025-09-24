# task 03 – obo endpoints (user-enforced crud)

## when and why
OBO is **required** for any endpoint where **SPE must enforce the user's permissions** (list/read/upload/delete as the user).
Admin/platform actions can remain MI.

## endpoints (obo variants)
- `GET /api/obo/containers/{id}/children`  (list, as user)
- `GET /api/obo/drives/{driveId}/items/{itemId}/content` (download, as user)
- `PUT /api/obo/containers/{id}/files/{*path}` (small upload, as user)
- `DELETE /api/obo/drives/{driveId}/items/{itemId}` (delete, as user)

## rules
- Use `graphclientfactory.createonbehalfofclientasync(userapitoken)`.
- Confidential client secret/cert comes from Key Vault (cloud only). No secrets in repo.
- Never log tokens or claims. Enforce policies before Graph.

## acceptance criteria
- 403 when user lacks SPE permission; 200/201 when allowed.
- Local run ok (dev creds fallback acceptable).
- Minimal e2e via SPA for one read + one write path.

## prompt for claude
Add the OBO endpoints above. Follow `docs/spe/security.md` constraints. Provide patch + tests.
