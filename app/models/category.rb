class Category < ApplicationRecord
  has_many :subcategories, dependent: :destroy
  has_one_attached :cat_icon

  validates :name, presence: true, uniqueness: true
  validates :slug, uniqueness: true
  before_validation :set_slug, on: [:create, :update]

  before_destroy :check_for_products

  def check_for_products
    if subcategories.joins(:products).exists? || products.exists?
      errors.add(:base, "Cannot delete category with products.")
      throw(:abort)
    end
  end

  def to_param
    slug
  end

  private

  def set_slug
    self.slug = name.to_s.parameterize if name.present?
  end
end
