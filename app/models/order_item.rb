class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
  belongs_to :variant, optional: true

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :product_id, uniqueness: { scope: [:order_id, :variant_id], message: "already exists in this order" }

  before_validation :set_product_details
  before_validation :calculate_total_price

  def product_name_with_variant
    if variant.present?
      "#{product_name} - #{variant_details}"
    else
      product_name
    end
  end

  def variant_details_text
    return nil unless variant.present?
    
    details = []
    details << "Size: #{variant.size}" if variant.size.present?
    details << "Color: #{variant.color}" if variant.color.present?
    details.join(", ")
  end

  private

  def set_product_details
    self.product_name = product.name
    self.variant_details = variant_details_text
  end

  def calculate_total_price
    self.total_price = (unit_price || variant&.price) * quantity
  end
end

