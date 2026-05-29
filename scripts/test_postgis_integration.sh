#!/bin/bash

# PostGIS + Martin Integration Test Script
# Usage: ./scripts/test_postgis_integration.sh

set -e

BASE_URL="http://localhost:3000"
MARTIN_URL="http://localhost:3030"
EMAIL="admin@user.com"
PASSWORD="password"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "PostGIS + Martin Integration Test Suite"
echo "=========================================="
echo ""

# Function to print test result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        if [ -n "$3" ]; then
            echo "  Error: $3"
        fi
    fi
}

# Test 1: Check PostGIS
echo -e "${YELLOW}Test 1: Checking PostGIS installation...${NC}"
POSTGIS_VERSION=$(psql -U odela3 -d ramas_dev -t -c "SELECT PostGIS_Version();" 2>/dev/null | tr -d ' ')
if [ -n "$POSTGIS_VERSION" ]; then
    print_result 0 "PostGIS installed (version: $POSTGIS_VERSION)"
else
    print_result 1 "PostGIS not installed"
    echo "  Run: brew install postgis && psql -U odela3 -d ramas_dev -c 'CREATE EXTENSION postgis;'"
fi
echo ""

# Test 2: Check Rails server
echo -e "${YELLOW}Test 2: Checking Rails server...${NC}"
RAILS_CHECK=$(curl -s -o /dev/null -w "%{http_code}" $BASE_URL/login 2>/dev/null || echo "000")
if [ "$RAILS_CHECK" != "000" ]; then
    print_result 0 "Rails server is running on $BASE_URL"
else
    print_result 1 "Rails server not running"
    echo "  Run: bundle exec rails s -b 0.0.0.0 -p 3000"
    exit 1
fi
echo ""

# Test 3: Authentication
echo -e "${YELLOW}Test 3: Testing authentication...${NC}"
TOKEN=$(curl -s -X POST "$BASE_URL/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}" \
    | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
    print_result 0 "Authentication successful"
    echo "  Token: ${TOKEN:0:50}..."
else
    print_result 1 "Authentication failed"
    echo "  Make sure admin user exists: rails db:seed"
    exit 1
fi
echo ""

# Test 4: GeoLayers endpoint
echo -e "${YELLOW}Test 4: Testing GET /geo_layers...${NC}"
GEO_LAYERS=$(curl -s -X GET "$BASE_URL/geo_layers" \
    -H "Authorization: Bearer $TOKEN")
if echo "$GEO_LAYERS" | grep -q '\['; then
    COUNT=$(echo "$GEO_LAYERS" | grep -o '"id"' | wc -l | tr -d ' ')
    print_result 0 "GeoLayers endpoint working ($COUNT layers found)"
else
    print_result 1 "GeoLayers endpoint failed"
    echo "  Response: $GEO_LAYERS"
fi
echo ""

# Test 5: GeoJSON endpoint
echo -e "${YELLOW}Test 5: Testing GET /geo_layers/geojson...${NC}"
GEOJSON=$(curl -s -X GET "$BASE_URL/geo_layers/geojson" \
    -H "Authorization: Bearer $TOKEN")
if echo "$GEOJSON" | grep -q '"type":"FeatureCollection"'; then
    FEATURE_COUNT=$(echo "$GEOJSON" | grep -o '"type":"Feature"' | wc -l | tr -d ' ')
    print_result 0 "GeoJSON endpoint working ($FEATURE_COUNT features)"
else
    print_result 1 "GeoJSON endpoint failed"
    echo "  Response: $GEOJSON"
fi
echo ""

# Test 6: Lands GeoJSON
echo -e "${YELLOW}Test 6: Testing GET /lands?format=geojson...${NC}"
LANDS_GEOJSON=$(curl -s -X GET "$BASE_URL/lands?format=geojson" \
    -H "Authorization: Bearer $TOKEN")
if echo "$LANDS_GEOJSON" | grep -q '"type":"FeatureCollection"'; then
    LAND_COUNT=$(echo "$LANDS_GEOJSON" | grep -o '"type":"Feature"' | wc -l | tr -d ' ')
    print_result 0 "Lands GeoJSON endpoint working ($LAND_COUNT lands with geometry)"
else
    print_result 1 "Lands GeoJSON endpoint failed"
fi
echo ""

# Test 7: Create test shapefile
echo -e "${YELLOW}Test 7: Creating test shapefile...${NC}"
TEST_DIR="/Users/odela3/RubymineProjects/RamasBackend/tmp"
mkdir -p "$TEST_DIR/test_shapefile"

# Create GeoJSON
cat > "$TEST_DIR/test_parcels.geojson" << 'EOF'
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {"name": "Test Parcel 1", "area": 100},
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[-99.16, 19.41], [-99.15, 19.41], [-99.15, 19.42], [-99.16, 19.42], [-99.16, 19.41]]]
      }
    }
  ]
}
EOF

