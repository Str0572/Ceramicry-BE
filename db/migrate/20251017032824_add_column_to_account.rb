class AddColumnToAccount < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :account_type, :integer
  end
end
