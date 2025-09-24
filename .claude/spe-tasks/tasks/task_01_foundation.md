# task 01 – foundation (auth seam + di + ping)

## goal
Introduce MI-first auth seam without changing business logic. Prepare OBO (no usage yet).

## changes
- Add `src/infrastructure/graph/graphclientfactory.cs` (MI + OBO, Graph SDK v5/Kiota).
- Add `src/infrastructure/graph/speservice.cs` (methods empty or throwing NotImplemented).
- Wire DI in `program.cs`; add `/ping` endpoint.
- Config keys: `uami_client_id`, `tenant_id`, `api_app_id`, `api_client_secret` (OBO only; via Key Vault in cloud).

## acceptance criteria
- Build passes. `/ping` returns 200 and includes `traceId`.
- No secrets in repo. No Razor. No browser Graph calls.

## prompt for claude
Read `docs/spe/*` and `tasks/prompts_guardrails.md`. Implement Task 01 exactly as above and output a patch.
