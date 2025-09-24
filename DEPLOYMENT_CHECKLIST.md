# 🚀 SPE Azure Deployment Checklist

## Pre-Deployment Checklist

### Code Quality
- [ ] All unit tests passing locally
- [ ] Code builds without errors: `dotnet build -c Release`
- [ ] No critical warnings in build output
- [ ] Code reviewed and approved

### Environment Setup
- [ ] Azure CLI installed and updated
- [ ] .NET 8.0 SDK installed
- [ ] PowerShell available for ZIP creation
- [ ] Network connection stable

### Azure Authentication
- [ ] Logged into correct Azure tenant: `a221a95e-6abc-4434-aecc-e48338a1b2f2`
- [ ] Correct subscription selected: `484bc857-3802-427f-9ea5-ca47b43db0f0`
- [ ] Account has Owner permissions verified
- [ ] Authentication test: `az account show` returns correct info

## Deployment Process

### Build and Package
- [ ] Clean previous builds: `dotnet clean src/Spe.Bff.Api`
- [ ] Restore packages: `dotnet restore src/Spe.Bff.Api`
- [ ] Build in Release mode: `dotnet build src/Spe.Bff.Api -c Release`
- [ ] Publish to deploy folder: `dotnet publish src/Spe.Bff.Api -c Release -o ./deploy-package`
- [ ] Create ZIP package: `powershell -Command "Compress-Archive -Path './deploy-package/*' -DestinationPath './spe-api.zip' -Force"`
- [ ] Verify ZIP created and contains files

### Azure Deployment
- [ ] Verify target App Service: `spe-api-dev-67e2xz`
- [ ] Verify target Resource Group: `spe-infrastructure-westus2`
- [ ] Deploy package: `az webapp deploy --resource-group spe-infrastructure-westus2 --name spe-api-dev-67e2xz --src-path spe-api.zip`
- [ ] Deployment response shows `"provisioningState": "Succeeded"`
- [ ] No errors in deployment output

## Post-Deployment Verification

### Health Checks
- [ ] Basic health endpoint responds: `curl https://spe-api-dev-67e2xz.azurewebsites.net/healthz`
- [ ] Detailed ping endpoint responds: `curl https://spe-api-dev-67e2xz.azurewebsites.net/ping`
- [ ] JSON response includes service name and timestamp
- [ ] Response time under 1 second

### Application Settings Verification
- [ ] `ASPNETCORE_ENVIRONMENT` = `Development`
- [ ] `TENANT_ID` = `a221a95e-6abc-4434-aecc-e48338a1b2f2`
- [ ] `API_APP_ID` = `170c98e1-d486-4355-bcbe-170454e0207c`
- [ ] `APPLICATIONINSIGHTS_CONNECTION_STRING` configured
- [ ] No null/empty required settings

### Log Verification
- [ ] Check Azure Portal → App Service → Log stream for startup logs
- [ ] No error messages in application logs
- [ ] Request logs show 200 status codes
- [ ] Application Insights receiving telemetry

### Functional Testing
- [ ] API endpoints return expected responses
- [ ] Authentication flow works (if applicable)
- [ ] Database connections working (if applicable)
- [ ] External service integrations working

## Rollback Plan

If deployment fails or issues found:

### Immediate Actions
- [ ] Note deployment time and issue details
- [ ] Check deployment logs: `az webapp log tail --resource-group spe-infrastructure-westus2 --name spe-api-dev-67e2xz`
- [ ] Screenshot error messages
- [ ] Verify app settings unchanged

### Rollback Options
- [ ] **Option 1:** Redeploy previous known-good version
- [ ] **Option 2:** Restart app service: `az webapp restart --resource-group spe-infrastructure-westus2 --name spe-api-dev-67e2xz`
- [ ] **Option 3:** Restore app settings if changed
- [ ] **Option 4:** Contact Azure support if infrastructure issue

## Sign-off

### Deployment Team
- [ ] **Developer:** Deployment completed successfully
- [ ] **QA:** Basic functionality verified
- [ ] **DevOps:** Infrastructure and monitoring confirmed

### Deployment Details
- **Date:** _______________
- **Time:** _______________
- **Deployed By:** _______________
- **Version/Commit:** _______________
- **Environment:** Development (West US 2)

### Notes
_Any special considerations, issues encountered, or follow-up actions needed:_

---

## Emergency Contacts

- **Azure Support:** Portal support tickets
- **Primary Developer:** [Contact Info]
- **DevOps Lead:** [Contact Info]

## Quick Reference Commands

```bash
# Authentication
az login --use-device-code --tenant a221a95e-6abc-4434-aecc-e48338a1b2f2
az account set --subscription 484bc857-3802-427f-9ea5-ca47b43db0f0

# Build and Deploy
dotnet publish src/Spe.Bff.Api -c Release -o ./deploy-package
powershell -Command "Compress-Archive -Path './deploy-package/*' -DestinationPath './spe-api.zip' -Force"
az webapp deploy --resource-group spe-infrastructure-westus2 --name spe-api-dev-67e2xz --src-path spe-api.zip

# Verification
curl https://spe-api-dev-67e2xz.azurewebsites.net/healthz
curl https://spe-api-dev-67e2xz.azurewebsites.net/ping

# Troubleshooting
az webapp log tail --resource-group spe-infrastructure-westus2 --name spe-api-dev-67e2xz
az webapp restart --resource-group spe-infrastructure-westus2 --name spe-api-dev-67e2xz
```