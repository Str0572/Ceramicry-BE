class OfferUsage < ApplicationRecord
  belongs_to :account
  belongs_to :offer

  validates :account_id, uniqueness: { scope: :offer_id, message: "has already used this offer" }

  before_validation :set_used_at

  private

  def set_used_at
    self.used_at = Time.current
  end
end
