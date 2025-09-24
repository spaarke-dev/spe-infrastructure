# ==================================================
# SPE Infrastructure - Monitoring Deployment Script
# ==================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$Location,

    [Parameter(Mandatory = $true)]
    [string]$AppInsightsName,

    [Parameter(Mandatory = $true)]
    [string]$LogAnalyticsWorkspaceName,

    [Parameter(Mandatory = $true)]
    [string]$CriticalAlertsEmail,

    [Parameter(Mandatory = $true)]
    [string]$PerformanceAlertsEmail,

    [Parameter(Mandatory = $false)]
    [string]$SlackWebhookUrl = '',

    [Parameter(Mandatory = $false)]
    [string]$TeamsWebhookUrl = '',

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "SPE Infrastructure Monitoring Deployment" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

try {
    # Ensure we're logged in to Azure
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "No Azure context found. Please run Connect-AzAccount first." -ForegroundColor Red
        exit 1
    }

    # Set the subscription context
    Write-Host "Setting subscription context to: $SubscriptionId" -ForegroundColor Yellow
    Set-AzContext -SubscriptionId $SubscriptionId

    # Check if resource group exists, create if not
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Host "Creating resource group: $ResourceGroupName in $Location" -ForegroundColor Yellow
        if (-not $WhatIf) {
            New-AzResourceGroup -Name $ResourceGroupName -Location $Location
        }
    } else {
        Write-Host "Using existing resource group: $ResourceGroupName" -ForegroundColor Green
    }

    # Prepare deployment parameters
    $deploymentParams = @{
        resourceGroupName = $ResourceGroupName
        location = $Location
        appInsightsName = $AppInsightsName
        logAnalyticsWorkspaceName = $LogAnalyticsWorkspaceName
        criticalAlertsEmail = $CriticalAlertsEmail
        performanceAlertsEmail = $PerformanceAlertsEmail
    }

    if ($SlackWebhookUrl) {
        $deploymentParams.slackWebhookUrl = $SlackWebhookUrl
    }

    if ($TeamsWebhookUrl) {
        $deploymentParams.teamsWebhookUrl = $TeamsWebhookUrl
    }

    # Deploy monitoring infrastructure
    $deploymentName = "spe-monitoring-deployment-$(Get-Date -Format 'yyyyMMddHHmmss')"
    $bicepFile = Join-Path $PSScriptRoot "DeployMonitoring.bicep"

    Write-Host "Deploying monitoring infrastructure..." -ForegroundColor Yellow
    Write-Host "Deployment name: $deploymentName" -ForegroundColor Gray

    if ($WhatIf) {
        Write-Host "WhatIf mode - would deploy with parameters:" -ForegroundColor Magenta
        $deploymentParams | Format-Table -AutoSize

        # Validate the deployment
        $validation = Test-AzResourceGroupDeployment `
            -ResourceGroupName $ResourceGroupName `
            -TemplateFile $bicepFile `
            -TemplateParameterObject $deploymentParams

        if ($validation) {
            Write-Host "Deployment validation failed:" -ForegroundColor Red
            $validation | Format-List
            exit 1
        } else {
            Write-Host "Deployment validation passed!" -ForegroundColor Green
        }
    } else {
        $deployment = New-AzResourceGroupDeployment `
            -Name $deploymentName `
            -ResourceGroupName $ResourceGroupName `
            -TemplateFile $bicepFile `
            -TemplateParameterObject $deploymentParams `
            -Verbose

        if ($deployment.ProvisioningState -eq "Succeeded") {
            Write-Host "Monitoring infrastructure deployed successfully!" -ForegroundColor Green

            # Output key information
            Write-Host "`nDeployment Outputs:" -ForegroundColor Cyan
            Write-Host "Application Insights ID: $($deployment.Outputs.appInsightsId.Value)" -ForegroundColor White
            Write-Host "Application Insights Connection String: $($deployment.Outputs.appInsightsConnectionString.Value)" -ForegroundColor White
            Write-Host "Log Analytics Workspace ID: $($deployment.Outputs.logAnalyticsWorkspaceId.Value)" -ForegroundColor White

            # Save connection string for easy access
            $connectionString = $deployment.Outputs.appInsightsConnectionString.Value
            $envFile = Join-Path $PSScriptRoot "..\src\Spe.Bff.Api\.env.monitoring"
            "APPLICATIONINSIGHTS_CONNECTION_STRING=$connectionString" | Out-File -FilePath $envFile -Encoding utf8
            Write-Host "Connection string saved to: $envFile" -ForegroundColor Green

        } else {
            Write-Host "Deployment failed with state: $($deployment.ProvisioningState)" -ForegroundColor Red
            exit 1
        }
    }

    # Deploy workbook
    Write-Host "`nDeploying operational dashboard workbook..." -ForegroundColor Yellow
    $workbookFile = Join-Path $PSScriptRoot "OperationalDashboard.workbook"

    if (Test-Path $workbookFile) {
        $workbookContent = Get-Content $workbookFile -Raw

        # Replace placeholder values
        $workbookContent = $workbookContent.Replace('{subscription-id}', $SubscriptionId)
        $workbookContent = $workbookContent.Replace('{resource-group}', $ResourceGroupName)
        $workbookContent = $workbookContent.Replace('{app-insights-name}', $AppInsightsName)

        $workbookName = "SPE-OperationalDashboard"
        $workbookPath = Join-Path $PSScriptRoot "$workbookName.json"
        $workbookContent | Out-File -FilePath $workbookPath -Encoding utf8

        if (-not $WhatIf) {
            # Deploy workbook using REST API (as there's no direct PowerShell cmdlet)
            Write-Host "Workbook template prepared: $workbookPath" -ForegroundColor Green
            Write-Host "Please import this workbook manually through the Azure portal." -ForegroundColor Yellow
        }
    }

    Write-Host "`n=============================================" -ForegroundColor Cyan
    Write-Host "Deployment Complete!" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan

    if (-not $WhatIf) {
        Write-Host "`nNext steps:" -ForegroundColor Yellow
        Write-Host "1. Update your API application configuration with the Application Insights connection string" -ForegroundColor White
        Write-Host "2. Import the workbook template from: $(Join-Path $PSScriptRoot 'SPE-OperationalDashboard.json')" -ForegroundColor White
        Write-Host "3. Verify alert rules are working by checking the Azure portal" -ForegroundColor White
        Write-Host "4. Test webhook integrations (Slack/Teams) if configured" -ForegroundColor White
    }

} catch {
    Write-Host "Error during deployment: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "`nFor troubleshooting, check the Azure Activity Log for deployment details." -ForegroundColor Gray