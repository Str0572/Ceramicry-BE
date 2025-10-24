class Subcategory < ApplicationRecord
  belongs_to :category
  has_many :products, dependent: :nullify
  has_one_attached :img_icon

  validates :name, presence: true, uniqueness: { scope: :category_id }
  validates :slug, uniqueness: true

  before_validation :set_slug, on: [:create, :update]
  before_destroy :check_for_products

  def to_param
    slug
  end

  private

  def set_slug
    self.slug = name.to_s.parameterize if name.present?
  end

  def check_for_products
    if products.exists?
      errors.add(:base, "Cannot delete subcategory with products.")
      throw(:abort)
    end
  end
end
