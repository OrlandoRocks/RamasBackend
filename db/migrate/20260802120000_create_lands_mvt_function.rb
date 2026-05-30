# frozen_string_literal: true

# PostGIS function for Martin vector tiles from land parcels (geography → geometry).
class CreateLandsMvtFunction < ActiveRecord::Migration[7.0]
  def up
    execute <<~'SQL'
      CREATE OR REPLACE FUNCTION public.lands_mvt(z integer, x integer, y integer)
      RETURNS bytea
      LANGUAGE plpgsql
      STABLE
      PARALLEL SAFE
      AS $function$
      DECLARE
        mvt bytea;
        bounds geometry;
      BEGIN
        bounds := ST_TileEnvelope(z, x, y);
        SELECT INTO mvt ST_AsMVT(q, 'lands', 4096, 'geom')
        FROM (
          SELECT
            id,
            land_code,
            residential_id,
            block,
            address,
            size,
            price,
            house_number,
            ST_AsMVTGeom(
              ST_Transform(geometry::geometry, 3857),
              bounds,
              4096,
              64,
              true
            ) AS geom
          FROM lands
          WHERE geometry IS NOT NULL
            AND ST_Intersects(ST_Transform(geometry::geometry, 3857), bounds)
        ) AS q;
        RETURN COALESCE(mvt, '\x'::bytea);
      END;
      $function$;
    SQL
  end

  def down
    execute "DROP FUNCTION IF EXISTS public.lands_mvt(integer, integer, integer);"
  end
end
