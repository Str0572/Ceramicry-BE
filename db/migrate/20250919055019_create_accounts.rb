class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.string  :full_name, null: false
      t.string  :email, null: false
      t.string  :mobile
      t.boolean :status, default: true
      t.string  :password_digest
      t.string  :otp_pin
      t.datetime :otp_sent_at
      t.string  :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :deleted_at
      
      t.timestamps
    end

    add_index :accounts, :email, unique: true
    add_index :accounts, :reset_password_token, unique: true
  end
end
