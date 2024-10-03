class AddContractToPayment < ActiveRecord::Migration[7.0]
  def change
    add_reference :payments, :contract, foreign_key: true
    remove_column :payments, :land_id, :integer
  end
end
