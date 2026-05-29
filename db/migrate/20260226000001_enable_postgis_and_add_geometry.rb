# frozen_string_literal: true

class EnablePostgisAndAddGeometry < ActiveRecord::Migration[7.0]
  def change
    enable_extension "postgis" unless extension_enabled?("postgis")

    # Add geometry column to lands table for individual land plots
    add_column :lands, :geometry, :geometry, geographic: true, srid: 4326

    # Add geometry column to residentials for the overall residential boundary
    add_column :residentials, :boundary, :geometry, geographic: true, srid: 4326

    # Create spatial index for better query performance
    add_index :lands, :geometry, using: :gist
    add_index :residentials, :boundary, using: :gist
  end
end
