class CreateResidentials < ActiveRecord::Migration[7.0]
  def change
    create_table :residentials do |t|
      t.string :name
      t.string :address
      t.decimal :cost
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
