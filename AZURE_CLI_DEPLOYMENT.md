# Azure CLI Deployment Process - SPE Infrastructure

## 📋 Overview

This document provides the proven Azure CLI deployment process for the SPE (SharePoint Embedded) BFF API. This method has been tested and verified to work reliably for development and production deployments.

## 🎯 Quick Start

```bash
# 1. Build and package
dotnet publish src/Spe.Bff.Api -c Release -o ./deploy-package
powershell -Command "Compress-Archive -Path './deploy-package/*' -DestinationPath './spe-api.zip' -Force"

# 2. Authenticate with Azure (one-time setup)
az login --use-device-code --tenant a221a95e-6abc-4434-aecc-e48338a1b2f2
az account set --subscription 484bc857-3802-427f-9ea5-ca47b43db0f0

# 3. Deploy
az webapp deploy --resource-group spe-infrastructure-westus2 --name spe-api-dev-67e2xz --src-path spe-api.zip
```

## 📖 Detailed Process

### Prerequisites

**Required Software:**
- ✅ .NET 8.0 SDK
- ✅ Azure CLI (latest version)
- ✅ PowerShell (for ZIP creation)

**Azure Resources:**
- ✅ App Service: `spe-api-dev-67e2xz` (West US 2)
- ✅ Resource Group: `spe-infrastructure-westus2`
- ✅ Application Insights: `spe-insights-dev-67e2xz`

### Step-by-Step Deployment

#### Step 1: Build the Application

```bash
# Clean build in Release mode
dotnet clean src/Spe.Bff.Api
dotnet build src/Spe.Bff.Api -c Release

# Publish to deployment folder
dotnet publish src/Spe.Bff.Api -c Release -o ./deploy-package
```

**Expected Output:**
- ✅ Build succeeded with warnings (async methods)
- ✅ Files created in `./deploy-package/`
- ✅ Contains: `Spe.Bff.Api.exe`, `web.config`, dependencies

#### Step 2: Create Deployment Package

```bash
# Create ZIP file for deployment
powershell -Command "Compress-Archive -Path './deploy-package/*' -DestinationPath './spe-api.zip' -Force"
```

**Verify Package:**
```bash
# Check ZIP contents (optional)
powershell -Command "Get-Content ./spe-api.zip | Measure-Object -Line"
```

#### Step 3: Azure Authentication

**First-time setup (or after token expiry):**

```bash
# Clear any cached credentials
az account clear
az cache purge

# Login with device code (most reliable method)
az login --use-device-code --tenant a221a95e-6abc-4434-aecc-e48338a1b2f2
```

**Follow the prompts:**
1. Open https://microsoft.com/devicelogin
2. Enter the provided code
3. Sign in with `ralph.schroeder@spaarke.com`

**Set correct subscription:**
```bash
az account set --subscription 484bc857-3802-427f-9ea5-ca47b43db0f0

# Verify authentication
az account show
```

#### Step 4: Deploy to Azure

```bash
# Deploy the ZIP package
az webapp deploy \
  --resource-group spe-infrastructure-westus2 \
  --name spe-api-dev-67e2xz \
  --src-path spe-api.zip
```

**Expected Response:**
```json
{
  "active": true,
  "complete": true,
  "deployer": "OneDeploy",
  "provisioningState": "Succeeded",
  "site_name": "spe-api-dev-67e2xz"
}
```

#### Step 5: Verify Deployment

```bash
# Test health endpoint
curl https://spe-api-dev-67e2xz.azurewebsites.net/healthz

# Test ping endpoint (should return JSON)
curl https://spe-api-dev-67e2xz.azurewebsites.net/ping
```

**Expected Response from `/ping`:**
```json
{
  "ok": true,
  "service": "SPE BFF API",
  "traceId": "...",
  "timestamp": "2025-09-24T14:33:01.9855004+00:00"
}
```

## ⚙️ Configuration

### Required App Service Settings

The following application settings are configured and required:

```bash
# View current settings
az webapp config appsettings list \
  --resource-group spe-infrastructure-westus2 \
  --name spe-api-dev-67e2xz \
  --query "[].{Name:name,Value:value}" \
  --output table
```

**Required Settings:**
- `ASPNETCORE_ENVIRONMENT` = `Development`
- `TENANT_ID` = `a221a95e-6abc-4434-aecc-e48338a1b2f2`
- `API_APP_ID` = `170c98e1-d486-4355-bcbe-170454e0207c`
- `APPLICATIONINSIGHTS_CONNECTION_STRING` = `InstrumentationKey=09a9beed...`

### App Service Configuration

**Verified Working Configuration:**
- Runtime: `.NET 8.0`
- Platform: `64-bit`
- PHP: `Off` (critical - prevents conflicts)
- Always On: `false` (Basic tier)

## 🚀 Deployment Environments

