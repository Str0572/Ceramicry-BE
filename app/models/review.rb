class Review < ApplicationRecord
  belongs_to :account
  belongs_to :product

  validates :title, presence: true, length: { maximum: 50 }
  validates :comment, presence: true, length: { minimum: 5 }
  validates :rating, presence: true, inclusion: { in: 1..5 }

  validates :account_id, uniqueness: { scope: :product_id, message: "has already reviewed this product" }

  def formatted_date
    created_at.strftime("%B %d, %Y")
  end
end
