class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :account, null: false, foreign_key: true
      t.references :shipping_address, null: false, foreign_key: { to_table: :addresses }
      t.references :billing_address, null: false, foreign_key: { to_table: :addresses }
      t.string :order_number, null: false
      t.string :status, default: 'pending', null: false
      t.decimal :subtotal, precision: 10, scale: 2, default: 0.0, null: false
      t.decimal :tax_amount, precision: 10, scale: 2, default: 0.0, null: false
      t.decimal :shipping_amount, precision: 10, scale: 2, default: 0.0, null: false
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0.0, null: false
      t.decimal :total_amount, precision: 10, scale: 2, default: 0.0, null: false
      t.string :payment_method
      t.string :payment_status, default: 'pending', null: false
      t.text :notes
      t.datetime :shipped_at
      t.datetime :delivered_at
      t.datetime :cancelled_at
      t.datetime :estimated_delivery

      t.timestamps
    end

    add_index :orders, :order_number, unique: true
    add_index :orders, :status
    add_index :orders, :payment_status
    add_index :orders, :created_at
  end
end
