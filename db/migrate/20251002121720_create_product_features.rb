class CreateProductFeatures < ActiveRecord::Migration[8.0]
  def change
    create_table :product_features do |t|
      t.references :product, null: false, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
