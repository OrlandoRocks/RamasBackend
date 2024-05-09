# frozen_string_literal: true

# Description: Migration to create the users table.
class CreateUser < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :email, null: false, default: ''
      t.string :password_digest, null: false, default: ''
      # Agrega campos adicionales aquí
      t.string :name
      t.string :last_name

      t.index :email, unique: true
      t.timestamps
    end
  end
end
