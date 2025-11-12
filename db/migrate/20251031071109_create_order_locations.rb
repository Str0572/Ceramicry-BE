class CreateOrderLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :order_locations do |t|
      t.references :order, null: false, foreign_key: true
      t.references :delivery_agent, null: false, foreign_key: { to_table: :delivery_agents }
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :order_locations, [:order_id, :recorded_at]
  end
end
