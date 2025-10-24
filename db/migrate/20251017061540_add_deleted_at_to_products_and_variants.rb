class AddDeletedAtToProductsAndVariants < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :deleted_at, :datetime
    add_column :variants, :deleted_at, :datetime
    add_column :accounts, :deleted_at, :datetime
  end
end
