class Variant < ApplicationRecord
  belongs_to :product
  has_many_attached :product_images
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :destroy
  validates :sku, presence: true, uniqueness: true
  validates :price, presence: true, numericality: true
  validates :weight, numericality: { greater_than: 0 }, allow_nil: true
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }
  scope :active, -> { where(deleted_at: nil) }

  validate :validate_image_type

  before_save :calculate_discount_percentage

  def calculate_discount_percentage
    if original_price.present? && price.present? && original_price > price
      self.discount_percentage = (((original_price - price) / original_price.to_f) * 100).round
    else
      self.discount_percentage = 0
    end
  end

  def destroy
    if order_items.exists?
      errors.add(:base, "Cannot delete variant tied to orders.")
      throw(:abort)
    else
      update(deleted_at: Time.current)
    end
  end

  def deleted?
    !!deleted_at
  end

  def sellable?
    !deleted? && stock_quantity > 0
  end

  private

  def validate_image_type
    return unless product_images.attached?

    allowed_types = ['image/jpg', 'image/jpeg', 'image/png']
    product_images.each do |image|
      errors.add(:product_images, "must be JPG, JPEG, or PNG") unless allowed_types.include?(image.content_type)
    end
  end
end
