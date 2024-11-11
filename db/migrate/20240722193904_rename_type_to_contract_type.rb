class RenameTypeToContractType < ActiveRecord::Migration[7.0]
  def change
    rename_column :contracts, :type, :contract_type
  end
end
