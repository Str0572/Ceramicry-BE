class CreateVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string :sku, null: false
      t.string :size
      t.string :color
      t.decimal :price, precision: 10, scale: 2, null: false
      t.decimal :original_price, precision: 10, scale: 2
      t.integer :discount_percentage, default: 0
      t.integer :stock_quantity, default: 0, null: false

      t.timestamps
    end

    add_index :variants, :sku, unique: true
  end
end
