# task e — dashboards & alerts (app insights + runbooks)

## objective
give ops immediate visibility into auth failures, throttling, and latency outliers.

## deliverables
- app insights workbooks (kql):
  - **403 breakdown** by `Authorization_RequestDenied` vs user-denied (other 403)
  - **throttling**: 429/503 counts & retry-after average
  - **latency**: p50/p95/p99 by route
  - **upload sessions**: started vs completed vs failed
- two metric alerts:
  - 403 spike (threshold + rolling window)
  - 429 spike
- `docs/ops/runbooks.md`:
  - “why 403?” decision tree (delegated consent vs user denied vs container-type perms)
  - “how to grant access”
  - “rotating the obo secret/cert”
  - “recovering stuck upload sessions”

## tests
- none (manual validation). include screenshots or copy/paste kql in docs.

## prompt
> implement task e exactly. create a `docs/ops` folder with KQL workbook json snippets and `runbooks.md`. add an `ops_validation.md` with manual steps to verify dashboards and alerts in each env.
