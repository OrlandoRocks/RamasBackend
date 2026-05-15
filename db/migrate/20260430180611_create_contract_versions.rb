class CreateContractVersions < ActiveRecord::Migration[7.0]
  def change
    create_table :contract_versions do |t|
      t.references :contract, null: false, foreign_key: true
      t.text :html_content
      t.integer :version_number

      t.timestamps
    end
  end
end
