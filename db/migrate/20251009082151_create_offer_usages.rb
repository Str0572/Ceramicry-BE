class CreateOfferUsages < ActiveRecord::Migration[8.0]
  def change
    create_table :offer_usages do |t|
      t.references :account, null: false, foreign_key: true
      t.references :offer, null: false, foreign_key: true
      t.datetime :used_at, null: false

      t.timestamps
    end

    add_index :offer_usages, [:account_id, :offer_id], unique: true
  end
end
