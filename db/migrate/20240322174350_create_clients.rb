# frozen_string_literal: true

# Description: Migration that creates the clients table.
class CreateClients < ActiveRecord::Migration[7.0]
  def change # rubocop:disable Metrics/MethodLength
    create_table :clients do |t|
      t.string :code
      t.string :full_name
      t.string :identification_card
      t.string :rfc
      t.string :address
      t.string :colony
      t.string :zip_code
      t.string :phone_number
      t.string :city
      t.string :state
      t.string :country
      t.string :assignee
      t.string :email
      t.date :birthday
      t.string :nationality
      t.string :civil_status
      t.string :spouse
      t.boolean :economic_dependants
      t.boolean :home_owner
      t.string :occupation
      t.string :company
      t.string :company_address
      t.string :company_phone
      t.decimal :monthly_income
      t.decimal :monthly_expenses
      t.text :comments
      t.string :image

      t.timestamps
    end
  end
end
