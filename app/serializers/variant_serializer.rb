class VariantSerializer < ActiveModel::Serializer
  attributes :id, :sku, :size, :color, :price, :original_price, :discount_percentage, :stock_quantity, :product_id
end
