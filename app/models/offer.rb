class Offer < ApplicationRecord
  has_many :offer_usages, dependent: :destroy
  has_many :accounts, through: :offer_usages

  validates :code, presence: true, uniqueness: true
  validates :discount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :min_order, numericality: { greater_than_or_equal_to: 0 }
  validates :usage_limit, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true).where('expires_at IS NULL OR expires_at > ?', Time.current) }

  def expired?
    expires_at.present? && Time.current > expires_at
  end

  def usage_exceeded?
    usage_limit.positive? && offer_usages.count >= usage_limit
  end

  def apply_discount(total_amount)
    discount < 100 ? (total_amount * (discount / 100)).round(2) : discount
  end
end
