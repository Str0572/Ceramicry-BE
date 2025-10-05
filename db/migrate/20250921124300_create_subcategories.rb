class CreateSubcategories < ActiveRecord::Migration[8.0]
  def change
    create_table :subcategories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
    add_index :subcategories, :slug, unique: true
  end
end
