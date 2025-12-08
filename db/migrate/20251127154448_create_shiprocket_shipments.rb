class CreateShiprocketShipments < ActiveRecord::Migration[8.0]
  def change
    create_table :shiprocket_shipments do |t|
      t.references :order, null: false, foreign_key: true
      t.bigint :sr_order_id
      t.bigint :sr_shipment_id
      t.string :awb_code
      t.integer :courier_company_id
      t.string :courier_name
      t.string :status
      t.string :last_shiprocket_status
      t.datetime :last_synced_at
      t.jsonb :raw_order_response
      t.jsonb :raw_courier_response

      t.timestamps
    end

    add_index :shiprocket_shipments, :sr_order_id
    add_index :shiprocket_shipments, :awb_code
  end
end
