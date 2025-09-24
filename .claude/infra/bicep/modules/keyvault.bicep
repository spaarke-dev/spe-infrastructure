param name string
param location string
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = { name: name, location: location, properties: { tenantId: subscription().tenantId, sku: { name: 'standard', family: 'A' }, enableRbacAuthorization: true, enablePurgeProtection: true, enableSoftDelete: true, softDeleteRetentionInDays: 14, publicNetworkAccess: 'Enabled' } }
output id string = kv.id
