# frozen_string_literal: true

require "rgeo/shapefile"

class ShapefileImportService
  class ImportError < StandardError; end

  attr_reader :shp_path, :options, :errors

  def initialize(shp_path, options = {})
    @shp_path = shp_path
    @options = options
    @errors = []
  end

  def import_to_geo_layers(name:, layer_type: nil, residential_id: nil)
    validate_file_exists!
    
    imported_layers = []

    RGeo::Shapefile::Reader.open(shp_path, factory: geo_factory) do |file|
      file.each do |record|
        next unless record&.geometry

        layer = GeoLayer.new(
          name: build_feature_name(name, record, imported_layers.size),
          layer_type: layer_type,
          description: options[:description],
          properties: extract_properties(record),
          geometry: record.geometry,
          residential_id: residential_id
        )

        if layer.save
          imported_layers << layer
        else
          @errors << { index: record.index, errors: layer.errors.full_messages }
        end
      end
    end

    {
      success: errors.empty?,
      imported_count: imported_layers.size,
      errors: errors,
      layers: imported_layers
    }
  rescue StandardError => e
    raise ImportError, "Failed to import shapefile: #{e.message}"
  end

  def import_to_lands(residential_id:, mapping: {})
    validate_file_exists!

    imported_lands = []

    RGeo::Shapefile::Reader.open(shp_path, factory: geo_factory) do |file|
      file.each do |record|
        next unless record&.geometry

        attributes = map_attributes(record, mapping)
        attributes[:residential_id] = residential_id
        attributes[:geometry] = record.geometry

        land = Land.new(attributes)

        if land.save
          imported_lands << land
        else
          @errors << { index: record.index, errors: land.errors.full_messages }
        end
      end
    end

    {
      success: errors.empty?,
      imported_count: imported_lands.size,
      errors: errors,
      lands: imported_lands
    }
  rescue StandardError => e
    raise ImportError, "Failed to import shapefile to lands: #{e.message}"
  end

  def preview(limit: 10)
    validate_file_exists!

    features = []

    RGeo::Shapefile::Reader.open(shp_path, factory: geo_factory) do |file|
      file.each_with_index do |record, index|
        break if index >= limit
        next unless record

        features << {
          index: record.index,
          geometry_type: record.geometry&.geometry_type&.to_s,
          attributes: extract_properties(record)
        }
      end

      {
        total_records: file.num_records,
        preview: features,
        attributes: file.num_records.positive? ? features.first&.dig(:attributes)&.keys : []
      }
    end
  rescue StandardError => e
    raise ImportError, "Failed to preview shapefile: #{e.message}"
  end

  private

  def geo_factory
    @geo_factory ||= RGeo::Geographic.spherical_factory(srid: 4326)
  end

  def validate_file_exists!
    raise ImportError, "Shapefile not found: #{shp_path}" unless File.exist?(shp_path)

    shx_path = shp_path.sub(/\.shp$/i, ".shx")
    dbf_path = shp_path.sub(/\.shp$/i, ".dbf")

    raise ImportError, "Missing .shx file" unless File.exist?(shx_path)
    raise ImportError, "Missing .dbf file" unless File.exist?(dbf_path)
  end

  def extract_properties(record)
    return {} unless record.respond_to?(:attributes)

    record.attributes.transform_keys(&:to_s)
  end

  def build_feature_name(base_name, record, index)
    if record.attributes && record.attributes["name"]
      record.attributes["name"].to_s
    elsif record.attributes && record.attributes["NAME"]
      record.attributes["NAME"].to_s
    else
      "#{base_name}_#{index + 1}"
    end
  end

  def map_attributes(record, mapping)
    attributes = {}
    props = extract_properties(record)

    mapping.each do |land_attr, shp_attr|
      attributes[land_attr.to_sym] = props[shp_attr.to_s] if props.key?(shp_attr.to_s)
    end

    attributes
  end
end
