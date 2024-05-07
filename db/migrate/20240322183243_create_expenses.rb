# frozen_string_literal: true

# Description: Migration to create the expenses table.
class CreateExpenses < ActiveRecord::Migration[7.0]
  def change
    create_table :expenses do |t|
      t.references :residential, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :account
      t.string :department
      t.string :type
      t.string :comments
      t.decimal :amount

      t.timestamps
    end
  end
end
