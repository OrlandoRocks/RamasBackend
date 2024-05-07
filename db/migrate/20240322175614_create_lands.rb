class CreateLands < ActiveRecord::Migration[7.0]
  def change
    create_table :lands do |t|
      t.references :residential, null: false, foreign_key: true
      t.string :type
      t.string :address
      t.string :block
      t.float :size
      t.decimal :price
      t.string :house_number

      t.timestamps
    end
  end
end
