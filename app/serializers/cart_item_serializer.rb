class CartItemSerializer < ActiveModel::Serializer
  attributes :id, :qty, :total_price, :cart_id, :product

  def product
    return unless object.product.present?
    ProductSerializer.new(object.product).as_json
  end
end
