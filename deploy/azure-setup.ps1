# ==================================================
# SPE Infrastructure - Complete Azure Setup
# ==================================================

param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$Location = "eastus",

    [Parameter(Mandatory = $false)]
    [string]$Environment = "dev"
)

Write-Host "🚀 Setting up SPE Infrastructure in Azure..." -ForegroundColor Cyan

# Ensure Azure PowerShell is available
if (!(Get-Module -ListAvailable -Name Az)) {
    Write-Host "❌ Azure PowerShell module not found. Please install it first:" -ForegroundColor Red
    Write-Host "Install-Module -Name Az -Repository PSGallery -Force" -ForegroundColor Yellow
    exit 1
}

# Connect and set context
Write-Host "🔐 Connecting to Azure..." -ForegroundColor Yellow
Connect-AzAccount
Set-AzContext -SubscriptionId $SubscriptionId

# Create resource group if it doesn't exist
$rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $rg) {
    Write-Host "📦 Creating resource group: $ResourceGroupName" -ForegroundColor Yellow
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location
}

# Generate unique names
$timestamp = Get-Date -Format "yyyyMMddHHmm"
$uniqueSuffix = $timestamp.Substring($timestamp.Length - 6)

$appInsightsName = "spe-insights-$Environment-$uniqueSuffix"
$logAnalyticsName = "spe-logs-$Environment-$uniqueSuffix"
$appServicePlanName = "spe-plan-$Environment-$uniqueSuffix"
$appServiceName = "spe-api-$Environment-$uniqueSuffix"

Write-Host "📊 Deploying monitoring infrastructure..." -ForegroundColor Yellow

# Deploy monitoring first
$monitoringDeployment = New-AzResourceGroupDeployment `
    -Name "spe-monitoring-$timestamp" `
    -ResourceGroupName $ResourceGroupName `
    -TemplateFile "$PSScriptRoot\..\monitoring\DeployMonitoring.bicep" `
    -appInsightsName $appInsightsName `
    -logAnalyticsWorkspaceName $logAnalyticsName `
    -criticalAlertsEmail "admin@company.com" `
    -performanceAlertsEmail "dev@company.com" `
    -Verbose

if ($monitoringDeployment.ProvisioningState -ne "Succeeded") {
    Write-Host "❌ Monitoring deployment failed!" -ForegroundColor Red
    exit 1
}

$appInsightsConnectionString = $monitoringDeployment.Outputs.appInsightsConnectionString.Value

Write-Host "✅ Monitoring deployed successfully!" -ForegroundColor Green
Write-Host "📝 Application Insights Connection String:" -ForegroundColor Cyan
Write-Host $appInsightsConnectionString -ForegroundColor White

# Deploy App Service infrastructure
Write-Host "🌐 Deploying App Service infrastructure..." -ForegroundColor Yellow

# Create App Service Plan
$appServicePlan = New-AzAppServicePlan `
    -ResourceGroupName $ResourceGroupName `
    -Name $appServicePlanName `
    -Location $Location `
    -Tier "Standard" `
    -NumberofWorkers 1 `
    -WorkerSize "Small"

# Create App Service
$appService = New-AzWebApp `
    -ResourceGroupName $ResourceGroupName `
    -Name $appServiceName `
    -Location $Location `
    -AppServicePlan $appServicePlanName

# Configure App Settings
$appSettings = @{
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = $appInsightsConnectionString
    "ASPNETCORE_ENVIRONMENT" = $Environment
    "UAMI_CLIENT_ID" = "your-managed-identity-client-id"
    "TENANT_ID" = "your-tenant-id"
    "API_APP_ID" = "your-api-app-id"
}

Set-AzWebApp -ResourceGroupName $ResourceGroupName -Name $appServiceName -AppSettings $appSettings

Write-Host "✅ App Service deployed successfully!" -ForegroundColor Green
Write-Host "🌐 App Service URL: https://$appServiceName.azurewebsites.net" -ForegroundColor Cyan

# Output summary
Write-Host "`n🎉 Azure Infrastructure Setup Complete!" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Gray
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "App Insights: $appInsightsName" -ForegroundColor White
Write-Host "Log Analytics: $logAnalyticsName" -ForegroundColor White
Write-Host "App Service: $appServiceName" -ForegroundColor White
Write-Host "App Service URL: https://$appServiceName.azurewebsites.net" -ForegroundColor White
Write-Host "=" * 50 -ForegroundColor Gray

Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Deploy your API code to the App Service" -ForegroundColor White
Write-Host "2. Configure authentication (replace test values)" -ForegroundColor White
Write-Host "3. Import the monitoring workbook" -ForegroundColor White
Write-Host "4. Test the alert rules" -ForegroundColor White