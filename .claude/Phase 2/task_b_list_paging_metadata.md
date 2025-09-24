# task b — listing with paging, ordering, metadata

## objective
return predictable listings with pagination and basic metadata for spa grids.

## deliverables
- extend `GET /api/obo/containers/{id}/children` to accept:
  - `?top=` (default 50, max 200)
  - `?skip=` (default 0)
  - `?orderBy=name|lastModifiedDateTime|size` (default name)
  - `?orderDir=asc|desc` (default asc)
- response dto for each item:
  - `{ id, name, size, eTag, lastModifiedDateTime, contentType, folder: { childCount? } }`
- include `nextLink` (relative url) when there are more results
- openapi + docs updates

## tests
- default list → <=50 items, sorted by name asc
- `top/skip` works; `nextLink` present when applicable
- `orderBy/dir` produce expected ordering
- 401 if missing bearer; 403 for user without permission

## acceptance criteria
- fast for empty folders; does not fetch content for each item
- obeys rate limits and rfc7807

## prompt
> implement task b exactly. add query params, map to graph list with select/expand as needed, shape dto, and return nextLink. update openapi and add tests for paging, ordering, and 401/403.
