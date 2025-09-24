# endpoints (v1)

## health
get /ping → 200

## containers (mi)
get  /api/containers?containertypeid=<ctid>
post /api/containers

## drive (mi)
get /api/containers/{id}/drive  # returns driveid

## files (mi)
put  /api/containers/{id}/files/{*path}          # small upload
post /api/drives/{driveid}/upload                # create upload session + chunk upload
get  /api/drives/{driveid}/children?itemid=<id>  # list children (root if none)

# obo endpoints (user-enforced)
GET  /api/obo/containers/{id}/children
GET  /api/obo/drives/{driveId}/items/{itemId}/content
PUT  /api/obo/containers/{id}/files/{*path}
DELETE /api/obo/drives/{driveId}/items/{itemId}


### notes
- all endpoints enforce api auth + policy checks before graph.
- obo variants may be added where per-user crud is required.
