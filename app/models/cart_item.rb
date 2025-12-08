class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product
  belongs_to :variant, optional: true

  validates :qty, presence: true, numericality: { greater_than: 0 }
  validates :product_id, uniqueness: { scope: [:cart_id, :variant_id], message: "already exists in cart" }

  before_save :set_total_price

  def set_total_price
    base_price = variant&.price || 0
    self.total_price = base_price * qty
  end
end
