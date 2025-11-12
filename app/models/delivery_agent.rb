class DeliveryAgent < ApplicationRecord
  has_secure_password
  has_many :orders, foreign_key: :delivery_agent_id, dependent: :nullify
  has_many :order_locations, dependent: :destroy

  validates :full_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, format: { with: /\A[+]?[0-9]{10,15}\z/ }, allow_blank: true

end
