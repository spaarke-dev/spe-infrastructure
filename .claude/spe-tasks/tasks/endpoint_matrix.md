# endpoint → auth mode matrix

| endpoint                                              | auth mode | why                                                             |
|-------------------------------------------------------|-----------|------------------------------------------------------------------|
| POST /api/containers                                   | MI        | platform/admin op; no per-user enforcement required              |
| GET  /api/containers?containerTypeId=                  | MI        | metadata listing for system ops                                  |
| GET  /api/containers/{id}/drive                        | MI        | drive id lookup                                                  |
| PUT  /api/containers/{id}/files/{*path}                | MI        | service upload (e.g., automated ingest)                          |
| POST /api/drives/{driveId}/upload                      | MI        | large file upload (service)                                      |
| GET  /api/obo/containers/{id}/children                 | OBO       | must enforce user’s SPE permission to list                       |
| GET  /api/obo/drives/{driveId}/items/{itemId}          | OBO       | item metadata as user                                            |
| GET  /api/obo/drives/{driveId}/items/{itemId}/content  | OBO       | download as user                                                 |
| PUT  /api/obo/containers/{id}/files/{*path}            | OBO       | upload as user                                                   |
| DELETE /api/obo/drives/{driveId}/items/{itemId}        | OBO       | delete as user                                                   |
