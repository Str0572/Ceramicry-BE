class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :variant, null: true, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :total_price, precision: 10, scale: 2, null: false
      t.string :product_name
      t.string :variant_details

      t.timestamps
    end

    add_index :order_items, [:order_id, :product_id, :variant_id], unique: true, name: 'index_order_items_on_order_product_variant'
  end
end
