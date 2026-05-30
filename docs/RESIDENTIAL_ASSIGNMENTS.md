# Residential assignments & client visibility

## Overview

- **`residential_assignments`**: many-to-many between `users` (sellers/admins) and `residentials`.
- **`residential_clients`**: many-to-many between `clients` and `residentials` (CRM visibility).

`residentials.user_id` was removed. Historical owners were copied into `residential_assignments`.

## API

### Residentials

```json
PATCH /residentials/1
{
  "residential": {
    "name": "Bosques",
    "user_ids": [2, 5, 9]
  }
}
```

Response includes `user_ids` and `assigned_users` (id, name, email, role_name).  
`user_id` / `user_full_name` remain for backward compatibility (first assignee).

### Clients

- Visible only if linked via `residential_clients` and the user is assigned to that residential.
- Auto-linked when a **contract** is saved (`land.residential` + `client`).
- Optional manual link: `client[residential_ids][]` on create/update.

### Users (super_user)

```json
PATCH /users/1
{
  "user": {
    "residential_ids": [1, 2, 3]
  }
}
```

## Authorization

| Role | Residentials | Clients |
|------|--------------|---------|
| super_user | All | All |
| admin / seller | Assigned only | Linked to assigned residentials only |
| client | — | Own contracts/payments only |

## Post-migration note

If you use a `residentials_tiles` DB view (e.g. Martin), recreate it without `user_id` after migrating.

## Frontend

Copy-paste Vue 2 integration task: **`docs/VUE2_RESIDENTIAL_ASSIGNMENTS.md`**

## Map tiles (Martin)

Land parcels imported via `POST /lands/import_shapefile` are served as vector tiles:

- Tile URL: `http://localhost:3030/lands/{z}/{x}/{y}?residential_id=<id>`
- `GET /residentials/:id` includes `map_center`, `map_bounds`, `martin_lands_tile_url`
- Frontend guide: **`docs/VUE2_MARTIN_RESIDENTIAL_MAPS.md`**
- Testing: **`docs/POSTGIS_MARTIN_TESTING_GUIDE.md`**
