class CreateOffers < ActiveRecord::Migration[8.0]
  def change
    create_table :offers do |t|
      t.string :code, null: false
      t.decimal :discount, precision: 10, scale: 2, null: false
      t.decimal :min_order, precision: 10, scale: 2, default: 0.0
      t.text :description
      t.boolean :active, default: true
      t.datetime :expires_at
      t.integer :usage_limit, default: 0

      t.timestamps
    end

    add_index :offers, :code, unique: true
  end
end