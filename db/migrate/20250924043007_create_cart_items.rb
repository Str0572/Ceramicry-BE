class CreateCartItems < ActiveRecord::Migration[8.0]
  def change
    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :variant, foreign_key: true
      t.integer :qty
      t.decimal :total_price,  precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :cart_items, [:cart_id, :product_id, :variant_id], unique: true, name: 'index_cart_items_uniqueness'
  end
end
