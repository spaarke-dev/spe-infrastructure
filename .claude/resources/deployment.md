# deployment (app service / functions)

## prerequisites
- resource group, app service (or functions), user-assigned mi.
- key vault for obo secret/cert (if obo is used).
- app registration for api (confidential client for obo only).

## steps
1) **attach mi**
   - assign the user-assigned mi to the app service/functions.
2) **permissions**
   - entra: grant mi **graph application** role `filestoragecontainer.selected`; admin consent.
   - spe: register container type; grant mi container-type permissions (create/readcontent/writecontent as needed).
   - grant Graph delegated permissions for OBO
3) **Key valut reference**
4) **config**
   - app settings: `uami_client_id`, `tenant_id`, `api_app_id` (+ key vault references if obo).54) **deploy**
   - `dotnet publish -c release`
   - zip deploy or github actions with environment-specific slots.
6) **post-deploy**
   - validate `/ping`, then container create and small upload paths.
   - verify 403s for missing graph role vs missing container-type permission.
