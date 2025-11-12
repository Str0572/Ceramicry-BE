class CreateDeliveryAgents < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_agents do |t|
      t.string :full_name
      t.string :phone
      t.string :email
      t.string :password_digest
      t.float :latitude
      t.float :longitude
      t.datetime :last_seen_at
      t.boolean :active, default: true

      t.timestamps
    end

    add_reference :orders, :delivery_agent, foreign_key: { to_table: :delivery_agents }, null: true
  end
end
