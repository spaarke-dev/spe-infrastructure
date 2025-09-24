# SPE Infrastructure Monitoring & Alerting

This directory contains the complete monitoring and alerting infrastructure for the SharePoint Embedded (SPE) API platform.

## Overview

The monitoring setup provides comprehensive operational visibility including:
- **Real-time dashboards** for API performance, file operations, and system health
- **Proactive alerting** for critical issues, performance degradation, and security events
- **KQL queries** for deep analytics and troubleshooting
- **Infrastructure as Code** for repeatable deployments

## Components

### 1. KQL Queries (`KqlQueries.kql`)
Pre-built KQL queries for:
- API performance metrics (response times, error rates)
- Rate limiting analysis and violations
- Graph API integration health
- File operations analytics (uploads/downloads)
- Authentication & authorization monitoring
- System health & resource usage
- Critical alerts (high error rates, dependency failures)

### 2. Alert Rules (`AlertRules.json`)
Configured alerts for:
- **Critical (Severity 1-2)**: High error rates, Graph API failures, performance issues
- **Warning (Severity 3)**: Rate limit violations, resource usage patterns
- **Action Groups**: Email, Slack, Teams integrations

### 3. Operational Dashboard (`OperationalDashboard.workbook`)
Azure Monitor workbook with tabs for:
- **API Performance**: Request counts, success rates, response times
- **File Operations**: Upload/download analytics, range request patterns
- **System Health**: Graph API health, resource utilization
- **Security & Auth**: Authentication failures, rate limiting

### 4. Infrastructure Deployment
- **Bicep template** (`DeployMonitoring.bicep`): Complete infrastructure as code
- **PowerShell script** (`Deploy-Monitoring.ps1`): Automated deployment with validation

## Quick Start

### Prerequisites
- Azure PowerShell module installed
- Appropriate Azure permissions (Contributor on resource group)
- SharePoint Embedded API deployed with Application Insights

### Deploy Monitoring Infrastructure

```powershell
# Example deployment
.\Deploy-Monitoring.ps1 `
    -SubscriptionId "your-subscription-id" `
    -ResourceGroupName "spe-monitoring-rg" `
    -Location "eastus" `
    -AppInsightsName "spe-api-insights" `
    -LogAnalyticsWorkspaceName "spe-logs-workspace" `
    -CriticalAlertsEmail "sre-team@company.com" `
    -PerformanceAlertsEmail "dev-team@company.com" `
    -SlackWebhookUrl "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" `
    -TeamsWebhookUrl "https://company.webhook.office.com/YOUR/TEAMS/WEBHOOK"

# Validate deployment (dry run)
.\Deploy-Monitoring.ps1 -WhatIf [other parameters...]
```

### Configure Your API Application

After deployment, update your API application configuration:

```json
{
  "ApplicationInsights": {
    "ConnectionString": "[OUTPUT FROM DEPLOYMENT]"
  },
  "Logging": {
    "ApplicationInsights": {
      "LogLevel": {
        "Default": "Information",
        "Microsoft": "Warning"
      }
    }
  }
}
```

## Alert Configuration

### Severity Levels
- **Severity 1**: Critical system failures (Graph API down, widespread errors)
- **Severity 2**: Performance degradation (high response times, error rate spikes)
- **Severity 3**: Warning conditions (rate limit violations, resource usage)

### Alert Thresholds
| Alert | Threshold | Window | Frequency |
|-------|-----------|--------|-----------|
| High Error Rate | >5% errors | 5 minutes | 5 minutes |
| High Response Time | P95 >5 seconds | 5 minutes | 5 minutes |
| Graph API Failures | >20% failures | 5 minutes | 5 minutes |
| Rate Limit Violations | >50 violations | 10 minutes | 10 minutes |
| Upload Failures | >15% failures | 10 minutes | 10 minutes |

## Key Metrics

### API Performance
- **Request Volume**: Total requests per endpoint per time window
- **Success Rate**: Percentage of successful requests (non-4xx/5xx)
- **Response Time**: Average, P95, P99 response times
- **Error Rate**: Percentage of failed requests by endpoint

### File Operations
- **Upload Performance**: Success rates, throughput (MB/s), chunk success
- **Download Analytics**: Range request patterns, cache hit rates
- **Content Distribution**: File size patterns, operation types

### System Health
- **Graph API Integration**: Dependency success rates, response times
- **Resource Usage**: Memory, CPU, connection pool health
- **Authentication**: Token validation rates, OBO success

## Troubleshooting

### Common Query Patterns

**Find recent errors:**
```kql
AppExceptions
| where TimeGenerated > ago(1h)
| where AppRoleName == "Spe.Bff.Api"
| summarize count() by Type, OuterMessage
| order by count_ desc
```

**Analyze slow requests:**
```kql
AppRequests
| where TimeGenerated > ago(1h)
| where AppRoleName == "Spe.Bff.Api"
| where DurationMs > 5000
| extend Endpoint = tostring(Properties["EndpointName"])
| order by DurationMs desc
```

**Check Graph API health:**
```kql
AppDependencies
| where TimeGenerated > ago(1h)
| where Type == "Http" and Target contains "graph.microsoft.com"
| summarize
    SuccessRate = (countif(Success == true) * 100.0) / count(),
    AvgDuration = avg(DurationMs)
    by tostring(Properties["GraphOperation"])
```

### Alert Investigation

When alerts fire:

1. **Check the dashboard** for immediate context
2. **Review related metrics** in the same time window
3. **Examine application logs** for detailed error information
4. **Verify Graph API status** if dependency alerts fire
5. **Check rate limiting** if performance issues occur

## Dashboard Access

After deployment:
1. Navigate to Azure Portal → Monitor → Workbooks
2. Import the generated workbook JSON file
3. Pin key charts to your Azure Dashboard
4. Set up automated reports if needed

## Maintenance

### Regular Tasks
- Review alert thresholds monthly
- Update dashboard queries based on new features
- Rotate webhook URLs for security
- Archive old log data based on retention policies

### Scaling Considerations
- Increase Log Analytics workspace tier for higher volume
- Adjust alert frequencies during high-traffic periods
- Consider custom metrics for business-specific KPIs

## Integration Examples

### Slack Alert Formatting
```json
{
  "text": "🚨 SPE API Alert",
  "attachments": [{
    "color": "danger",
    "fields": [{
      "title": "Error Rate Spike",
      "value": "API experiencing 8.5% error rate",
      "short": true
    }]
  }]
}
```

### Teams Webhook Integration
Configure webhook URL in action groups for rich notifications with charts and quick actions.

## Security Considerations

- **Webhook URLs**: Store securely, rotate regularly
- **Email Recipients**: Use distribution lists, not individual addresses
- **Access Control**: Limit workbook and alert rule modifications
- **Data Privacy**: Ensure queries don't expose sensitive data

## Support

For issues with monitoring setup:
1. Check Azure Activity Log for deployment errors
2. Verify Application Insights telemetry flow
3. Test alert rules manually through Azure portal
4. Review webhook connectivity and formatting

---

**Version**: 1.0
**Last Updated**: January 2025
**Maintained by**: SPE Infrastructure Team