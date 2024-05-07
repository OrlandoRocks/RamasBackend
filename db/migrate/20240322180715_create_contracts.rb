class CreateContracts < ActiveRecord::Migration[7.0]
  def change
    create_table :contracts do |t|
      t.references :client, null: false, foreign_key: true
      t.references :land, null: false, foreign_key: true
      t.date :contract_date
      t.string :type
      t.decimal :down_payment
      t.decimal :monthly_payment
      t.decimal :yearly_payment
      t.float :months
      t.decimal :penalty_interest
      t.decimal :extraordinary_payment

      t.timestamps
    end
  end
end
