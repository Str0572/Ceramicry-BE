class AddTaxColumns < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :tax_rate, :decimal, precision: 5, scale: 2, default: 0.0, null: false

    add_column :order_items, :tax_rate, :decimal, precision: 5, scale: 2, default: 0.0, null: false
    add_column :order_items, :tax_amount, :decimal, precision: 10, scale: 2, default: 0.0, null: false

    add_column :offers, :discount_type, :string, default: 'percentage', null: false
  end
end
