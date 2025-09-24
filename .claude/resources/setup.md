# setup (local & cloud)

## local dev
- .net 8/9 sdk, node 18+ (for spa), azure cli (`az login`).
- run spa on :3000; api on :5088 (or functions :7071).
- `uami_client_id` is not required locally; `defaultazurecredential` will use developer creds.
- create `.env` for spa and `appsettings.development.json` for api.

## azure prep
1) create user-assigned mi and attach to app service/functions.
2) app registration (api) – confidential client **only if** you need obo.
3) key vault – store obo secret/cert if applicable.
4) spe container type – create/register; grant mi the needed container-type permissions.

## app settings (api)
- `uami_client_id` (required in azure)
- `tenant_id`, `api_app_id` (and key vault references for obo secret if used)
- `default_ct_id`
- 'api_app_id', 'tenant_id' (and Key Vault reference for api_client_secret (cloud only))

## first run tests
- `get /ping` → 200
- `post /api/containers` (mi) → 201
- `put /api/containers/{id}/files/test.txt` (mi) → 200
- `get /api/drives/{driveid}/children` → 200
