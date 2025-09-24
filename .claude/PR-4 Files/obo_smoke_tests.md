# obo smoke tests — user-enforced crud

> purpose: verify that SPE enforces the **user's** permissions through the OBO endpoints.

## prerequisites
- Two users:
  - **User A**: has access to the target container/item.
  - **User B**: does **not** have access.
- Each user can obtain an access token for **your API** (audience = your API app id/uri).
- A container + drive already exist (from MI flows).

## env (bash)
```bash
export API_BASE="https://<yourapp>.azurewebsites.net"
export TOKEN_A="<api-token-for-user-a>"
export TOKEN_B="<api-token-for-user-b>"
export CONTAINER_ID="<target-container-id>"
export DRIVE_ID="<drive-id-for-container>"
export ITEM_ID="<existing-item-id>"
```

## list as user (expect A=200, B=403)
```bash
curl -i -H "Authorization: Bearer $TOKEN_A" "$API_BASE/api/obo/containers/$CONTAINER_ID/children"
curl -i -H "Authorization: Bearer $TOKEN_B" "$API_BASE/api/obo/containers/$CONTAINER_ID/children"
```

## download (or upload) as user
```bash
# download
curl -i -H "Authorization: Bearer $TOKEN_A" "$API_BASE/api/obo/drives/$DRIVE_ID/items/$ITEM_ID/content"

# or upload
echo "hello obo $(date -u +%FT%TZ)" > hello.txt
curl -i -X PUT -H "Authorization: Bearer $TOKEN_A" -H "Content-Type: text/plain"   --data-binary @hello.txt "$API_BASE/api/obo/containers/$CONTAINER_ID/files/folder1/hello.txt"
```

## failure decoding
- **401** — API token missing/invalid (audience must be your API).
- **403 + Authorization_RequestDenied** — delegated Graph consent/permissions missing on your API app registration.
- **403 (no Authorization_RequestDenied)** — user lacks SPE permission on the container/item.

## done
- A succeeds; B denied with RFC7807 (includes `graphRequestId`).
