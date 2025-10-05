class Subcategory < ApplicationRecord
  belongs_to :category
  has_many :products, dependent: :nullify
  has_one_attached :img_icon

  validates :name, presence: true, uniqueness: { scope: :category_id }
  before_validation :set_slug, on: [:create, :update]

  def to_param
    slug
  end

  private

  def set_slug
    self.slug = name.to_s.parameterize if name.present?
  end
end
