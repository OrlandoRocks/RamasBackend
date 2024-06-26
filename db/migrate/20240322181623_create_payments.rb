# frozen_string_literal: true

# Description: Payment model that belongs to a land.
class CreatePayments < ActiveRecord::Migration[7.0]
  def change
    create_table :payments do |t|
      t.references :land, null: false, foreign_key: true
      t.decimal :amount
      t.date :payment_date
      t.string :payment_type
      t.text :comments
      t.string :image_url
      t.string :status

      t.timestamps
    end
  end
end
