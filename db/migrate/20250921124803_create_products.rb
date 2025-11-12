class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :sku, null: false
      t.text :description
      t.text :features
      t.string :material, null: false
      t.integer :pieces_count, null: false
      t.string :brand
      t.boolean :is_featured, default: false
      t.boolean :is_new, default: false
      t.integer :views_count, default: 0
      t.references :subcategory, null: false, foreign_key: true
      t.decimal :tax_rate, precision: 5, scale: 2, default: 0.0, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :products, :slug, unique: true
    add_index :products, :sku, unique: true
    add_index :products, :is_featured
  end
end
