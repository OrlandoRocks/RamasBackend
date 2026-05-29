# frozen_string_literal: true

class GeoLayerSerializer < ActiveModel::Serializer
  attributes :id, :name, :layer_type, :description, :properties, :residential_id, :created_at, :updated_at

  attribute :geometry_type do
    object.geometry&.geometry_type&.to_s
  end

  attribute :geojson do
    object.as_geojson_feature if instance_options[:include_geojson]
  end

  belongs_to :residential, optional: true
end
