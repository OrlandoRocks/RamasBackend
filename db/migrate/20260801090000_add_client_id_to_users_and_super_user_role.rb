# frozen_string_literal: true

class AddClientIdToUsersAndSuperUserRole < ActiveRecord::Migration[7.0]
  def up
    unless column_exists?(:users, :client_id)
      add_reference :users, :client, foreign_key: true, null: true
    end
    Role.find_or_create_by!(name: "super_user")
  end

  def down
    remove_reference :users, :client, foreign_key: true if column_exists?(:users, :client_id)
    Role.find_by(name: "super_user")&.destroy!
  end
end
