# Vue 2 — Per-residential map (Martin Option A)

Copy everything inside the fenced block below into your **Vue 2 frontend** repo (Cursor/agent chat).

---

```markdown
# Task: Per-residential map with Martin server filter (Option A)

## Backend status (already done in RamasBackend)

**Option A is implemented** on the API/PostGIS side. You only need to change the **Vue 2 frontend**.

| Backend piece | Status |
|---------------|--------|
| `lands_mvt(z,x,y,query)` with `?residential_id=` | Done |
| `GET /residentials/:id` → `map_center`, `map_bounds`, `map_zoom_hint`, `martin_lands_tile_url` | Done |
| Martin `lands` source in `martin/martin.yaml` | Done |

Run on backend if not migrated yet: `bin/rails db:migrate`

Restart Martin after deploy:

```bash
pkill -f "martin --config martin/martin.yaml"
DATABASE_URL="postgresql://USER@localhost:5432/ramas_dev" martin --config martin/martin.yaml
```

Verify:

```bash
curl http://localhost:3030/catalog
# must include "lands"

curl -o /dev/null -w "%{http_code}\n" \
  "http://localhost:3030/lands/14/3325/6843?residential_id=3"
# expect 200 (non-empty tile for Valle Dorado)
```

---

## What to implement in Vue 2

### Rule 1 — One Martin layer, filter on the server

Do **not** create a separate Martin config per residential.

Use the tile URL from the API (includes `residential_id`):

```text
{VUE_APP_MARTIN_URL}/lands/{z}/{x}/{y}?residential_id={id}
```

Or use the ready-made field from `GET /residentials/:id`:

```json
"martin_lands_tile_url": "http://localhost:3030/lands/{z}/{x}/{y}?residential_id=3"
```

### Rule 2 — MapLibre coordinates are [lng, lat]

```js
center: residential.map_center   // e.g. [-106.918749, 28.38777]
// NOT [28.38777, -106.918749]
```

### Rule 3 — Use `lands`, not `geo_layers`

Parcels imported via `POST /lands/import_shapefile` appear in the **`lands`** tile layer only.

### Rule 4 — When residential changes, update tiles + camera

1. `GET /residentials/:id`
2. `map.getSource('lands').setTiles([residential.martin_lands_tile_url])`
3. `map.fitBounds(...)` from `map_bounds`

---

## Environment

```env
VUE_APP_MARTIN_URL=http://localhost:3030
VUE_APP_API_URL=http://localhost:3000
```

Production: set `MARTIN_TILE_URL` on the Rails host if you override the default in `martin_lands_tile_url`.

---

## API contract

### `GET /residentials/:id` (authenticated)

Relevant fields:

| Field | Type | Usage |
|-------|------|--------|
| `id` | number | `residential_id` in tile URL |
| `map_center` | `[lng, lat]` | `flyTo` / initial `center` |
| `map_bounds` | `[west, south, east, north]` | `fitBounds` |
| `map_zoom_hint` | number | maxZoom hint after fitBounds |
| `martin_lands_tile_url` | string | **Pass to MapLibre `tiles` array as-is** |

Example:

```json
{
  "id": 3,
  "name": "Valle Dorado",
  "map_center": [-106.918749, 28.38777],
  "map_bounds": [-106.920527, 28.386587, -106.91697, 28.388952],
  "map_zoom_hint": 15,
  "martin_lands_tile_url": "http://localhost:3030/lands/{z}/{x}/{y}?residential_id=3"
}
```

### Optional GeoJSON overlays (Bearer token)

| Endpoint | Purpose |
|----------|---------|
| `GET /residentials/:id/geojson` | Red dashed boundary |
| `GET /residentials/:id/lands_geojson` | Full parcel GeoJSON (fallback if Martin down) |

---

## Replace existing map code

Search the frontend for:

- `geo_layers` vector source → change to **`lands`** for parcel maps
- Single `user_id` / one owner on residential → unrelated; keep map work focused on tiles
- Hard-coded center (e.g. Mexico City `-99.15, 19.42`) → remove; use API fields
- Tile URL without query string → **must** add `?residential_id=${id}`

---

## `ResidentialMap.vue` (Options API + MapLibre GL JS)

```vue
<template>
  <div ref="mapContainer" class="residential-map" />
</template>

<script>
import maplibregl from 'maplibre-gl'

