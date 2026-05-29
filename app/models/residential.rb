# frozen_string_literal: true

# Description: Residential model that represents a residential development with boundary geometry.
class Residential < ApplicationRecord
  belongs_to :user

  has_many :lands, dependent: :nullify
  has_many :expenses, dependent: :nullify
  has_many :geo_layers, dependent: :destroy
  has_many :clients, through: :lands
  has_many :contracts, through: :lands
  has_many :payments, through: :contracts

  def as_geojson_feature
    return nil unless boundary

    {
      type: "Feature",
      geometry: RGeo::GeoJSON.encode(boundary),
      properties: {
        id: id,
        name: name,
        address: address,
        cost: cost&.to_f
      }
    }
  end

  def lands_as_geojson
    features = lands.where.not(geometry: nil).map(&:as_geojson_feature).compact
    {
      type: "FeatureCollection",
      features: features
    }
  end
end
