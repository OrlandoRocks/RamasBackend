# frozen_string_literal: true

# Description: Land model that represents a land plot with geometry support.
class Land < ApplicationRecord
  belongs_to :residential

  has_one :contract, dependent: :nullify
  has_one :client, through: :contract
  has_many :payments, dependent: :nullify

  def as_geojson_feature
    return nil unless geometry

    {
      type: "Feature",
      geometry: RGeo::GeoJSON.encode(geometry),
      properties: {
        id: id,
        land_code: land_code,
        address: address,
        block: block,
        size: size,
        price: price&.to_f,
        house_number: house_number,
        residential_id: residential_id,
        has_contract: contract.present?,
        client_name: client&.full_name
      }
    }
  end
end
