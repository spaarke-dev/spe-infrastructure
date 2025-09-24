# claude code — deploy dev infra (pre-filled)

export SUBSCRIPTION_NAME="Spaarke SPE Subscription 1"
export SUBSCRIPTION_ID="484bc857-3802-427f-9ea5-ca47b43db0f0"
export TENANT_ID="a221a95e-6abc-4434-aecc-e48338a1b2f2"
export RESOURCE_GROUP="SharePointEmbedded"
export LOCATION="eastus"
export KV_NAME="spaarke-spekvcert"
export UAMI_NAME="spaarke-spe-uami-dev"
export WEBAPP_NAME="spaarke-spe-bff-dev"
export AI_NAME="spaarke-spe-ai-dev"
export API_CLIENT_ID="170c98e1-d486-4355-bcbe-170454e0207c"
export CORS_ORIGINS="https://localhost:5173"
export SPE_CONTAINER_TYPE_NAME="Spaarke PAYGO 1"
export SPE_CONTAINER_TYPE_ID="8a6ce34c-6055-4681-8f87-2f4f9f921c06"

az account set --subscription "$SUBSCRIPTION_ID"
cd infra/scripts
./deploy.sh -g "$RESOURCE_GROUP" -l "$LOCATION" -p ../params/dev.bicepparam -s "$SUBSCRIPTION_ID"
# WAIT for me to confirm WHAT-IF
# Then:
# APPLY=1 ./deploy.sh -g "$RESOURCE_GROUP" -l "$LOCATION" -p ../params/dev.bicepparam -s "$SUBSCRIPTION_ID"
