# 🚀 Azure Deployment Guide

Complete guide to deploy the SPE Infrastructure to Azure with monitoring and CI/CD.

## Prerequisites

### Required Software
```powershell
# Install Azure PowerShell
Install-Module -Name Az -Repository PSGallery -Force

# Install Azure CLI (alternative)
# Download from: https://aka.ms/installazurecliwindows

# Install .NET 8 SDK
# Download from: https://dotnet.microsoft.com/download/dotnet/8.0
```

### Azure Requirements
- Azure subscription with Contributor access
- Resource group creation permissions
- App Service and Application Insights permissions

## 🎯 Quick Deployment (Manual)

### Step 1: Run Azure Setup Script

```powershell
# Clone the repository (if not already done)
git clone <your-repo-url>
cd spe-infrastructure

# Run the complete setup script
.\deploy\azure-setup.ps1 `
    -SubscriptionId 484bc857-3802-427f-9ea5-ca47b43db0f0 `
    -ResourceGroupName SharePointEmbedded `
    -Location "eastus" `
    -Environment "dev"
```

This script will:
- ✅ Create resource group
- ✅ Deploy Application Insights & Log Analytics
- ✅ Set up alert rules and action groups
- ✅ Create App Service Plan and App Service
- ✅ Configure app settings with monitoring

### Step 2: Deploy Your Code

```powershell
# Build and publish the API
dotnet publish src/Spe.Bff.Api -c Release -o ./publish

# Deploy to App Service (replace with your app name)
az webapp deploy --resource-group spe-infrastructure-rg --name spe-api-dev-xxxxxx --src-path ./publish
```

### Step 3: Import Monitoring Dashboard

1. Go to Azure Portal → Monitor → Workbooks
2. Click "New" → "Advanced Editor"
3. Paste content from `monitoring/OperationalDashboard.workbook`
4. Replace placeholders: `{subscription-id}`, `{resource-group}`, `{app-insights-name}`
5. Save as "SPE Operational Dashboard"

## 🔄 Automated Deployment (CI/CD)

### GitHub Actions Setup

#### 1. Create Service Principal

```bash
# Create service principal for GitHub Actions
az ad sp create-for-rbac --name "spe-github-actions" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth
```

#### 2. Configure GitHub Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AZURE_CREDENTIALS` | Service principal JSON from step 1 | `{"clientId":"..."}` |
| `CRITICAL_ALERTS_EMAIL` | Email for critical alerts | `sre@company.com` |
| `PERFORMANCE_ALERTS_EMAIL` | Email for performance alerts | `dev@company.com` |
| `SLACK_WEBHOOK_URL` | Slack webhook (optional) | `https://hooks.slack.com/...` |
| `TEAMS_WEBHOOK_URL` | Teams webhook (optional) | `https://company.webhook.office.com/...` |
| `UAMI_CLIENT_ID` | User Managed Identity Client ID | `12345678-1234-1234-1234-123456789012` |
| `TENANT_ID` | Azure AD Tenant ID | `87654321-4321-4321-4321-210987654321` |
| `API_APP_ID` | App Registration ID | `11111111-2222-3333-4444-555555555555` |

#### 3. Trigger Deployment

The GitHub Actions workflow (`deploy-to-azure.yml`) will automatically:
- Build and test the code
- Deploy monitoring infrastructure
- Deploy the API to App Service
- Run integration tests

**Automatic triggers:**
- Push to `main` branch
- Manual trigger via GitHub Actions UI

## 🔧 Configuration Steps

### 1. Update Application Settings

After deployment, verify these App Service configuration settings:

```json
{
  "APPLICATIONINSIGHTS_CONNECTION_STRING": "[AUTO-POPULATED]",
  "ASPNETCORE_ENVIRONMENT": "dev",
  "UAMI_CLIENT_ID": "your-managed-identity-client-id",
  "TENANT_ID": "your-tenant-id",
  "API_APP_ID": "your-api-app-registration-id"
}
```

### 2. Configure Authentication

#### Option A: Managed Identity (Recommended)
```powershell
# Create User-Assigned Managed Identity
$identity = New-AzUserAssignedIdentity -ResourceGroupName "spe-infrastructure-rg" -Name "spe-api-identity"

# Assign to App Service
Set-AzWebApp -ResourceGroupName "spe-infrastructure-rg" -Name "spe-api-dev-xxxxxx" -AssignIdentity $identity.Id

# Grant Microsoft Graph permissions (requires admin consent)
# This step requires Global Administrator or Application Administrator role
```

#### Option B: App Registration
1. Go to Azure AD → App registrations → New registration
2. Configure API permissions for Microsoft Graph
3. Create client secret
4. Update app settings with client credentials

### 3. Enable HTTPS and Custom Domain

```powershell
# Enable HTTPS only
Set-AzWebApp -ResourceGroupName "spe-infrastructure-rg" -Name "spe-api-dev-xxxxxx" -HttpsOnly $true

# Configure custom domain (optional)
# Requires SSL certificate and DNS configuration
```

## 📊 Monitoring Setup

### Verify Monitoring Components

1. **Application Insights**: Check telemetry data flow
2. **Alert Rules**: Test with sample failures
3. **Dashboard**: Import workbook template
4. **Action Groups**: Verify email/webhook delivery

### Test Monitoring

```powershell
# Generate test traffic
$baseUrl = "https://spe-api-dev-xxxxxx.azurewebsites.net"

# Test endpoints
Invoke-RestMethod -Uri "$baseUrl/health" -Method GET
Invoke-RestMethod -Uri "$baseUrl/api/obo/containers/test/children" -Method GET -Headers @{"Authorization"="Bearer test-token"}
```

