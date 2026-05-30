# Vue 2 — Residential assignments & client visibility

Copy the markdown block below into your **Vue 2 frontend** repo (Cursor/agent chat).

---

```markdown
# Task: Residential multi-assignment & client visibility (Vue 2)

Implement UI for assigning **multiple staff/sellers** to a residential development and linking **clients** to developments, aligned with RamasBackend. Follow existing patterns (Options API, axios, Vuex auth, Vuetify/Bootstrap multi-select if present).

## Breaking change (important)

- `residentials.user_id` and single `user_full_name` are **deprecated**.
- Use **`user_ids`** (array) and **`assigned_users`** on residential JSON.
- `user_id` / `user_full_name` still exist for backward compatibility (= first assignee only). **Do not** build new UI on a single owner dropdown.

## Visibility rules (must match API — UI is not security)

| role-name (`user.attributes['role-name']`) | Residentials list | Clients list |
|------------------------------------------|-------------------|--------------|
| `super_user` | All | All |
| `admin`, `user` (vendedor) | Only **assigned** developments | Only clients linked to **assigned** developments |
| `client` | N/A (portal) | Own data only |

- `GET /residentials` and `GET /clients` are already **scoped** server-side.
- Empty lists are normal if the user has no assignments — show empty state, not “load all”.
- On **403**: `{ "error": "No estas autorizado para realizar esta accion!" }`

---

## 1. Residential form — assign staff (`user_ids`)

### Spanish UI

| Field | Label |
|-------|--------|
| Multi-select | **Personal asignado** or **Vendedores y administradores** |
| Helper text | Selecciona quién puede ver y gestionar este desarrollo. |

### API

**Load (show/edit):**

```http
GET /residentials/:id
Authorization: Bearer <token>
```

Response (relevant fields):

```json
{
  "id": 1,
  "name": "Bosques del Norte",
  "user_ids": [2, 5, 9],
  "assigned_users": [
    { "id": 2, "name": "Ana", "last_name": "López", "email": "ana@...", "role_name": "user" },
    { "id": 5, "name": "Luis", "last_name": "Ruiz", "email": "luis@...", "role_name": "admin" }
  ],
  "user_id": 2,
  "user_full_name": "Ana López"
}
```

**Save:**

```http
POST /residentials
PATCH /residentials/:id
Content-Type: application/json

{
  "residential": {
    "name": "Bosques del Norte",
    "address": "...",
    "cost": 1000000,
    "user_ids": [2, 5, 9]
  }
}
```

- Only users with roles **`user`**, **`admin`**, or **`super_user`** are accepted (sellers/admins). Client-role users must not appear in the picker.
- Omitting `user_ids` on PATCH leaves assignments unchanged.
- Sending `user_ids: []` clears all assignments (allowed for super_user; confirm in UI).

### Staff picker data source

`GET /users` is **super_user only**. For residential forms used by admin/seller:

- **Option A (recommended):** Dedicated endpoint or include assignable users in residential meta (if you add it).
- **Option B:** Cache staff list from a prior super_user screen.
- **Option C:** `GET /users` only when `isSuperUser`, else show read-only chips from `assigned_users` on edit (admin cannot reassign without super_user — match your product rule).

Populate multi-select **value** = `user.id`, **label** = `"${name} ${last_name} (${email}) — ${roleLabel}"` where `roleLabel`: `user` → Vendedor, `admin` → Administrador, `super_user` → Super usuario.

### Vue 2 example (Vuetify 2)

```vue
<v-select
  v-model="form.user_ids"
  :items="staffOptions"
  item-text="label"
  item-value="id"
  label="Personal asignado"
  multiple
  chips
  deletable-chips
  hint="Quién puede ver y gestionar este desarrollo"
  persistent-hint
/>
```

```js
// After GET residential
this.form.user_ids = data.user_ids || []

