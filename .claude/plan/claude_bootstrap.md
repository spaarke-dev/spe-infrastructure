# claude bootstrap (pin these files)

**treat the following as authoritative** for this codebase:
- docs/spe/prompts.md
- docs/spe/program_spec.md
- docs/spe/architecture.md
- docs/spe/deployment.md
- docs/spe/endpoints.md
- docs/spe/security.md
- docs/spe/setup.md
- tasks/prompts_guardrails.md
- tasks/endpoint_matrix.md
- tasks/azure_permissions_checklist.md

## one-time instruction to claude code
We are a **React SPA + C# BFF**, **Managed Identity (MI)** for app-only, **OBO** for any endpoint that must enforce *user* permissions inside SharePoint Embedded (SPE).
Never add Razor/MVC or browser Graph calls. Use container **drives** for file ops (`drives/{driveId}`).
All PRs must include: acceptance criteria, diffs, tests, and rollback notes.
