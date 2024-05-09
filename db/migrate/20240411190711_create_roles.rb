# frozen_string_literal: true

# Description: Migration to create the roles table.
class CreateRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :roles do |t|
      t.string :name

      t.timestamps
    end
  end
end
