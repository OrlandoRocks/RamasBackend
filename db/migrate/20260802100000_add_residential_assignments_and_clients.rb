# frozen_string_literal: true

class AddResidentialAssignmentsAndClients < ActiveRecord::Migration[7.0]
  def up
    create_table :residential_assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :residential, null: false, foreign_key: true
      t.timestamps
    end

    add_index :residential_assignments, %i[user_id residential_id],
              unique: true,
              name: "index_residential_assignments_on_user_and_residential"

    create_table :residential_clients do |t|
      t.references :client, null: false, foreign_key: true
      t.references :residential, null: false, foreign_key: true
      t.timestamps
    end

    add_index :residential_clients, %i[client_id residential_id],
              unique: true,
              name: "index_residential_clients_on_client_and_residential"

    migrate_residential_owners_to_assignments
    backfill_residential_clients_from_contracts

    # Martin / PostGIS views may reference residentials.user_id
    execute "DROP VIEW IF EXISTS residentials_tiles CASCADE"

    remove_reference :residentials, :user, foreign_key: true
  end

  def down
    add_reference :residentials, :user, foreign_key: true

  execute <<~SQL.squish
      UPDATE residentials r
      SET user_id = ra.user_id
      FROM (
        SELECT DISTINCT ON (residential_id) residential_id, user_id
        FROM residential_assignments
        ORDER BY residential_id, id
      ) ra
      WHERE r.id = ra.residential_id
    SQL

    change_column_null :residentials, :user_id, false

    drop_table :residential_clients
    drop_table :residential_assignments
  end

  private

  def migrate_residential_owners_to_assignments
    return unless column_exists?(:residentials, :user_id)

    execute <<~SQL.squish
      INSERT INTO residential_assignments (user_id, residential_id, created_at, updated_at)
      SELECT user_id, id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM residentials
      WHERE user_id IS NOT NULL
      ON CONFLICT (user_id, residential_id) DO NOTHING
    SQL
  end

  def backfill_residential_clients_from_contracts
    execute <<~SQL.squish
      INSERT INTO residential_clients (client_id, residential_id, created_at, updated_at)
      SELECT DISTINCT c.client_id, l.residential_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM contracts c
      INNER JOIN lands l ON l.id = c.land_id
      WHERE c.client_id IS NOT NULL AND l.residential_id IS NOT NULL
      ON CONFLICT (client_id, residential_id) DO NOTHING
    SQL
  end
end
