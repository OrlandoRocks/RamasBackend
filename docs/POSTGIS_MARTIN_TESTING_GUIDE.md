# PostGIS + Martin Integration Testing Guide

This guide explains how to test the PostGIS and Martin integration for serving shapefiles as vector tiles to a Vue2 frontend using MapLibre.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Step 1: Install Dependencies](#step-1-install-dependencies)
4. [Step 2: Verify PostGIS](#step-2-verify-postgis)
5. [Step 3: Run Migrations](#step-3-run-migrations)
6. [Step 4: Start Rails Server](#step-4-start-rails-server)
7. [Step 5: Test Authentication](#step-5-test-authentication)
8. [Step 6: Test GeoLayer API](#step-6-test-geolayer-api)
9. [Step 7: Test Shapefile Import](#step-7-test-shapefile-import)
10. [Step 8: Test Martin Server](#step-8-test-martin-server)
11. [Step 9: Test Frontend Integration](#step-9-test-frontend-integration)
12. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              DATA FLOW                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│   1. UPLOAD                2. STORE               3. SERVE              │
│   ┌─────────┐             ┌─────────┐            ┌─────────┐            │
│   │  .shp   │  ────────▶  │ PostGIS │  ────────▶ │  Martin │            │
│   │  file   │   Rails     │   DB    │   reads    │ Server  │            │
│   └─────────┘   API       └─────────┘   tables   └─────────┘            │
│                                                       │                  │
│                                                       │ vector tiles     │
│                                                       ▼                  │
│                                               ┌─────────────┐            │
│                                               │  Vue2 App   │            │
│                                               │  MapLibre   │            │
│                                               └─────────────┘            │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### What Each Component Does:

| Component | Purpose |
|-----------|---------|
| **Rails API** | Handles shapefile uploads, parses them with RGeo, stores geometries in PostGIS |
| **PostGIS** | PostgreSQL extension that adds support for geographic objects (points, lines, polygons) |
| **Martin** | Lightweight vector tile server that reads PostGIS tables and serves them as .pbf tiles |
| **MapLibre** | Open-source map rendering library (fork of Mapbox GL JS) that displays vector tiles |

---

## Prerequisites

Before testing, ensure you have:

- Ruby 3.2.2
- PostgreSQL with PostGIS extension
- Bundler
- curl (for API testing)

---

## Step 1: Install Dependencies

### What we're testing:
The Ruby gems required for PostGIS and shapefile handling are installed correctly.

### Why it matters:
Without these gems, we can't parse shapefiles or store geometry data.

### Commands:

```bash
cd /Users/odela3/RubymineProjects/RamasBackend
bundle install
```

### Expected output:
```
Installing activerecord-postgis-adapter x.x.x
Installing rgeo x.x.x
Installing rgeo-shapefile x.x.x
Installing rgeo-geojson x.x.x
Installing rubyzip x.x.x
Bundle complete!
```

### Key gems installed:

| Gem | Purpose |
|-----|---------|
| `activerecord-postgis-adapter` | Allows Rails to use PostGIS column types (geometry, geography) |
| `rgeo` | Ruby library for handling geometric data |
| `rgeo-shapefile` | Parses ESRI Shapefile format (.shp, .shx, .dbf) |
| `rgeo-geojson` | Converts between RGeo objects and GeoJSON format |
| `rubyzip` | Extracts uploaded .zip files containing shapefiles |

---

## Step 2: Verify PostGIS

### What we're testing:
PostGIS extension is installed and enabled in PostgreSQL.

### Why it matters:
PostGIS provides the geometry column types and spatial functions needed to store and query geographic data.

### Command:

```bash
psql -U odela3 -d ramas_dev -c "SELECT PostGIS_Version();"
```

### Expected output:
```
            postgis_version            
---------------------------------------
 3.x USE_GEOS=1 USE_PROJ=1 USE_STATS=1
(1 row)
```

### If PostGIS is not installed:

```bash
# On macOS with Homebrew
brew install postgis

# Enable extension in database
psql -U odela3 -d ramas_dev -c "CREATE EXTENSION IF NOT EXISTS postgis;"
```

---

## Step 3: Run Migrations

### What we're testing:
Database tables are created with geometry columns and spatial indexes.

### Why it matters:
We need geometry columns to store the shapefile data, and spatial indexes for efficient querying.

### Command:

```bash
bundle exec rails db:migrate
```

### Verify the tables were created correctly:

```bash
# Check lands table has geometry column
psql -U odela3 -d ramas_dev -c "\d lands"
```

### Expected output (partial):
```
     Column     |              Type              
----------------+--------------------------------
 id             | bigint                         
 geometry       | geography(Geometry,4326)       
...
Indexes:
    "index_lands_on_geometry" gist (geometry)
```

### What the migration creates:

| Table | Column | Type | Purpose |
|-------|--------|------|---------|
| `lands` | `geometry` | `geography(Geometry,4326)` | Stores land plot boundaries |
| `residentials` | `boundary` | `geography(Geometry,4326)` | Stores residential development boundaries |
| `geo_layers` | `geometry` | `geography(Geometry,4326)` | Stores imported shapefile features |

**Note:** SRID 4326 is the WGS84 coordinate system (latitude/longitude) used by GPS.

---

## Step 4: Start Rails Server

### What we're testing:
The Rails server starts without errors and can accept requests.

### Why it matters:
The API endpoints must be running to accept shapefile uploads and serve GeoJSON.

### Command:

```bash
bundle exec rails s -b 0.0.0.0 -p 3000
```

### Expected output:
```
=> Booting Puma
=> Rails 7.0.x application starting in development
=> Run `bin/rails server --help` for more startup options
Puma starting in single mode...
* Listening on http://0.0.0.0:3000
```

### Quick health check:

```bash
curl http://localhost:3000/login -d ""
```

If the server is running, you'll get a JSON error response (which is expected since we didn't provide credentials).

---

## Step 5: Test Authentication

### What we're testing:
We can obtain a JWT token to authenticate API requests.

### Why it matters:
All API endpoints require authentication. We need a valid token to test the geo endpoints.

### Command:

```bash
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@user.com", "password": "password"}'
```

### Expected output:
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "admin@user.com",
    ...
  }
}
```

### Save the token for subsequent tests:

```bash
# Store token in environment variable
export TOKEN="eyJhbGciOiJIUzI1NiJ9..."
```

---

## Step 6: Test GeoLayer API

### 6.1 List GeoLayers

#### What we're testing:
The `/geo_layers` endpoint returns all stored geographic layers.

#### Command:

```bash
curl -X GET http://localhost:3000/geo_layers \
  -H "Authorization: Bearer $TOKEN"
```

#### Expected output:
```json
[]
```
(Empty array if no layers have been imported yet)

---

### 6.2 Get GeoJSON

#### What we're testing:
The `/geo_layers/geojson` endpoint returns data in GeoJSON format that MapLibre can consume.

#### Why it matters:
GeoJSON is the standard format for geographic data on the web. MapLibre needs valid GeoJSON to render features.

#### Command:

```bash
curl -X GET http://localhost:3000/geo_layers/geojson \
  -H "Authorization: Bearer $TOKEN"
```

#### Expected output:
```json
{
  "type": "FeatureCollection",
  "features": []
}
```

#### GeoJSON Structure Explained:

```json
{
  "type": "FeatureCollection",     // Always "FeatureCollection" for multiple features
  "features": [
    {
      "type": "Feature",           // Each item is a "Feature"
      "geometry": {
        "type": "Polygon",         // Geometry type: Point, LineString, Polygon, MultiPolygon, etc.
        "coordinates": [...]       // Array of coordinate pairs [longitude, latitude]
      },
      "properties": {              // Arbitrary properties/attributes
        "id": 1,
        "name": "Parcel A",
        "area": 500
      }
    }
  ]
}
```

---

### 6.3 Create a GeoLayer via Rails Console (Optional)

#### What we're testing:
We can create geometry data programmatically.

#### Command:

```bash
bundle exec rails runner '
factory = RGeo::Geographic.spherical_factory(srid: 4326)
polygon = factory.parse_wkt("POLYGON((-99.15 19.42, -99.14 19.42, -99.14 19.43, -99.15 19.43, -99.15 19.42))")

layer = GeoLayer.create!(
  name: "Test Layer",
  layer_type: "parcels",
  geometry: polygon,
  properties: { "test_prop" => "value1" }
)

puts "Created GeoLayer ID: #{layer.id}"
puts "GeoJSON: #{layer.as_geojson_feature.to_json}"
'
```

---

## Step 7: Test Shapefile Import

### 7.1 Create a Test Shapefile

#### What we're testing:
We can create a valid shapefile for testing purposes.

#### Why it matters:
Shapefiles consist of multiple files (.shp, .shx, .dbf, .prj) that must all be present.

#### Command:

```bash
cd /Users/odela3/RubymineProjects/RamasBackend/tmp

# Create a GeoJSON file
cat > test_parcels.geojson << 'EOF'
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {"name": "Parcel 1", "area": 100, "land_code": "P001"},
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[-99.16, 19.41], [-99.15, 19.41], [-99.15, 19.42], [-99.16, 19.42], [-99.16, 19.41]]]
      }
    },
    {
      "type": "Feature",
      "properties": {"name": "Parcel 2", "area": 150, "land_code": "P002"},
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[-99.15, 19.41], [-99.14, 19.41], [-99.14, 19.42], [-99.15, 19.42], [-99.15, 19.41]]]
      }
    }
  ]
}
EOF

