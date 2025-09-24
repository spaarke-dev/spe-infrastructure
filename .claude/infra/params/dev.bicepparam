using '../bicep/main.bicep'

param namePrefix = 'spaarke-spe-dev'
param location = 'westus2'
param planSkuName = 'P1v3'
param planSkuTier = 'PremiumV3'
param planCapacity = 1
param uamiName = 'spaarke-spe-uami-dev'
param kvName = 'spaarke-spekvcert' // existing Key Vault; review WHAT-IF before applying
param webAppName = 'spaarke-spe-bff-dev'
param corsAllowedOrigins = 'https://localhost:5173'
param aiName = 'spaarke-spe-ai-dev'