### Review Metrics

Go to Azure Portal → Application Insights → Live Metrics to see real-time data.

## 🔒 Security Checklist

### Essential Security Steps

- [ ] **HTTPS Only**: Enforce HTTPS for all traffic
- [ ] **Authentication**: Configure proper Azure AD integration
- [ ] **Secrets Management**: Use Key Vault for sensitive data
- [ ] **Network Security**: Configure NSGs or Private Endpoints
- [ ] **CORS**: Configure appropriate CORS policies
- [ ] **Rate Limiting**: Verify rate limiting policies are active
- [ ] **Monitoring**: Ensure security alerts are configured

### Key Vault Integration (Optional)

```powershell
# Create Key Vault
$keyVault = New-AzKeyVault -ResourceGroupName "spe-infrastructure-rg" -VaultName "spe-keyvault-dev" -Location "eastus"

# Store secrets
Set-AzKeyVaultSecret -VaultName "spe-keyvault-dev" -Name "GraphApiClientSecret" -SecretValue (ConvertTo-SecureString "your-secret" -AsPlainText -Force)

# Configure App Service to use Key Vault
# App Settings: @Microsoft.KeyVault(VaultName=spe-keyvault-dev;SecretName=GraphApiClientSecret)
```

## 🧪 Testing & Validation

### Health Check Endpoints

```bash
# API Health Check
curl https://spe-api-dev-xxxxxx.azurewebsites.net/health

# Monitoring Health
curl https://spe-api-dev-xxxxxx.azurewebsites.net/api/obo/whoami -H "Authorization: Bearer test-token"
```

### Load Testing

```powershell
# Install Artillery for load testing
npm install -g artillery

# Run load test
artillery quick --count 10 --num 50 https://spe-api-dev-xxxxxx.azurewebsites.net/health
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Deployment Failures
```powershell
# Check deployment logs
Get-AzLog -ResourceGroupName "spe-infrastructure-rg" -StartTime (Get-Date).AddHours(-1)

# Check App Service logs
Get-AzWebAppLog -ResourceGroupName "spe-infrastructure-rg" -Name "spe-api-dev-xxxxxx"
```

#### 2. Authentication Issues
- Verify UAMI_CLIENT_ID matches User-Assigned Managed Identity
- Check App Registration permissions and admin consent
- Verify TENANT_ID is correct

#### 3. Monitoring Not Working
- Check Application Insights connection string
- Verify instrumentation key is configured
- Review alert rule conditions and thresholds

### Diagnostic Commands

```powershell
# Test Application Insights connectivity
Invoke-RestMethod -Uri "https://dc.services.visualstudio.com/v2/track" -Method POST -Body '{"name":"test","time":"2024-01-01T00:00:00.000Z","iKey":"your-instrumentation-key","data":{"baseType":"EventData","baseData":{"name":"test"}}}'

# Check resource deployment status
Get-AzResourceGroupDeployment -ResourceGroupName "spe-infrastructure-rg"

# Verify app settings
Get-AzWebApp -ResourceGroupName "spe-infrastructure-rg" -Name "spe-api-dev-xxxxxx" | Select-Object -ExpandProperty SiteConfig | Select-Object -ExpandProperty AppSettings
```

## 📈 Scaling & Performance

### Auto-scaling Configuration

```powershell
# Enable auto-scaling
$autoScaleRule = New-AzAutoscaleRule -MetricName "CpuPercentage" -Operator GreaterThan -Threshold 70 -ScaleAction (New-AzAutoscaleScaleAction -Direction Increase -Type ChangeCount -Value 1)

New-AzAutoscaleSetting -ResourceGroupName "spe-infrastructure-rg" -Name "spe-autoscale" -TargetResourceId "/subscriptions/{subscription-id}/resourceGroups/spe-infrastructure-rg/providers/Microsoft.Web/serverFarms/spe-plan-dev-xxxxxx" -AutoscaleRules $autoScaleRule
```

### Performance Monitoring

- Monitor Application Insights Performance counters
- Set up availability tests for critical endpoints
- Configure slow request alerts (>5 seconds)
- Review dependency call duration (Graph API)

## 🔄 Environment Management

### Multiple Environments

Create separate resource groups for each environment:

```powershell
# Development
.\deploy\azure-setup.ps1 -ResourceGroupName "spe-dev-rg" -Environment "dev"

# Staging
.\deploy\azure-setup.ps1 -ResourceGroupName "spe-staging-rg" -Environment "staging"

# Production
.\deploy\azure-setup.ps1 -ResourceGroupName "spe-prod-rg" -Environment "prod"
```

### Blue-Green Deployment

Use App Service deployment slots:

```powershell
# Create staging slot
New-AzWebAppSlot -ResourceGroupName "spe-infrastructure-rg" -Name "spe-api-prod-xxxxxx" -Slot "staging"

# Deploy to staging slot, then swap
Switch-AzWebAppSlot -ResourceGroupName "spe-infrastructure-rg" -Name "spe-api-prod-xxxxxx" -SourceSlotName "staging" -DestinationSlotName "production"
```

---

## 📞 Support & Maintenance

### Regular Maintenance Tasks

1. **Monthly**: Review alert thresholds and update based on usage patterns
2. **Quarterly**: Update dependencies and security patches
3. **Annually**: Review monitoring retention policies and costs

### Getting Help

- Check Azure Activity Log for deployment issues
- Review Application Insights Live Metrics for real-time diagnostics
- Use Azure Support Center for complex issues
- Check GitHub repository issues for known problems

---

**Last Updated**: January 2025
**Version**: 1.0
**Maintained by**: SPE Infrastructure Team