# frozen_string_literal: true

# Optional ?residential_id= query param for Martin (per-development tile filtering).
class AddResidentialFilterToLandsMvt < ActiveRecord::Migration[7.0]
  def up
    execute "DROP FUNCTION IF EXISTS public.lands_mvt(integer, integer, integer);"

    execute <<~'SQL'
      CREATE OR REPLACE FUNCTION public.lands_mvt(
        z integer,
        x integer,
        y integer,
        query json DEFAULT '{}'::json
      )
      RETURNS bytea
      LANGUAGE plpgsql
      STABLE
      PARALLEL SAFE
      AS $function$
      DECLARE
        mvt bytea;
        bounds geometry;
        residential_filter bigint;
      BEGIN
        bounds := ST_TileEnvelope(z, x, y);

        IF (query->>'residential_id') IS NOT NULL AND (query->>'residential_id') ~ '^[0-9]+$' THEN
          residential_filter := (query->>'residential_id')::bigint;
        ELSE
          residential_filter := NULL;
        END IF;

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
            AND (residential_filter IS NULL OR residential_id = residential_filter)
        ) AS q;
        RETURN COALESCE(mvt, '\x'::bytea);
      END;
      $function$;
    SQL
  end

  def down
    execute "DROP FUNCTION IF EXISTS public.lands_mvt(integer, integer, integer, json);"

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
end