# Convert to shapefile using ogr2ogr (requires GDAL)
mkdir -p test_shapefile
ogr2ogr -f "ESRI Shapefile" test_shapefile/parcels.shp test_parcels.geojson

# Create a zip file
zip -j test_parcels.zip test_shapefile/*
```

### Shapefile Components:

| File | Purpose |
|------|---------|
| `.shp` | Contains the geometry data (points, lines, polygons) |
| `.shx` | Index file for quick access to geometry features |
| `.dbf` | dBASE table containing attribute data (properties) |
| `.prj` | Contains the coordinate system/projection information |

---

### 7.2 Preview Shapefile

#### What we're testing:
The API can read and preview a shapefile's contents without importing it.

#### Why it matters:
This allows users to inspect the shapefile's attributes before deciding to import.

#### Command:

```bash
curl -X POST http://localhost:3000/geo_layers/preview_shapefile \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/Users/odela3/RubymineProjects/RamasBackend/tmp/test_parcels.zip"
```

#### Expected output:
```json
{
  "total_records": 2,
  "preview": [
    {
      "index": 0,
      "geometry_type": "MultiPolygon",
      "attributes": {
        "name": "Parcel 1",
        "area": 100,
        "land_code": "P001"
      }
    },
    {
      "index": 1,
      "geometry_type": "MultiPolygon",
      "attributes": {
        "name": "Parcel 2",
        "area": 150,
        "land_code": "P002"
      }
    }
  ],
  "attributes": ["name", "area", "land_code"]
}
```

---

### 7.3 Import Shapefile

#### What we're testing:
The API can import a shapefile into the PostGIS database.

#### Why it matters:
This is the core functionality - converting shapefiles to PostGIS data that Martin can serve.

#### Command:

```bash
curl -X POST http://localhost:3000/geo_layers/import_shapefile \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@/Users/odela3/RubymineProjects/RamasBackend/tmp/test_parcels.zip" \
  -F "name=Test Parcels" \
  -F "layer_type=parcels"
```

#### Expected output:
```json
{
  "message": "Successfully imported 2 features",
  "imported_count": 2
}
```

---

### 7.4 Verify Import

#### What we're testing:
The imported data is correctly stored in PostGIS with geometry.

#### Command:

```bash
curl -X GET "http://localhost:3000/geo_layers/geojson?layer_type=parcels" \
  -H "Authorization: Bearer $TOKEN"
```

#### Expected output:
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "MultiPolygon",
        "coordinates": [[[[-99.16, 19.41], [-99.15, 19.41], ...]]]
      },
      "properties": {
        "id": 1,
        "name": "Parcel 1",
        "layer_type": "parcels",
        ...
      }
    },
    ...
  ]
}
```

---

## Step 8: Test Martin Server

### 8.1 Install Martin

#### What we're testing:
Martin tile server is installed and can connect to PostGIS.

#### Why it matters:
Martin reads PostGIS tables and serves them as vector tiles (.pbf) that MapLibre can render efficiently.

#### Installation (macOS):

```bash
brew install maplibre/martin/martin
```

#### Alternative (Docker):

```bash
docker run -p 3030:3000 \
  -e DATABASE_URL=postgresql://odela3@host.docker.internal:5432/ramas_dev \
  ghcr.io/maplibre/martin
```

---

### 8.2 Start Martin

#### Command:

```bash
cd /Users/odela3/RubymineProjects/RamasBackend
martin --config martin/martin.yaml "postgresql://odela3@localhost:5432/ramas_dev"
```

#### Expected output:
```
Martin server starting at 0.0.0.0:3000
Discovered table: public.lands
Discovered table: public.geo_layers
Discovered table: public.residentials
```

---

### 8.3 Test Martin Endpoints

#### Get Catalog:

```bash
curl http://localhost:3030/catalog
```

**What this tests:** Martin discovered the PostGIS tables with geometry columns.

**Expected output:**
```json
{
  "tiles": {
    "geo_layers": {...},
    "lands": {...},
    "residentials": {...}
  }
}
```

---

#### Get TileJSON:

```bash
curl http://localhost:3030/geo_layers
```

**What this tests:** Martin can generate TileJSON metadata for MapLibre.

**Expected output:**
```json
{
  "tilejson": "3.0.0",
  "tiles": ["http://localhost:3030/geo_layers/{z}/{x}/{y}"],
  "minzoom": 0,
  "maxzoom": 22,
  ...
}
```

---

#### Get a Vector Tile:

```bash
# Get tile at zoom 14 for Mexico City area
curl http://localhost:3030/geo_layers/14/3756/6876.pbf -o test_tile.pbf
ls -la test_tile.pbf
```

**What this tests:** Martin can generate actual vector tile data.

**Expected output:** A binary .pbf file (Protobuf format)

---

## Step 9: Test Frontend Integration

### 9.1 Create Test HTML File

#### What we're testing:
MapLibre can consume vector tiles from Martin and render them on a map.

#### Create file:

```bash
cat > /Users/odela3/RubymineProjects/RamasBackend/public/test-map.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>PostGIS + Martin Test</title>
  <script src="https://unpkg.com/maplibre-gl@3.6.0/dist/maplibre-gl.js"></script>
  <link href="https://unpkg.com/maplibre-gl@3.6.0/dist/maplibre-gl.css" rel="stylesheet" />
  <style>
    body, html { margin: 0; padding: 0; height: 100%; }
    #map { width: 100%; height: 100%; }
    #info { position: absolute; top: 10px; left: 10px; background: white; padding: 10px; border-radius: 5px; z-index: 1; }
  </style>
</head>
<body>
  <div id="info">
    <strong>PostGIS + Martin Test</strong><br>
    Click on parcels to see properties
  </div>
  <div id="map"></div>
  <script>
    const MARTIN_URL = 'http://localhost:3030';
    
    const map = new maplibregl.Map({
      container: 'map',
      style: {
        version: 8,
        sources: {
          // Base map tiles (OpenStreetMap)
          osm: {
            type: 'raster',
            tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
            tileSize: 256,
            attribution: '© OpenStreetMap contributors'
          },
          // Vector tiles from Martin
          geo_layers: {
            type: 'vector',
            url: MARTIN_URL + '/geo_layers'
          },
          lands: {
            type: 'vector',
            url: MARTIN_URL + '/lands'
          }
        },
        layers: [
          // Base map layer
          {
            id: 'osm-tiles',
            type: 'raster',
            source: 'osm'
          },
          // GeoLayers fill
          {
            id: 'geo-layers-fill',
            type: 'fill',
            source: 'geo_layers',
            'source-layer': 'geo_layers',
            paint: {
              'fill-color': '#088',
              'fill-opacity': 0.5
            }
          },
          // GeoLayers outline
          {
            id: 'geo-layers-outline',
            type: 'line',
            source: 'geo_layers',
            'source-layer': 'geo_layers',
            paint: {
              'line-color': '#000',
              'line-width': 2
            }
          },
          // Lands fill (different color)
          {
            id: 'lands-fill',
            type: 'fill',
            source: 'lands',
            'source-layer': 'lands',
            paint: {
              'fill-color': '#f80',
              'fill-opacity': 0.5
            }
          }
        ]
      },
      center: [-99.15, 19.42],  // Centered on test data (Mexico City area)
      zoom: 14
    });

    // Add click handler to show feature properties
    map.on('click', 'geo-layers-fill', (e) => {
      const props = e.features[0].properties;
      new maplibregl.Popup()
        .setLngLat(e.lngLat)
        .setHTML(`
          <strong>${props.name || 'Unknown'}</strong><br>
          Type: ${props.layer_type || 'N/A'}<br>
          ID: ${props.id || 'N/A'}
        `)
        .addTo(map);
    });

    // Change cursor on hover
    map.on('mouseenter', 'geo-layers-fill', () => {
      map.getCanvas().style.cursor = 'pointer';
    });
    map.on('mouseleave', 'geo-layers-fill', () => {
      map.getCanvas().style.cursor = '';
    });

    // Add navigation controls
    map.addControl(new maplibregl.NavigationControl());
  </script>
</body>
</html>
EOF
```

---

### 9.2 Test in Browser

1. Make sure Rails server is running on port 3000
2. Make sure Martin is running on port 3030
3. Open in browser: `http://localhost:3000/test-map.html`

#### What you should see:
- OpenStreetMap base map
- Cyan polygons for geo_layers
- Orange polygons for lands
- Click on a polygon to see its properties

---

## Troubleshooting

### Problem: PostGIS extension not found

```bash
# Install PostGIS
brew install postgis

# Enable in database
psql -U odela3 -d ramas_dev -c "CREATE EXTENSION IF NOT EXISTS postgis;"
```

---

### Problem: Migration fails with "geometry type not found"

Make sure `config/database.yml` uses the `postgis` adapter:

```yaml
default: &default
  adapter: postgis  # NOT postgresql
  ...
```

---

### Problem: Shapefile import fails with "cannot load such file -- zip"

```bash
bundle install  # Ensure rubyzip is installed
# Restart Rails server after installing
```

---

### Problem: Martin can't connect to database

Check connection string:
```bash
# Test connection
psql "postgresql://odela3@localhost:5432/ramas_dev" -c "SELECT 1;"

# If password is required
martin "postgresql://odela3:yourpassword@localhost:5432/ramas_dev"
```

---

### Problem: Martin doesn't see tables

Tables must have a geometry/geography column. Check:
```bash
psql -U odela3 -d ramas_dev -c "
  SELECT table_name, column_name, udt_name 
  FROM information_schema.columns 
  WHERE udt_name IN ('geometry', 'geography');
"
```

---

### Problem: MapLibre shows blank map

1. Check browser console for errors (F12)
2. Verify Martin is running: `curl http://localhost:3030/catalog`
3. Check CORS is enabled in Martin config
4. Verify tile URL is correct in browser network tab

---

## API Reference

### Endpoints Created

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/geo_layers` | List all geo layers |
| GET | `/geo_layers/:id` | Get single geo layer |
| GET | `/geo_layers/geojson` | Get all layers as GeoJSON |
| POST | `/geo_layers` | Create a geo layer |
| POST | `/geo_layers/import_shapefile` | Import shapefile to geo_layers |
| POST | `/geo_layers/preview_shapefile` | Preview shapefile contents |
| PUT | `/geo_layers/:id` | Update geo layer |
| DELETE | `/geo_layers/:id` | Delete geo layer |
| GET | `/lands?format=geojson` | Get lands as GeoJSON |
| POST | `/lands/import_shapefile` | Import shapefile to lands |
| GET | `/residentials/:id/geojson` | Get residential boundary as GeoJSON |
| GET | `/residentials/:id/lands_geojson` | Get lands for a residential as GeoJSON |

### Query Parameters

| Parameter | Endpoint | Description |
|-----------|----------|-------------|
| `layer_type` | `/geo_layers`, `/geo_layers/geojson` | Filter by layer type |
| `residential_id` | `/geo_layers`, `/geo_layers/geojson` | Filter by residential |
| `format=geojson` | `/lands` | Return lands as GeoJSON |

---

## Files Changed/Created

### New Files

| File | Purpose |
|------|---------|
| `app/models/geo_layer.rb` | Model for storing shapefile features |
| `app/controllers/geo_layers_controller.rb` | API endpoints for geo layers |
| `app/serializers/geo_layer_serializer.rb` | JSON serialization |
| `app/services/shapefile_import_service.rb` | Shapefile parsing logic |
| `db/migrate/20260226000001_enable_postgis_and_add_geometry.rb` | Adds geometry columns |
| `db/migrate/20260226000002_create_geo_layers.rb` | Creates geo_layers table |
| `martin/martin.yaml` | Martin server configuration |

### Modified Files

| File | Changes |
|------|---------|
| `Gemfile` | Added PostGIS and shapefile gems |
| `config/database.yml` | Changed adapter to `postgis` |
| `config/routes.rb` | Added geo_layers routes |
| `app/models/land.rb` | Added geometry support and GeoJSON method |
| `app/models/residential.rb` | Added boundary geometry and GeoJSON methods |
| `app/controllers/lands_controller.rb` | Added shapefile import |
| `app/controllers/residentials_controller.rb` | Added GeoJSON endpoints |
| `docker-compose.yml` | Added PostGIS images and Martin service |

---

## Next Steps

After completing all tests successfully:

1. **Production Setup**: Configure Martin in production with proper CORS and SSL
2. **Vue2 Integration**: Create Vue components using MapLibre GL JS
3. **Performance**: Add caching headers to Martin responses
4. **Security**: Add authentication to Martin if needed (via nginx proxy)
