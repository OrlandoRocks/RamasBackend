# frozen_string_literal: true

# Fix residential_id filter: json type does not support the ? operator (use ->> only).
class FixLandsMvtJsonQueryOperator < ActiveRecord::Migration[7.0]
  def up
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
        residential_param text;
      BEGIN
        bounds := ST_TileEnvelope(z, x, y);
        residential_param := query->>'residential_id';

        IF residential_param IS NOT NULL AND residential_param ~ '^[0-9]+$' THEN
          residential_filter := residential_param::bigint;
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
    # no-op: previous version had the broken operator
  end
end
