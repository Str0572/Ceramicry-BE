class CartSerializer < ActiveModel::Serializer
  attributes :id, :total_items, :subtotal

  belongs_to :account
  has_many :cart_items

  def total_items
    object.cart_items.sum(:qty)
  end

  def subtotal
    object.cart_items.sum(:total_price)
  end
end
