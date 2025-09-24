# 🚀 Quick Deploy Reference - SPE Azure CLI

## One-Command Deploy (After Initial Setup)

```bash
dotnet publish src/Spe.Bff.Api -c Release -o ./deploy-package && \
powershell -Command "Compress-Archive -Path './deploy-package/*' -DestinationPath './spe-api.zip' -Force" && \
az webapp deploy --resource-group spe-infrastructure-westus2 --name spe-api-dev-67e2xz --src-path spe-api.zip && \
curl https://spe-api-dev-67e2xz.azurewebsites.net/ping
```

## First-Time Setup

```bash
# 1. Authenticate (one-time)
az login --use-device-code --tenant a221a95e-6abc-4434-aecc-e48338a1b2f2
az account set --subscription 484bc857-3802-427f-9ea5-ca47b43db0f0

# 2. Verify authentication
az account show
```

## Individual Commands

```bash
# Build
dotnet publish src/Spe.Bff.Api -c Release -o ./deploy-package

# Package
powershell -Command "Compress-Archive -Path './deploy-package/*' -DestinationPath './spe-api.zip' -Force"

# Deploy
az webapp deploy --resource-group spe-infrastructure-westus2 --name spe-api-dev-67e2xz --src-path spe-api.zip

# Test
curl https://spe-api-dev-67e2xz.azurewebsites.net/ping
```

## Troubleshooting Quick Fixes

```bash
# Auth issues
az account clear && az login --use-device-code --tenant a221a95e-6abc-4434-aecc-e48338a1b2f2

# App not responding
az webapp restart --resource-group spe-infrastructure-westus2 --name spe-api-dev-67e2xz

# Check logs
az webapp log tail --resource-group spe-infrastructure-westus2 --name spe-api-dev-67e2xz
```

## Environment Info

- **App Service:** `spe-api-dev-67e2xz`
- **Resource Group:** `spe-infrastructure-westus2`
- **Region:** West US 2
- **Health Check:** `/healthz`
- **Status Check:** `/ping`

---
**⏱️ Expected Deploy Time:** ~60 seconds