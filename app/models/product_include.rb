class ProductInclude < ApplicationRecord
  belongs_to :product
  validates :item, presence: true
end
