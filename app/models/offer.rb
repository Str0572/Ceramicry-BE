class Offer < ApplicationRecord
  has_many :offer_usages, dependent: :destroy
  has_many :accounts, through: :offer_usages

  validates :code, presence: true, uniqueness: true
  validates :discount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :min_order, numericality: { greater_than_or_equal_to: 0 }
  validates :usage_limit, numericality: { greater_than_or_equal_to: 0 }
  
  enum :discount_type, { percentage: "percentage", fixed: "fixed"}

  scope :active, -> { where(active: true).where('expires_at IS NULL OR expires_at > ?', Time.current) }

  after_create :notify_users_of_new_offer

  def valid_for?(account, subtotal)
    return false unless active?
    return false if expired?
    return false if subtotal < min_order
    return false if usage_exceeded?
    return false if account.offer_usages.exists?(offer: self)
    true
  end

  def expired?
    expires_at.present? && Time.current > expires_at
  end

  def usage_exceeded?
    self.with_lock do
      usage_limit.positive? && offer_usages.count >= usage_limit
    end
  end

  def apply_discount(amount)
    case discount_type
    when "percentage"
      (amount * (discount / 100.0)).round(2)
    when "fixed"
      [discount, amount].min
    else
      0
    end
  end

  def self.available_for_account(account, subtotal = 0)
    active.select { |o| o.valid_for?(account, subtotal) }
  end

  private

  def notify_users_of_new_offer
    Account.find_each(batch_size: 100) do |user|
      NotificationMailer.new_offer_created(user, self).deliver_now
    end
  end
end
