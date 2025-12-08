class Product < ApplicationRecord
  belongs_to :subcategory
  has_many :product_features,  dependent: :destroy, inverse_of: :product
  has_many :product_specifications, dependent: :destroy, inverse_of: :product
  has_many :product_includes,  dependent: :destroy, inverse_of: :product

  accepts_nested_attributes_for :product_features, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :product_specifications, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :product_includes, allow_destroy: true, reject_if: :all_blank

  has_many :variants, dependent: :destroy
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :destroy
  has_many :reviews, dependent: :destroy

  validates :name, presence: true, length: { maximum: 200 }
  validates :sku, presence: true, uniqueness: true
  validates :material, presence: true
  validates :pieces_count, numericality: { greater_than: 0 }

  scope :featured, -> { where(is_featured: true) }
  scope :new_arrivals, -> { where('created_at >= ?', 30.days.ago) } 
  scope :active, -> { where(deleted_at: nil) }

  before_validation :set_slug, on: [:create, :update]

  def to_param
    slug
  end

  def average_rating
    reviews.average(:rating)&.round(1) || 0
  end
  
  def review_count
    reviews.count
  end

  def destroy
    if order_items.exists?
      errors.add(:base, "Cannot delete a product in existing orders.")
      throw(:abort)
    else
      update(deleted_at: Time.current)
    end
  end

  def deleted?
    !!deleted_at
  end

  def sellable?
    !deleted? && variants.active.any? { |v| v.sellable? }
  end

  private

  def set_slug
    self.slug = name.to_s.parameterize if name.present?
  end
end