// On save
await api.patch(`/residentials/${id}`, {
  residential: { ...this.form, user_ids: this.form.user_ids }
})
```

### List / cards

- Show **multiple** assignees (chips or comma-separated from `assigned_users`).
- Stop showing a single “Propietario” from `user_full_name` unless as fallback for old cached data.

---

## 2. Client form — link developments (`residential_ids`)

### Spanish UI

| Field | Label |
|-------|--------|
| Multi-select | **Desarrollos** or **Fraccionamientos vinculados** |
| Helper text | El cliente solo será visible para el personal asignado a estos desarrollos. |

### API

```http
GET /clients/:id
```

Includes `residential_ids: [1, 3]`.

```http
POST /clients
PATCH /clients/:id

{
  "client": {
    "full_name": "Juan Pérez",
    "email": "juan@example.com",
    "residential_ids": [1, 3]
  }
}
```

- Omitting `residential_ids` on PATCH does not change links.
- **Auto-link:** Creating/updating a **contract** links the client to the land’s residential on the server — no extra UI required for that path.
- Manual multi-select is for CRM visibility before contracts exist or for multiple developments.

### Picker options

`GET /residentials` (scoped) — use returned list for options:

- `item-value`: `id`
- `item-text`: `name`

Only developments the current user can see appear (correct for admin/seller).

---

## 3. User management (super_user) — assign developments

### Spanish UI

| Field | Label |
|-------|--------|
| Multi-select | **Desarrollos asignados** |
| Helper text | Restringe qué fraccionamientos y clientes puede ver este usuario. |

### API (JSON:API)

```http
GET /users/:id
PATCH /users/:id

{
  "user": {
    "name": "...",
    "role_id": 2,
    "residential_ids": [1, 2, 3]
  }
}
```

- **`residential_ids`** on `UserSerializer` (attributes include `residential_ids`).
- **Do not** show this field for `role-name === 'client'` (portal users use `client_id`, not residential assignments).
- `GET /users` meta includes `roles` for role dropdown.

```js
// JSON:API parse
const attrs = response.data.data.attributes
this.form.residential_ids = attrs['residential_ids'] || []

// PATCH
await api.patch(`/users/${id}`, {
  user: {
    name: attrs.name,
    role_id: attrs['role-id'],
    residential_ids: this.form.residential_ids
  }
})
```

---

## 4. RBAC helpers (Vuex / composable)

Extend existing permission helpers:

```js
const ROLE = {
  SUPER: 'super_user',
  ADMIN: 'admin',
  SELLER: 'user',
  CLIENT: 'client'
}

export function canManageResidentialAssignments(user) {
  // Product: super_user always; admin if your policy allows PATCH with user_ids
  return user?.roleName === ROLE.SUPER || user?.roleName === ROLE.ADMIN
}

export function canManageClientResidentialLinks(user) {
  return [ROLE.SUPER, ROLE.ADMIN].includes(user?.roleName)
}

export function canManageUserResidentialAssignments(user) {
  return user?.roleName === ROLE.SUPER
}
```

Hide assignment controls when `false`; still handle 403 from API.

---

## 5. UX checklist

- [ ] Residential create/edit: multi-select `user_ids`, display `assigned_users` on detail
- [ ] Remove/replace legacy single-owner dropdown bound to `user_id`
- [ ] Client create/edit: multi-select `residential_ids` (staff only)
- [ ] User edit (super_user): multi-select `residential_ids` for non-client roles
- [ ] Lists respect scoped API (no client-side “show all” fallback)
- [ ] Empty states: “No tienes desarrollos asignados” / “No hay clientes en tus desarrollos”
- [ ] After contract save, refresh client if you show `residential_ids` (server may have auto-linked)
- [ ] Confirm before clearing all `user_ids` on a residential

---

## 6. Error handling

| Status | Action |
|--------|--------|
| 401 | Redirect to login |
| 403 | Toast: *No estás autorizado para realizar esta acción* |
| 422 | Show `errors` / model validation messages |

---

## 7. Testing (manual / e2e)

1. **Seller A** assigned only to Residential 1 → sees only those clients linked to Residential 1.
2. **Seller B** on Residential 2 → does not see Residential 1 clients.
3. **Both** assigned to same residential → both see shared client list.
4. **super_user** sees all; can assign users to developments via User + Residential forms.
5. PATCH residential with `user_ids` updates assignees; GET returns matching `assigned_users`.

---

## Reference

Backend docs: `docs/RESIDENTIAL_ASSIGNMENTS.md` in RamasBackend repo.
```
