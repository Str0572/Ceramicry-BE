class AddDimensionsToVariants < ActiveRecord::Migration[8.0]
  def change
    add_column :variants, :length, :decimal
    add_column :variants, :breadth, :decimal
    add_column :variants, :height, :decimal
    add_column :variants, :weight, :decimal
  end
end
