class Address < ApplicationRecord
  belongs_to :account
  has_many :shipping_orders, class_name: 'Order', foreign_key: :shipping_address_id, dependent: :nullify
  has_many :billing_orders, class_name: 'Order', foreign_key: :billing_address_id, dependent: :nullify
  
  validates :name, :phone, :address_line1, :city, :state, :pincode, :country, presence: true
  validates :pincode, format: { with: /\A[0-9]{6}\z/, message: "must be 6 digits" }
  validates :phone, format: { with: /\A[+]?[0-9]{10,15}\z/ }
  validates :address_type, inclusion: { in: %w[home work other] }

  enum :address_type, { home: 0, work: 1, other: 2 }

  scope :default, -> { where(is_default: true) }

  before_save :set_single_default

  def full_address
    [address_line1, address_line2, city, state, pincode, country].compact.join(", ")
  end

  private

  def set_single_default
    if is_default_changed? && is_default?
      Address.where(account_id: account_id).where.not(id: id).update_all(is_default: false)
    end
  end
end
