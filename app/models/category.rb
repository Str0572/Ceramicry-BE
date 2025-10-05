class Category < ApplicationRecord
  has_many :subcategories, dependent: :destroy
  has_one_attached :cat_icon

  validates :name, presence: true, uniqueness: true
  before_validation :set_slug, on: [:create, :update]

  def to_param
    slug
  end

  private

  def set_slug
    self.slug = name.to_s.parameterize if name.present?
  end
end
