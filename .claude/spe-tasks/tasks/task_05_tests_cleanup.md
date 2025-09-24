# task 05 – tests & cleanup

## add
- Unit tests for `speservice` with fake Graph client.
- Integration tests (happy + 401 + 403 + 413) for endpoints.
- Delete legacy cert-based app-only auth; keep confidential client only for OBO.

## acceptance criteria
- CI green. Coverage threshold met for service and endpoints.
- No lingering references to cert-based app-only auth.

## prompt for claude
Generate tests and cleanup. Provide final patch + rollback notes.
