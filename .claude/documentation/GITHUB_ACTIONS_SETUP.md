# GitHub Actions Setup Guide

## Overview
This guide sets up GitHub Actions for automated CI/CD deployment of the SPE infrastructure to Azure.

## Prerequisites
- Azure subscription with proper permissions
- GitHub repository with Actions enabled
- Service principal created for GitHub Actions authentication

## Service Principal Configuration

A service principal has been created. The credentials are provided separately for security.

## GitHub Repository Secrets Setup

Navigate to your GitHub repository → Settings → Secrets and variables → Actions, then add these secrets:

### Required Secrets

#### 1. AZURE_CREDENTIALS
The complete JSON object with service principal credentials (provided separately for security).

#### 2. UAMI_CLIENT_ID
```
170c98e1-d486-4355-bcbe-170454e0207c
```

#### 3. TENANT_ID
```
a221a95e-6abc-4434-aecc-e48338a1b2f2
```

#### 4. API_APP_ID
```
170c98e1-d486-4355-bcbe-170454e0207c
```

### Optional Monitoring Secrets (for alerts)

#### 5. CRITICAL_ALERTS_EMAIL
```
your-critical-alerts@company.com
```

#### 6. PERFORMANCE_ALERTS_EMAIL
```
your-performance-alerts@company.com
```

#### 7. SLACK_WEBHOOK_URL
```
https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

#### 8. TEAMS_WEBHOOK_URL
```
https://outlook.office.com/webhook/YOUR/TEAMS/WEBHOOK
```

## Workflow Configuration

The GitHub Actions workflow (`.github/workflows/deploy-to-azure.yml`) is configured to:

1. **Build and Test** - Compile and test the .NET application
2. **Deploy Infrastructure** - Deploy monitoring infrastructure using Bicep
3. **Deploy API** - Deploy the API to Azure App Service
4. **Run Integration Tests** - Execute tests against the deployed environment

## Triggering Deployments

### Automatic Triggers
- **Push to main branch** - Full deployment pipeline
- **Pull request to main** - Build and test only

### Manual Trigger
- **workflow_dispatch** - Manual deployment with environment selection
  - Go to Actions tab → Deploy SPE Infrastructure to Azure → Run workflow
  - Select environment (dev/staging/prod)

## App Service Configuration

The current deployment targets:
- **App Service**: `spe-api-dev-67e2xz`
- **Resource Group**: `SharePointEmbedded`
- **Subscription**: `Spaarke SPE Subscription 1`

## Monitoring and Alerts

The workflow deploys Application Insights and monitoring infrastructure:
- **Application Insights**: `spe-insights-dev-67e2xz`
- **Connection String**: Available in Azure portal

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify AZURE_CREDENTIALS secret is properly formatted JSON
   - Check service principal has contributor role on subscription

2. **Deployment Failures**
   - Check Azure resource quotas and limits
   - Verify resource group exists and is accessible

3. **App Settings Not Applied**
   - Ensure all required secrets are set in GitHub repository
   - Check App Service configuration in Azure portal

### Manual Verification Commands

```bash
# Test service principal authentication
az login --service-principal -u 8c85a481-f3a0-46de-b84e-3ede8a4d60c3 -p [CLIENT_SECRET] --tenant a221a95e-6abc-4434-aecc-e48338a1b2f2

# Check App Service status
az webapp show --name spe-api-dev-67e2xz --resource-group SharePointEmbedded --query 'state'

# Test API health endpoint
curl https://spe-api-dev-67e2xz.azurewebsites.net/healthz
```

## Security Notes

- Service principal credentials are sensitive - store securely in GitHub secrets only
- Regular rotation of client secrets is recommended
- Monitor service principal usage through Azure Activity Logs
- Use least-privilege principle for role assignments

## Next Steps

1. Add the repository secrets as documented above
2. Test the workflow with a manual trigger
3. Configure monitoring alert recipients
4. Set up additional environments (staging/prod) as needed