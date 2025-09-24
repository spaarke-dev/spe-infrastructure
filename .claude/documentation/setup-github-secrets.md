# GitHub Repository Secrets Setup

## Step-by-Step Instructions

1. **Navigate to your GitHub repository**
   - Go to https://github.com/YOUR_USERNAME/YOUR_REPO
   - Click **Settings** (top navigation)
   - Click **Secrets and variables** → **Actions** (left sidebar)

2. **Add Repository Secrets**

   Click **New repository secret** for each of the following:

### AZURE_CREDENTIALS
**Name:** `AZURE_CREDENTIALS`
**Value:** The complete service principal JSON (provided separately for security)

### UAMI_CLIENT_ID
**Name:** `UAMI_CLIENT_ID`
**Value:** `170c98e1-d486-4355-bcbe-170454e0207c`

### TENANT_ID
**Name:** `TENANT_ID`
**Value:** `a221a95e-6abc-4434-aecc-e48338a1b2f2`

### API_APP_ID
**Name:** `API_APP_ID`
**Value:** `170c98e1-d486-4355-bcbe-170454e0207c`

## Optional Monitoring Secrets

### CRITICAL_ALERTS_EMAIL
**Name:** `CRITICAL_ALERTS_EMAIL`
**Value:** `your-email@spaarke.com`

### PERFORMANCE_ALERTS_EMAIL
**Name:** `PERFORMANCE_ALERTS_EMAIL`
**Value:** `your-email@spaarke.com`

## Test the Setup

After adding all secrets:

1. Go to **Actions** tab in your repository
2. Click **Deploy SPE Infrastructure to Azure**
3. Click **Run workflow**
4. Select **dev** environment
5. Click **Run workflow** button

The workflow should now run successfully and deploy your application to Azure.

## Security Notes

⚠️ **Important**: These credentials have contributor access to your Azure subscription. Keep them secure:
- Only add them to GitHub repository secrets (never in code)
- Regularly rotate the client secret
- Monitor usage in Azure Activity Logs
- Remove access when no longer needed

## Next Steps

Once secrets are configured:
1. Test the workflow with a manual deployment
2. Commit and push changes to trigger automatic deployment
3. Monitor deployment logs in GitHub Actions
4. Verify the application is running at: https://spe-api-dev-67e2xz.azurewebsites.net/healthz