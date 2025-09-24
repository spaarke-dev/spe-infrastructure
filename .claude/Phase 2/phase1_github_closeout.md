# phase 1 — github closeout checklist
date: 2025-09-24

If Claude Code already pushed Phase 1 commits and tests are green, do this quick wrap‑up.

## 1) merge & tag
```bash
git status
git checkout main
git pull
git merge --no-ff chore/rename-to-spe-bff-api -m "merge: phase 1 complete (refactor + validations)"
git tag -a v0.5.0 -m "phase 1 complete: mi+obo, security headers, cors, otel, tests, refactor to Spe.Bff.Api"
git push origin main
git push origin --tags
```

## 2) optional cleanup
```bash
git branch -d chore/rename-to-spe-bff-api
# or keep it; your call
```

## 3) optional: create a release (recommended)
- Title: `v0.5.0 – phase 1 complete`
- Notes: shortlist the PR-2/3/4/5 highlights + refactor rename
- Attach artifacts if you made bundles (not required)

## 4) branch protection & ci (optional)
- Protect `main` (require PR + passing checks)
- Keep the minimal CI (build + test) or disable it until Phase 2