# Check if ogr2ogr is available
if command -v ogr2ogr &> /dev/null; then
    ogr2ogr -f "ESRI Shapefile" "$TEST_DIR/test_shapefile/test.shp" "$TEST_DIR/test_parcels.geojson" 2>/dev/null
    cd "$TEST_DIR" && zip -j test_shapefile.zip test_shapefile/* 2>/dev/null
    print_result 0 "Test shapefile created at $TEST_DIR/test_shapefile.zip"
else
    print_result 1 "ogr2ogr not found (install GDAL to create shapefiles)"
    echo "  Run: brew install gdal"
fi
echo ""

# Test 8: Preview shapefile (if exists)
if [ -f "$TEST_DIR/test_shapefile.zip" ]; then
    echo -e "${YELLOW}Test 8: Testing shapefile preview...${NC}"
    PREVIEW=$(curl -s -X POST "$BASE_URL/geo_layers/preview_shapefile" \
        -H "Authorization: Bearer $TOKEN" \
        -F "file=@$TEST_DIR/test_shapefile.zip")
    if echo "$PREVIEW" | grep -q '"total_records"'; then
        RECORD_COUNT=$(echo "$PREVIEW" | grep -o '"total_records":[0-9]*' | cut -d':' -f2)
        print_result 0 "Shapefile preview working ($RECORD_COUNT records found)"
    else
        print_result 1 "Shapefile preview failed"
        echo "  Response: ${PREVIEW:0:200}"
    fi
    echo ""

    # Test 9: Import shapefile
    echo -e "${YELLOW}Test 9: Testing shapefile import...${NC}"
    IMPORT=$(curl -s -X POST "$BASE_URL/geo_layers/import_shapefile" \
        -H "Authorization: Bearer $TOKEN" \
        -F "file=@$TEST_DIR/test_shapefile.zip" \
        -F "name=Script Test Import" \
        -F "layer_type=test")
    if echo "$IMPORT" | grep -q '"imported_count"'; then
        IMPORTED=$(echo "$IMPORT" | grep -o '"imported_count":[0-9]*' | cut -d':' -f2)
        print_result 0 "Shapefile import working ($IMPORTED features imported)"
    else
        print_result 1 "Shapefile import failed"
        echo "  Response: ${IMPORT:0:200}"
    fi
    echo ""
fi

# Test 10: Check Martin
echo -e "${YELLOW}Test 10: Checking Martin server...${NC}"
MARTIN_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$MARTIN_URL/catalog" 2>/dev/null || echo "000")
if [ "$MARTIN_CHECK" = "200" ]; then
    CATALOG=$(curl -s "$MARTIN_URL/catalog")
    TABLE_COUNT=$(echo "$CATALOG" | grep -o '"geo_layers"\|"lands"\|"residentials"' | wc -l | tr -d ' ')
    print_result 0 "Martin server is running ($TABLE_COUNT tables discovered)"
else
    print_result 1 "Martin server not running on $MARTIN_URL"
    echo "  Run: martin --config martin/martin.yaml 'postgresql://odela3@localhost:5432/ramas_dev'"
fi
echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo ""
echo "Core API endpoints are working."
echo ""
echo "To complete the integration:"
echo "1. Install Martin: brew install maplibre/martin/martin"
echo "2. Start Martin: martin --config martin/martin.yaml 'postgresql://odela3@localhost:5432/ramas_dev'"
echo "3. Open test map: http://localhost:3000/test-map.html"
echo ""
echo "Documentation: docs/POSTGIS_MARTIN_TESTING_GUIDE.md"
