# frozen_string_literal: true

# Centroid and bounds for MapLibre / Martin (lng/lat, WGS84).
module ResidentialMapDisplay
  extend ActiveSupport::Concern

  # [longitude, latitude] for MapLibre center / flyTo
  def map_center
    row = extent_row
    return nil unless row && row["lng"] && row["lat"]

    [row["lng"].to_f, row["lat"].to_f]
  end

  # [west, south, east, north] for fitBounds
  def map_bounds
    row = extent_row
    return nil unless row && row["west"]

    [
      row["west"].to_f,
      row["south"].to_f,
      row["east"].to_f,
      row["north"].to_f
    ]
  end

  def map_zoom_hint
    bounds = map_bounds
    return 14 unless bounds

    span = [bounds[2] - bounds[0], bounds[3] - bounds[1]].max
    return 16 if span < 0.002
    return 15 if span < 0.005
    return 14 if span < 0.02

    13
  end

  private

  def extent_row
    @extent_row ||= self.class.connection.select_one(
      ActiveRecord::Base.sanitize_sql_array([
                           <<~SQL.squish,
                             SELECT
                               ST_X(ST_Centroid(ext)) AS lng,
                               ST_Y(ST_Centroid(ext)) AS lat,
                               ST_XMin(ext) AS west,
                               ST_YMin(ext) AS south,
                               ST_XMax(ext) AS east,
                               ST_YMax(ext) AS north
                             FROM (
                               SELECT ST_Extent(geom) AS ext
                               FROM (
                                 SELECT boundary::geometry AS geom
                                 FROM residentials
                                 WHERE id = ? AND boundary IS NOT NULL
                                 UNION ALL
                                 SELECT geometry::geometry AS geom
                                 FROM lands
                                 WHERE residential_id = ? AND geometry IS NOT NULL
                               ) sources
                             ) aggregated
                           SQL
                           id,
                           id
                         ])
    )
  end
end
