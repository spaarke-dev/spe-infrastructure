# repo hygiene update — ignore /claude and local artifacts

## what to change
1) Add a sensible `.gitignore` at the repo root (covers /claude, bin/obj, node_modules, logs, coverage, etc.).
2) (Optional) Add `.dockerignore` if/when you containerize.

## exact steps for claude code
1) Create/overwrite files:
   - `.gitignore` with the content from this folder
   - `.dockerignore` with the content from this folder (optional)

2) Remove already-committed helper files from the index (keep them locally):
```bash
git rm -r --cached claude || true
git rm -r --cached bin obj TestResults coverage logs backups tmp temp || true
git add .gitignore .dockerignore
git commit -m "chore(gitignore): ignore /claude and local artifacts"
```

3) Verify:
```bash
git status
```

> Do not delete your local `/claude` folder; the `--cached` flag removes it from git tracking only.
