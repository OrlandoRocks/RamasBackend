# frozen_string_literal: true

class GeoLayer < ApplicationRecord
  belongs_to :residential, optional: true

  validates :name, presence: true
  validates :geometry, presence: true

  scope :by_type, ->(type) { where(layer_type: type) if type.present? }
  scope :with_residential, ->(residential_id) { where(residential_id: residential_id) if residential_id.present? }

  def as_geojson_feature
    {
      type: "Feature",
      geometry: RGeo::GeoJSON.encode(geometry),
      properties: properties.merge(
        id: id,
        name: name,
        layer_type: layer_type,
        residential_id: residential_id
      )
    }
  end
end
