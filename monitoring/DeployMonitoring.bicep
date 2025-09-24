// ==================================================
// SPE Infrastructure - Monitoring & Alerting Deployment
// ==================================================

@description('The name of the resource group')
param resourceGroupName string

@description('The location for all resources')
param location string = resourceGroup().location

@description('The name of the Application Insights instance')
param appInsightsName string

@description('The name of the Log Analytics workspace')
param logAnalyticsWorkspaceName string

@description('The email address for critical alerts')
param criticalAlertsEmail string

@description('The email address for performance alerts')
param performanceAlertsEmail string

@description('Slack webhook URL for critical alerts (optional)')
param slackWebhookUrl string = ''

@description('Teams webhook URL for performance alerts (optional)')
param teamsWebhookUrl string = ''

// Create Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
    features: {
      immediatePurgeDataOn30Days: true
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Create Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// Action Groups
resource criticalAlertsActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'SPE-CriticalAlerts'
  location: 'global'
  properties: {
    groupShortName: 'SPE-Crit'
    enabled: true
    emailReceivers: [
      {
        name: 'OnCallTeam'
        emailAddress: criticalAlertsEmail
        useCommonAlertSchema: true
      }
    ]
    webhookReceivers: !empty(slackWebhookUrl) ? [
      {
        name: 'SlackIntegration'
        serviceUri: slackWebhookUrl
        useCommonAlertSchema: true
      }
    ] : []
  }
}

resource performanceAlertsActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'SPE-PerformanceAlerts'
  location: 'global'
  properties: {
    groupShortName: 'SPE-Perf'
    enabled: true
    emailReceivers: [
      {
        name: 'DevTeam'
        emailAddress: performanceAlertsEmail
        useCommonAlertSchema: true
      }
    ]
    webhookReceivers: !empty(teamsWebhookUrl) ? [
      {
        name: 'TeamsIntegration'
        serviceUri: teamsWebhookUrl
        useCommonAlertSchema: true
      }
    ] : []
  }
}

resource warningAlertsActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'SPE-WarningAlerts'
  location: 'global'
  properties: {
    groupShortName: 'SPE-Warn'
    enabled: true
    emailReceivers: [
      {
        name: 'DevTeam'
        emailAddress: performanceAlertsEmail
        useCommonAlertSchema: true
      }
    ]
  }
}

// Alert Rules
resource highErrorRateAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'SPE-API-HighErrorRate'
  location: location
  properties: {
    displayName: 'SPE API High Error Rate'
    description: 'Alert when API error rate exceeds 5% over 5 minutes'
    severity: 2
    enabled: true
    scopes: [
      appInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'AppRequests | where TimeGenerated > ago(5m) | where AppRoleName == "Spe.Bff.Api" | extend Endpoint = tostring(Properties["EndpointName"]) | summarize TotalRequests = count(), ErrorRequests = countif(Success == false), ErrorRate = (countif(Success == false) * 100.0) / count() by Endpoint | where TotalRequests >= 10 and ErrorRate > 5.0'
          timeAggregation: 'Count'
          dimensions: [
            {
              name: 'Endpoint'
              operator: 'Include'
              values: ['*']
            }
          ]
          operator: 'GreaterThan'
          threshold: 0
        }
      ]
    }
    actions: {
      actionGroups: [
        criticalAlertsActionGroup.id
      ]
    }
  }
}

resource highResponseTimeAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'SPE-API-HighResponseTime'
  location: location
  properties: {
    displayName: 'SPE API High Response Time'
    description: 'Alert when P95 response time exceeds 5 seconds'
    severity: 2
    enabled: true
    scopes: [
      appInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'AppRequests | where TimeGenerated > ago(5m) | where AppRoleName == "Spe.Bff.Api" | extend Endpoint = tostring(Properties["EndpointName"]) | summarize RequestCount = count(), P95Duration = percentile(DurationMs, 95) by Endpoint | where RequestCount >= 5 and P95Duration > 5000'
          timeAggregation: 'Count'
          dimensions: [
            {
              name: 'Endpoint'
              operator: 'Include'
              values: ['*']
            }
          ]
          operator: 'GreaterThan'
          threshold: 0
        }
      ]
    }
    actions: {
      actionGroups: [
        performanceAlertsActionGroup.id
      ]
    }
  }
}

resource graphApiDependencyFailureAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'SPE-GraphAPI-DependencyFailure'
  location: location
  properties: {
    displayName: 'SPE Graph API Dependency Failure'
    description: 'Alert when Graph API dependency failure rate exceeds 20%'
    severity: 1
    enabled: true
    scopes: [
      appInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          query: 'AppDependencies | where TimeGenerated > ago(5m) | where AppRoleName == "Spe.Bff.Api" | where Type == "Http" and Target contains "graph.microsoft.com" | extend GraphOperation = tostring(Properties["GraphOperation"]) | summarize CallCount = count(), FailureCount = countif(Success == false), FailureRate = (countif(Success == false) * 100.0) / count() by GraphOperation | where CallCount >= 3 and FailureRate > 20.0'
          timeAggregation: 'Count'
          dimensions: [
            {
              name: 'GraphOperation'
              operator: 'Include'
              values: ['*']
            }
          ]
          operator: 'GreaterThan'
          threshold: 0
        }
      ]
    }
    actions: {
      actionGroups: [
        criticalAlertsActionGroup.id
      ]
    }
  }
}

resource rateLimitViolationsAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'SPE-RateLimitViolations'
  location: location
  properties: {
    displayName: 'SPE Rate Limit Violations'
    description: 'Alert on high rate of rate limit violations'
    severity: 3
    enabled: true
    scopes: [
      appInsights.id
    ]
    evaluationFrequency: 'PT10M'
    windowSize: 'PT10M'
    criteria: {
      allOf: [
        {
          query: 'AppTraces | where TimeGenerated > ago(10m) | where AppRoleName == "Spe.Bff.Api" | where Message contains "Rate limit exceeded" | extend PolicyName = tostring(Properties["PolicyName"]) | summarize ViolationCount = count() by PolicyName | where ViolationCount > 50'
          timeAggregation: 'Count'
          dimensions: [
            {
              name: 'PolicyName'
              operator: 'Include'
              values: ['*']
            }
          ]
          operator: 'GreaterThan'
          threshold: 0
        }
      ]
    }
    actions: {
      actionGroups: [
        warningAlertsActionGroup.id
      ]
    }
  }
}

resource uploadFailureSpikeAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'SPE-UploadFailureSpike'
  location: location
  properties: {
    displayName: 'SPE Upload Failure Spike'
    description: 'Alert on spike in upload operation failures'
    severity: 2
    enabled: true
    scopes: [
      appInsights.id
    ]
    evaluationFrequency: 'PT10M'
    windowSize: 'PT10M'
    criteria: {
      allOf: [
        {
          query: 'AppRequests | where TimeGenerated > ago(10m) | where AppRoleName == "Spe.Bff.Api" | where Url contains "/upload" or Url contains "/chunk" | summarize TotalUploads = count(), FailedUploads = countif(Success == false), FailureRate = (countif(Success == false) * 100.0) / count() | where TotalUploads >= 5 and FailureRate > 15.0'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0
        }
      ]
    }
    actions: {
      actionGroups: [
        performanceAlertsActionGroup.id
      ]
    }
  }
}

// Outputs
output appInsightsId string = appInsights.id
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output criticalAlertsActionGroupId string = criticalAlertsActionGroup.id
output performanceAlertsActionGroupId string = performanceAlertsActionGroup.id
output warningAlertsActionGroupId string = warningAlertsActionGroup.id