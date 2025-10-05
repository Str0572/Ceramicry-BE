class Cart < ApplicationRecord
  belongs_to :account
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  def total_items
    cart_items.sum(:qty)
  end

  def subtotal
    cart_items.includes(:product, :variant).sum(&:total_price)
  end

  def clear
    cart_items.destroy_all
  end
end
