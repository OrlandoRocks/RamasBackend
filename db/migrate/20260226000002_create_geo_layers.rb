# frozen_string_literal: true

class CreateGeoLayers < ActiveRecord::Migration[7.0]
  def change
    create_table :geo_layers do |t|
      t.string :name, null: false
      t.string :layer_type
      t.text :description
      t.jsonb :properties, default: {}
      t.geometry :geometry, geographic: true, srid: 4326
      t.references :residential, foreign_key: true

      t.timestamps
    end

    add_index :geo_layers, :geometry, using: :gist
    add_index :geo_layers, :name
    add_index :geo_layers, :layer_type
  end
end
