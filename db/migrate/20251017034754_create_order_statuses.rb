class CreateOrderStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :order_statuses do |t|
      t.references :order, null: false, foreign_key: true
      t.string :status, null: false
      t.text :notes
      t.integer :step_index
      t.string :user_message
      t.datetime :estimated_delivery
      t.references :created_by, null: false, foreign_key: { to_table: :accounts }

      t.timestamps
    end

    add_index :order_statuses, [:order_id, :created_at]
    add_index :order_statuses, :status
  end
end
