# frozen_string_literal: true

# Description: AddRoleToUsers migration that adds a role reference to the users table.
class AddRoleToUsers < ActiveRecord::Migration[7.0]
  def change
    add_reference :users, :role, null: false, foreign_key: true
  end
end
