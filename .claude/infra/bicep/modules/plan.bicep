param name string
param location string
param skuName string
param skuTier string
param capacity int
resource plan 'Microsoft.Web/serverfarms@2023-12-01' = { name: name, location: location, sku: { name: skuName, tier: skuTier, capacity: capacity }, kind: 'linux', properties: { reserved: true } }
output id string = plan.id
