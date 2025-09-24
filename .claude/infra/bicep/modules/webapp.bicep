param name string
param location string
param planId string
param uamiId string
param uamiClientId string
param appInsightsConnectionString string
param corsAllowedOrigins string
resource site 'Microsoft.Web/sites@2023-12-01' = { name: name, location: location, identity: { type: 'UserAssigned', userAssignedIdentities: { '${uamiId}': {} } }, properties: { serverFarmId: planId, httpsOnly: true, siteConfig: { ftpsState: 'Disabled', alwaysOn: true, appSettings: [ { name: 'ASPNETCORE_ENVIRONMENT', value: 'Production' }, { name: 'WEBSITE_RUN_FROM_PACKAGE', value: '0' }, { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: appInsightsConnectionString }, { name: 'Cors__AllowedOrigins', value: corsAllowedOrigins }, { name: 'UAMI_CLIENT_ID', value: uamiClientId } ], cors: { allowedOrigins: split(corsAllowedOrigins, ','), supportCredentials: false } } } }
output id string = site.id
