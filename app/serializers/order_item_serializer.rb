class OrderItemSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :tax_rate, :tax_amount, :unit_price, :total_price, :product_name, :variant_details,
             :product_name_with_variant, :created_at, :updated_at

  belongs_to :product, serializer: ProductSerializer
  belongs_to :variant, serializer: VariantSerializer

  def product_name_with_variant
    object.product_name_with_variant
  end
end

