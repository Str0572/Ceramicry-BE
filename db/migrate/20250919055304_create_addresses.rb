class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.string :phone, null: false
      t.string :address_line1, null: false
      t.string :address_line2
      t.string :city, null: false
      t.string :state, null: false
      t.string :pincode, null: false
      t.string :country, default: 'India', null: false
      t.integer :address_type, default: 0
      t.boolean :is_default, default: false

      t.timestamps
    end

    add_index :addresses, [:account_id, :is_default]
  end
end
