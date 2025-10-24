class Offer < ApplicationRecord
  has_many :offer_usages, dependent: :destroy
  has_many :accounts, through: :offer_usages

  validates :code, presence: true, uniqueness: true
  validates :discount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :min_order, numericality: { greater_than_or_equal_to: 0 }
  validates :usage_limit, numericality: { greater_than_or_equal_to: 0 }
  enum :discount_type, { percentage: "percentage", fixed: "fixed"}

  scope :active, -> { where(active: true).where('expires_at IS NULL OR expires_at > ?', Time.current) }

  def expired?
    expires_at.present? && Time.current > expires_at
  end

  def usage_exceeded?
    self.with_lock do
      usage_limit.positive? && offer_usages.count >= usage_limit
    end
  end

  def self.available_for_account(account, subtotal = 0)
    active.select { |o| !o.expired? && !o.usage_exceeded? && subtotal >= o.min_order && !account.offer_usages.exists?(offer: o) }
  end

  def apply_discount(total_amount)
    discount < 100 ? (total_amount * (discount / 100)).round(2) : discount
  end

  def valid_for_order?(order)
    return false unless active? && !expired? && !usage_exceeded?
    return false if order.subtotal < min_order
    return false if order.account.offer_usages.exists?(offer: self)
    
    true
  end
end
