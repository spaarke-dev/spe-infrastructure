@description('Name prefix for resources (e.g., spe-dev)')
param namePrefix string
@description('Location for all resources')
param location string
@description('App Service Plan SKU (e.g., P1v3)')
param planSkuName string = 'P1v3'
param planSkuTier string = 'PremiumV3'
param planCapacity int = 1
@description('UAMI name')
param uamiName string
@description('Key Vault name (globally unique if creating new)')
param kvName string
@description('Web App name (globally unique)')
param webAppName string
@description('Allowed CORS origins (comma-separated)')
param corsAllowedOrigins string = 'https://localhost:5173'
@description('Application Insights name')
param aiName string
module uami 'modules/uami.bicep' = { name: '${namePrefix}-uami', params: { name: uamiName, location: location } }
module plan 'modules/plan.bicep' = { name: '${namePrefix}-plan', params: { name: '${namePrefix}-asp', location: location, skuName: planSkuName, skuTier: planSkuTier, capacity: planCapacity } }
module insights 'modules/insights.bicep' = { name: '${namePrefix}-ai', params: { name: aiName, location: location } }
module keyvault 'modules/keyvault.bicep' = { name: '${namePrefix}-kv', params: { name: kvName, location: location } }
module webapp 'modules/webapp.bicep' = { name: '${namePrefix}-web', params: { name: webAppName, location: location, planId: plan.outputs.id, uamiId: uami.outputs.id, uamiClientId: uami.outputs.clientId, appInsightsConnectionString: insights.outputs.connectionString, corsAllowedOrigins: corsAllowedOrigins }, dependsOn: [ keyvault ] }
resource kvSecretsUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kvName, 'KeyVaultSecretsUser', uamiName)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions','4633458b-17de-408a-b874-0445c86b69e6')
    principalId: uami.outputs.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    keyvault
  ]
}
output webAppId string = webapp.outputs.id
output uamiPrincipalId string = uami.outputs.principalId
output uamiClientId string = uami.outputs.clientId
output keyVaultId string = keyvault.outputs.id
output appInsightsId string = insights.outputs.id
output planId string = plan.outputs.id
