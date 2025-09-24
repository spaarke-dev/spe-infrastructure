# azure permissions checklist (runbook)

## 1) attach user-assigned mi
- attach the UAMI to the app service/functions.

## 2) grant graph application role to mi (filestoragecontainer.selected)
```bash
# login
az login

# ids
UAMI_CLIENT_ID="<your-uami-client-id>"

MI_SP_ID=$(az ad sp show --id $UAMI_CLIENT_ID --query id -o tsv)
GRAPH_SP_ID=$(az ad sp list --filter "appId eq '00000003-0000-0000-c000-000000000000'" --query [0].id -o tsv)

# lookup app role id for FileStorageContainer.Selected (Application)
az rest --method GET --uri https://graph.microsoft.com/v1.0/servicePrincipals/$GRAPH_SP_ID/appRoles   --query "value[?value=='FileStorageContainer.Selected' && contains(allowedMemberTypes, 'Application')].[id,displayName]" -o tsv

APP_ROLE_ID="<paste-id-from-output>"

# create appRoleAssignment (admin consent required in tenant)
az rest --method POST   --uri "https://graph.microsoft.com/v1.0/servicePrincipals/${MI_SP_ID}/appRoleAssignments"   --body "{"principalId":"${MI_SP_ID}","resourceId":"${GRAPH_SP_ID}","appRoleId":"${APP_ROLE_ID}"}"
```

## 3) grant spe container-type permissions to mi
- register your container type in the tenant (owner flow).
- grant MI `Create`, `ReadContent`, `WriteContent` (only what is needed).

## 4) app settings
- set `uami_client_id` in app settings.
- if OBO is used, store confidential client secret/cert in Key Vault and reference from config.

## 5) validate
- `/ping` → 200
- create container (MI) → 201
- upload/list (MI) → 200
- OBO read/write as a user with and without permission → 200/403