### Development Environment
- **App Service:** `spe-api-dev-67e2xz`
- **Resource Group:** `spe-infrastructure-westus2`
- **Region:** West US 2
- **Tier:** Basic B1

### Adding New Environments

To create staging/production environments:

```bash
# Example for staging
az webapp create \
  --resource-group spe-infrastructure-westus2 \
  --plan spe-plan-dev-67e2xz \
  --name spe-api-staging-67e2xz \
  --runtime "DOTNET|8.0"

# Configure settings
az webapp config appsettings set \
  --resource-group spe-infrastructure-westus2 \
  --name spe-api-staging-67e2xz \
  --settings ASPNETCORE_ENVIRONMENT=Staging [other settings...]
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. Authentication Failures
**Symptom:** `Please run 'az login' to setup account`
**Solution:**
```bash
az account clear
az cache purge
az login --use-device-code --tenant a221a95e-6abc-4434-aecc-e48338a1b2f2
```

#### 2. Wrong Subscription
**Symptom:** `The subscription ... doesn't exist`
**Solution:**
```bash
az account list --output table
az account set --subscription 484bc857-3802-427f-9ea5-ca47b43db0f0
```

#### 3. App Not Starting (503 Errors)
**Symptom:** `503 Service Unavailable`
**Common Causes:**
- Missing application settings
- PHP enabled (conflicts with .NET)
- 32-bit worker process
- Missing dependencies

**Solution:**
```bash
# Check app settings
az webapp config appsettings list --resource-group spe-infrastructure-westus2 --name spe-api-dev-67e2xz

# Verify .NET configuration
az webapp config show --resource-group spe-infrastructure-westus2 --name spe-api-dev-67e2xz --query "{netFrameworkVersion:netFrameworkVersion,phpVersion:phpVersion,use32BitWorkerProcess:use32BitWorkerProcess}"

# Fix common issues
az webapp config set --resource-group spe-infrastructure-westus2 --name spe-api-dev-67e2xz --php-version "Off" --use-32bit-worker-process false
```

#### 4. Build Errors
**Symptom:** Compilation errors during `dotnet build`
**Solution:**
```bash
# Clean and restore
dotnet clean
dotnet restore
dotnet build -c Release
```

### Log Analysis

**View deployment logs:**
```bash
az webapp log tail --resource-group spe-infrastructure-westus2 --name spe-api-dev-67e2xz
```

**Download complete logs:**
```bash
az webapp log download --resource-group spe-infrastructure-westus2 --name spe-api-dev-67e2xz --log-file app-logs.zip
```

**Monitor real-time logs:**
- Azure Portal → App Service → Log stream

## 📊 Monitoring

### Health Check Endpoints

- **Basic Health:** `/healthz` - Returns 200 OK
- **Detailed Status:** `/ping` - Returns JSON with service info, trace ID, timestamp

### Application Insights

Monitoring is automatically configured via connection string:
- **Resource:** `spe-insights-dev-67e2xz`
- **Location:** West US 2
- **Logs:** Available in Azure Portal

### Performance Monitoring

Check app performance:
```bash
# Recent requests
az monitor metrics list --resource spe-api-dev-67e2xz --metric "Http2xx,Http4xx,Http5xx" --interval PT1H
```

## 🔒 Security Considerations

### Best Practices
- ✅ HTTPS enforced by default
- ✅ Security headers configured
- ✅ Application Insights for monitoring
- ✅ Rate limiting configured
- ✅ CORS policies configured

### Secrets Management
- Application settings stored in App Service configuration
- No secrets in source code
- Environment-specific configuration

## 📈 Performance

### Deployment Times
- **Build:** ~30 seconds
- **Package:** ~5 seconds
- **Upload:** ~15 seconds
- **Total:** ~50 seconds

### Scaling
Current configuration supports:
- Basic B1: 1.75 GB RAM, 1 CPU core
- Can scale up to higher tiers as needed

## 🔄 CI/CD Integration

### Manual Process (Current)
This Azure CLI process is perfect for:
- Development deployments
- Hotfix deployments
- Emergency releases
- Local testing

### Future Automation
The same `az webapp deploy` command can be integrated into:
- GitHub Actions
- Azure DevOps
- Jenkins
- Any CI/CD system

## 📚 Additional Resources

### Documentation
- [Azure CLI Web App Commands](https://docs.microsoft.com/cli/azure/webapp)
- [App Service Deployment](https://docs.microsoft.com/azure/app-service/deploy-zip)

### Support
- **Logs:** Azure Portal → App Service → Log stream
- **Metrics:** Application Insights dashboard
- **Issues:** Check deployment logs and health endpoints

---

**Last Updated:** 2025-09-24
**Tested Version:** .NET 8.0, Azure CLI 2.77.0
**Environment:** Development (West US 2)