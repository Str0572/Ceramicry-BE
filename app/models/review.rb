class Review < ApplicationRecord
  belongs_to :account
  belongs_to :product

  validates :title, presence: true, length: { maximum: 50 }
  validates :comment, presence: true, length: { minimum: 5 }
  validates :rating, presence: true, inclusion: { in: 1..5 }

  validates :account_id, uniqueness: { scope: :product_id, message: "can only review each product once" }

  before_save :check_for_spam

  def check_for_spam
    # Add more robust profanity/spam check here in future
    if comment&.downcase&.include?("spam")
      errors.add(:comment, "contains inappropriate content")
      throw(:abort)
    end
  end

  # Admin only: hide/restore
  def hide!
    update(hidden: true)
  end

  def restore!
    update(hidden: false)
  end

  def formatted_date
    created_at.strftime("%B %d, %Y")
  end
end
