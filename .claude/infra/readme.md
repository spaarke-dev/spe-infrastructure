# azure infra — spe bff (safe-by-default)
date: 2025-09-24

This folder deploys the base platform for **Spe.Bff.Api** on Azure App Service with a **User‑Assigned Managed Identity (UAMI)**, **Key Vault**, and **Application Insights**. 
The script runs **WHAT-IF** by default—no changes until you set `APPLY=1`.

## quick start (what‑if only)
```bash
cd infra/scripts
./deploy.sh -g SharePointEmbedded -l eastus -p ../params/dev.bicepparam -s 484bc857-3802-427f-9ea5-ca47b43db0f0
```