export default {
  name: 'ResidentialMap',
  props: {
    residentialId: { type: [Number, String], required: true }
  },
  data() {
    return {
      map: null,
      residential: null,
      martinBase: process.env.VUE_APP_MARTIN_URL || 'http://localhost:3030'
    }
  },
  watch: {
    residentialId: {
      immediate: true,
      handler() {
        this.loadResidential()
      }
    }
  },
  mounted() {
    this.initMap()
  },
  beforeDestroy() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  },
  methods: {
    async loadResidential() {
      try {
        const { data } = await this.$http.get(`/residentials/${this.residentialId}`)
        this.residential = data
        this.applyResidentialToMap()
      } catch (e) {
        console.error('Failed to load residential for map', e)
      }
    },

    landsTileUrl(residential) {
      if (residential.martin_lands_tile_url) {
        return residential.martin_lands_tile_url
      }
      return `${this.martinBase}/lands/{z}/{x}/{y}?residential_id=${residential.id}`
    },

    initMap() {
      this.map = new maplibregl.Map({
        container: this.$refs.mapContainer,
        style: {
          version: 8,
          sources: {
            osm: {
              type: 'raster',
              tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
              tileSize: 256,
              attribution: '© OpenStreetMap'
            }
          },
          layers: [
            { id: 'osm', type: 'raster', source: 'osm' }
          ]
        },
        center: [-106.92, 28.39],
        zoom: 14
      })

      this.map.on('load', () => {
        if (this.residential) this.applyResidentialToMap()
      })
    },

    applyResidentialToMap() {
      const r = this.residential
      if (!r || !this.map) return

      const tiles = [this.landsTileUrl(r)]
      const sourceId = 'lands'

      if (this.map.getSource(sourceId)) {
        this.map.getSource(sourceId).setTiles(tiles)
      } else {
        this.map.addSource(sourceId, { type: 'vector', tiles })
        this.map.addLayer({
          id: 'lands-fill',
          type: 'fill',
          source: sourceId,
          'source-layer': 'lands',
          paint: { 'fill-color': '#2a9d8f', 'fill-opacity': 0.45 }
        })
        this.map.addLayer({
          id: 'lands-outline',
          type: 'line',
          source: sourceId,
          'source-layer': 'lands',
          paint: { 'line-color': '#1d3557', 'line-width': 1.5 }
        })
      }

      if (r.map_bounds && r.map_bounds.length === 4) {
        this.map.fitBounds(
          [
            [r.map_bounds[0], r.map_bounds[1]],
            [r.map_bounds[2], r.map_bounds[3]]
          ],
          { padding: 48, duration: 800, maxZoom: r.map_zoom_hint || 16 }
        )
      } else if (r.map_center) {
        this.map.flyTo({
          center: r.map_center,
          zoom: r.map_zoom_hint || 15,
          duration: 800
        })
      }
    }
  }
}
</script>

<style scoped>
.residential-map {
  width: 100%;
  height: 400px;
}
</style>
```

### Parent view / router

```vue
<ResidentialMap v-if="residentialId" :residential-id="residentialId" />
```

When navigating from residential 1 → 3, only change the prop; the watcher reloads tiles with the new `?residential_id=`.

---

## Spanish UI labels (optional)

| Context | Label |
|---------|--------|
| Map section title | **Plano del fraccionamiento** |
| Loading | Cargando mapa… |
| No geometry | No hay geometría cargada para este desarrollo |
| Map error | No se pudo cargar el mapa |

---

## Do NOT use Option B unless debugging

Option B (client-side filter only, no query param) still downloads other developments' parcels in shared tiles. **Use Option A** (`?residential_id=`) for all residential detail screens.

---

## Checklist

- [ ] `bin/rails db:migrate` on backend
- [ ] Martin restarted; `/catalog` lists `lands`
- [ ] Map component uses `martin_lands_tile_url` or `?residential_id=`
- [ ] `source-layer` is **`lands`**
- [ ] `fitBounds` / `center` from API (`map_bounds` / `map_center`)
- [ ] Removing hard-coded CDMX / default centers
- [ ] On residential change: `setTiles` + `fitBounds` again
- [ ] Auth header on Rails GeoJSON requests (Martin tiles are usually public; lock down in production if needed)

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| 404 `/lands/...` | Restart Martin with updated `martin.yaml` |
| 204 / empty tiles | No lands geometry; import shapefile with `POST /lands/import_shapefile` |
| Map in ocean / Africa | Swapped lat/lng |
| Wrong development parcels | Missing `?residential_id=` on tile URL |
| Martin SQL error | Run latest migration `fix_lands_mvt_json_query_operator` |

```
